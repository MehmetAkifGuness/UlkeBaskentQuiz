// lib/services/conquest_websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../models/conquest_session_dto.dart';

class ConquestWebSocketService {
  StompClient? _client;
  StompUnsubscribe? _stateUnsubscribe;
  StompUnsubscribe? _errorUnsubscribe;

  String? _connectedSessionId;
  int _generation = 0;
  bool _isManualDisconnect = false;

  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  final Random _random = Random();

  void Function(ConquestSessionState state)? _onState;
  void Function(String message)? _onError;
  void Function()? _onConnected;

  bool get isConnected => _client?.connected ?? false;

  String _resolveWsUrl() {
    final apiBase = (dotenv.env['API_BASE_URL'] ?? '').trim();
    if (apiBase.isEmpty) {
      return '/ws/conquest';
    }

    // API_BASE_URL genelde "...:8081/api" şeklinde. WS endpoint ise "/ws/conquest".
    final root = apiBase.replaceFirst(RegExp(r'/api/?$'), '');
    return '$root/ws/conquest';
  }

  void connect({
    required String sessionId,
    required void Function(ConquestSessionState state) onState,
    required void Function(String message) onError,
    void Function()? onConnected,
  }) {
    disconnect();

    _generation += 1;
    final int generation = _generation;
    _isManualDisconnect = false;
    _reconnectAttempt = 0;

    _connectedSessionId = sessionId;
    _onState = onState;
    _onError = onError;
    _onConnected = onConnected;

    _activateClient(generation);
  }

  void disconnect() {
    _generation += 1;
    _isManualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _stateUnsubscribe?.call(unsubscribeHeaders: {});
    _errorUnsubscribe?.call(unsubscribeHeaders: {});
    _stateUnsubscribe = null;
    _errorUnsubscribe = null;

    _client?.deactivate();
    _client = null;
    _connectedSessionId = null;
    _onState = null;
    _onError = null;
    _onConnected = null;
    _reconnectAttempt = 0;
  }

  void _activateClient(int generation) {
    final sessionId = _connectedSessionId;
    final onState = _onState;
    final onError = _onError;
    if (sessionId == null || onState == null || onError == null) return;

    final wsUrl = _resolveWsUrl();
    _disposeClientOnly();

    _client = StompClient(
      config: StompConfig.sockJS(
        url: wsUrl,
        // Sabit reconnectDelay "thundering herd" riski yaratıyor.
        // 0ms -> otomatik reconnect kapalı. Backoff+jitter'i biz yönetiyoruz.
        reconnectDelay: Duration.zero,
        heartbeatIncoming: const Duration(seconds: 5),
        heartbeatOutgoing: const Duration(seconds: 5),
        onConnect: (frame) {
          if (generation != _generation) return;

          _reconnectAttempt = 0;
          _reconnectTimer?.cancel();
          _reconnectTimer = null;

          // State topic
          _stateUnsubscribe = _client?.subscribe(
            destination: '/topic/conquest/$sessionId',
            callback: (frame) {
              if (generation != _generation) return;
              try {
                if (frame.body == null) return;
                final decoded = jsonDecode(frame.body!);
                if (decoded is Map<String, dynamic>) {
                  onState(ConquestSessionState.fromJson(decoded));
                } else if (decoded is Map) {
                  onState(ConquestSessionState.fromJson(
                    Map<String, dynamic>.from(decoded),
                  ));
                }
              } catch (e) {
                onError("State parse hatası: $e");
              }
            },
          );

          // Error topic
          _errorUnsubscribe = _client?.subscribe(
            destination: '/topic/conquest/$sessionId/errors',
            callback: (frame) {
              if (generation != _generation) return;
              if (frame.body == null) return;
              try {
                final decoded = jsonDecode(frame.body!);
                if (decoded is Map) {
                  final message = decoded['message']?.toString().trim();
                  if (message != null && message.isNotEmpty) {
                    onError(message);
                    return;
                  }
                }
              } catch (_) {}
              onError(frame.body!);
            },
          );

          try {
            if (generation != _generation) return;
            _onConnected?.call();
          } catch (e) {
            onError("Bağlantı callback hatası: $e");
          }
        },
        onWebSocketError: (dynamic error) {
          if (generation != _generation) return;
          if (_isManualDisconnect) return;
          onError(error.toString());
          _scheduleReconnect(generation);
        },
        onWebSocketDone: () {
          if (generation != _generation) return;
          if (_isManualDisconnect) return;
          onError("WebSocket bağlantısı kapandı.");
          _scheduleReconnect(generation);
        },
        onStompError: (frame) {
          if (generation != _generation) return;
          if (_isManualDisconnect) return;
          onError(frame.body ?? 'STOMP error');
          _scheduleReconnect(generation);
        },
        onDisconnect: (frame) {
          if (generation != _generation) return;
          if (_isManualDisconnect) return;
          _scheduleReconnect(generation);
        },
      ),
    );

    _client?.activate();
  }

  void _scheduleReconnect(int generation) {
    if (generation != _generation) return;
    if (_isManualDisconnect) return;
    if (_reconnectTimer != null) return;
    if (_connectedSessionId == null) return;

    _disposeClientOnly();

    final delay = _computeReconnectDelay(_reconnectAttempt);
    _reconnectAttempt += 1;

    _reconnectTimer = Timer(delay, () {
      if (generation != _generation) return;
      if (_isManualDisconnect) return;
      _reconnectTimer = null;
      _activateClient(generation);
    });
  }

  Duration _computeReconnectDelay(int attempt) {
    const int baseSeconds = 2;
    const int maxSeconds = 30;

    final int safeAttempt = attempt < 0 ? 0 : (attempt > 10 ? 10 : attempt);
    final int rawSeconds = baseSeconds * (1 << safeAttempt);
    final int seconds =
        rawSeconds < 1 ? 1 : (rawSeconds > maxSeconds ? maxSeconds : rawSeconds);
    final int jitterMs = _random.nextInt(750);

    return Duration(seconds: seconds, milliseconds: jitterMs);
  }

  void _disposeClientOnly() {
    _stateUnsubscribe?.call(unsubscribeHeaders: {});
    _errorUnsubscribe?.call(unsubscribeHeaders: {});
    _stateUnsubscribe = null;
    _errorUnsubscribe = null;
    _client?.deactivate();
    _client = null;
  }

  void startGame(StartConquestGameRequest request) {
    _client?.send(
      destination: '/app/conquest.start',
      body: jsonEncode(request.toJson()),
    );
  }

  void submitAnswer(SubmitConquestAnswerRequest request) {
    _client?.send(
      destination: '/app/conquest.answer',
      body: jsonEncode(request.toJson()),
    );
  }

  void requestState(StartConquestGameRequest request) {
    _client?.send(
      destination: '/app/conquest.state',
      body: jsonEncode(request.toJson()),
    );
  }

  void setReady(SetConquestReadyRequest request) {
    _client?.send(
      destination: '/app/conquest.ready',
      body: jsonEncode(request.toJson()),
    );
  }

  void leaveSession(StartConquestGameRequest request) {
    _client?.send(
      destination: '/app/conquest.leave',
      body: jsonEncode(request.toJson()),
    );
  }

  String? get connectedSessionId => _connectedSessionId;
}
