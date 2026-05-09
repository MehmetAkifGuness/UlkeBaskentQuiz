// lib/services/conquest_websocket_service.dart
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../models/conquest_session_dto.dart';

class ConquestWebSocketService {
  StompClient? _client;
  StompUnsubscribe? _stateUnsubscribe;
  StompUnsubscribe? _errorUnsubscribe;

  String? _connectedSessionId;

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
  }) {
    disconnect();

    _connectedSessionId = sessionId;
    final wsUrl = _resolveWsUrl();

    _client = StompClient(
      config: StompConfig.sockJS(
        url: wsUrl,
        reconnectDelay: const Duration(seconds: 2),
        heartbeatIncoming: const Duration(seconds: 5),
        heartbeatOutgoing: const Duration(seconds: 5),
        onConnect: (frame) {
          // State topic
          _stateUnsubscribe = _client?.subscribe(
            destination: '/topic/conquest/$sessionId',
            callback: (frame) {
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
        },
        onWebSocketError: (dynamic error) {
          onError(error.toString());
        },
        onWebSocketDone: () {
          onError("WebSocket bağlantısı kapandı.");
        },
        onStompError: (frame) {
          onError(frame.body ?? 'STOMP error');
        },
        onDisconnect: (frame) {
          // Bağlantı koparsa provider tekrar bağlanmayı yönetebilir.
        },
      ),
    );

    _client?.activate();
  }

  void disconnect() {
    _stateUnsubscribe?.call(unsubscribeHeaders: {});
    _errorUnsubscribe?.call(unsubscribeHeaders: {});
    _stateUnsubscribe = null;
    _errorUnsubscribe = null;

    _client?.deactivate();
    _client = null;
    _connectedSessionId = null;
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
