// lib/providers/conquest_multiplayer_provider.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../models/conquest_session_dto.dart';
import '../models/map_country_model.dart';
import '../services/conquest_api_service.dart';
import '../services/conquest_websocket_service.dart';
import '../services/country_match_service.dart';
import '../services/iso_country_service.dart';
import '../utils/color_hex_utils.dart';
import '../utils/error_message_utils.dart';

part 'conquest_multiplayer_provider/answer_mapping.dart';
part 'conquest_multiplayer_provider/connection.dart';
part 'conquest_multiplayer_provider/exit.dart';
part 'conquest_multiplayer_provider/target.dart';

class ConquestMultiplayerProvider with ChangeNotifier {
  final ConquestApiService _apiService = ConquestApiService();
  final ConquestWebSocketService _wsService = ConquestWebSocketService();

  // Aynı session için peş peşe connect() çağrılarını engellemek için.
  // (Örn: oda oluştur -> lobiye geçiş anında iki kere bağlanma denemesi.)
  String? _connectingSessionId;

  bool isConnected = false;
  bool isLoading = false;
  String? errorMessage;

  String? sessionId;
  String? roomCode;
  String? playerId;

  String? playerName;
  Color playerColor = Colors.blue;

  ConquestSessionState? sessionState;

  bool isQuickMatchMode = false;

  // TODO: Oda sahibi / host yetkisi eklenecek.
  // TODO: Oyuncu disconnect/reconnect gelişmiş yönetilecek.
  // TODO: Maç sonucu backend'e kaydedilecek.
  // TODO: Liderlik tablosu eklenecek.
  // TODO: Davet linki ve arkadaş sistemi eklenecek.

  bool get isInLobby => (sessionState?.status ?? '').toUpperCase() == 'WAITING';

  bool get isGameStarted =>
      (sessionState?.status ?? '').toUpperCase() == 'STARTED';

  bool get isGameFinished =>
      (sessionState?.status ?? '').toUpperCase() == 'FINISHED';

  String? get currentTargetIsoCode => sessionState?.currentRound?.targetIsoCode;

  Map<String, Color> get conqueredCountryColorsAsColors {
    final raw = sessionState?.conqueredCountryColors ?? const <String, String>{};
    return raw.map((key, value) => MapEntry(key, hexToColor(value)));
  }

  Future<bool> createOnlineSession({
    required String token,
    required String username,
    required Color color,
    required String continentFilter,
  }) async {
    if (isLoading) return false;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.createSession(
        CreateConquestSessionRequest(
          username: username,
          colorHex: colorToHex(color),
          continentFilter: continentFilter,
        ),
        token: token,
      );

      sessionId = response.sessionId;
      roomCode = response.roomCode;
      playerId = response.playerId;
      playerName = username;
      playerColor = color;
      isQuickMatchMode = false;

      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = errorMessageFrom(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> joinOnlineSession({
    required String token,
    required String username,
    required String roomCode,
    required Color color,
  }) async {
    if (isLoading) return false;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.joinSession(
        roomCode,
        JoinConquestSessionRequest(
          username: username,
          colorHex: colorToHex(color),
        ),
        token: token,
      );

      sessionId = response.sessionId;
      this.roomCode = response.roomCode;
      playerId = response.playerId;
      playerName = username;
      playerColor = color;
      isQuickMatchMode = false;

      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = errorMessageFrom(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> quickMatch({
    required String token,
    required String username,
    required Color color,
    required String continentFilter,
  }) async {
    if (isLoading) return false;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.quickMatch(
        CreateConquestSessionRequest(
          username: username,
          colorHex: colorToHex(color),
          continentFilter: continentFilter,
        ),
        token: token,
      );

      sessionId = response.sessionId;
      roomCode = response.roomCode;
      playerId = response.playerId;
      playerName = username;
      playerColor = color;
      isQuickMatchMode = true;

      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = errorMessageFrom(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> connectToCurrentSession() => connectToSession();

  Future<void> startOnlineGame() async {
    if (sessionId == null || playerId == null) {
      errorMessage = "startOnlineGame için sessionId/playerId gerekli.";
      notifyListeners();
      return;
    }

    _wsService.startGame(
      StartConquestGameRequest(sessionId: sessionId!, playerId: playerId!),
    );
  }

  void setReady(bool ready) {
    final sid = sessionId;
    final pid = playerId;
    if (sid == null || pid == null) {
      errorMessage = 'Hazır durumu için sessionId/playerId gerekli.';
      notifyListeners();
      return;
    }

    _wsService.setReady(
      SetConquestReadyRequest(sessionId: sid, playerId: pid, ready: ready),
    );
  }

  Future<void> submitOnlineAnswer({
    required String selectedIsoCode,
    required String selectedCountryName,
  }) async {
    if (sessionId == null || playerId == null) {
      errorMessage = "submitOnlineAnswer için sessionId/playerId gerekli.";
      notifyListeners();
      return;
    }

    _wsService.submitAnswer(
      SubmitConquestAnswerRequest(
        sessionId: sessionId!,
        playerId: playerId!,
        selectedIsoCode: selectedIsoCode,
        selectedCountryName: selectedCountryName,
      ),
    );
  }

  Future<void> refreshSessionState({required String token}) async {
    final currentSessionId = sessionId;
    if (currentSessionId == null || currentSessionId.isEmpty) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      sessionState = await _apiService.getSessionState(
        currentSessionId,
        token: token,
      );
    } catch (e) {
      errorMessage = errorMessageFrom(e);
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool get isHost {
    final hostId = (sessionState?.hostPlayerId ?? '').trim();
    final pid = (playerId ?? '').trim();
    if (hostId.isEmpty || pid.isEmpty) return false;
    return hostId == pid;
  }

  void disconnect() {
    // Geriye dönük uyumluluk.
    leaveSession();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void _emit() => notifyListeners();
}
