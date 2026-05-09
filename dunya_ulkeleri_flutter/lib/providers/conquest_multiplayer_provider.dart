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

class ConquestMultiplayerProvider with ChangeNotifier {
  final ConquestApiService _apiService = ConquestApiService();
  final ConquestWebSocketService _wsService = ConquestWebSocketService();

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

  String? get currentTargetName => sessionState?.currentRound?.targetCountryName;

  String? get currentTargetIsoCode => sessionState?.currentRound?.targetIsoCode;

  Map<String, Color> get conqueredCountryColorsAsColors {
    final raw = sessionState?.conqueredCountryColors ?? const <String, String>{};
    return raw.map((key, value) => MapEntry(key, hexToColor(value)));
  }

  Future<bool> createOnlineSession({
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
        JoinConquestSessionRequest(username: username, colorHex: colorToHex(color)),
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

  Future<void> connectToSession() async {
    final currentSessionId = sessionId;
    if (currentSessionId == null || currentSessionId.isEmpty) {
      errorMessage = "sessionId bulunamadı.";
      notifyListeners();
      return;
    }

    errorMessage = null;
    notifyListeners();

    _wsService.connect(
      sessionId: currentSessionId,
      onState: (state) {
        sessionState = state;
        roomCode = state.roomCode ?? roomCode;
        isQuickMatchMode = state.quickMatch;
        isConnected = true;
        notifyListeners();
      },
      onError: (message) {
        errorMessage = message;
        isConnected = false;
        notifyListeners();
      },
    );

    final pid = playerId;
    if (pid != null && pid.isNotEmpty) {
      _wsService.requestState(
        StartConquestGameRequest(sessionId: currentSessionId, playerId: pid),
      );
    }

    // Not: STOMP bağlantısı asenkron kurulur; ilk state gelince isConnected true olur.
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

  Future<void> submitOnlineAnswerFromMapProperties(
    Map<String, dynamic> mapProperties,
  ) async {
    final sid = sessionId;
    final pid = playerId;
    if (sid == null || pid == null) {
      errorMessage = 'Cevap göndermek için sessionId/playerId gerekli.';
      notifyListeners();
      return;
    }

    final state = sessionState;
    if (state == null) {
      errorMessage = 'Oturum durumu henüz hazır değil.';
      notifyListeners();
      return;
    }

    try {
      await IsoCountryService.ensureLoaded();
    } catch (_) {}

    String? readFirstNonEmpty(List<String> keys) {
      for (final key in keys) {
        final raw = mapProperties[key];
        final value = raw?.toString().trim();
        if (value != null && value.isNotEmpty && value != '-99') return value;
      }
      return null;
    }

    final isoCandidate = readFirstNonEmpty(const [
      'ISO3166-1-Alpha-2',
      'ISO_A2',
      'iso_a2',
      'ISO3166-1-Alpha-3',
      'ISO_A3',
      'iso_a3',
      'ADM0_A3',
      'adm0_a3',
      'id',
    ]);

    final nameCandidate = readFirstNonEmpty(const [
      'name',
      'NAME',
      'admin',
      'ADMIN',
    ]);

    final available = state.playableIsoCodes.isNotEmpty
        ? state.playableIsoCodes
            .map((iso) => MapCountryModel(isoCode: iso, name: iso))
            .toList(growable: false)
        : <MapCountryModel>[];

    if (available.isEmpty) {
      final fallbackIso = (isoCandidate ?? '').trim();
      final fallbackName = (nameCandidate ?? '').trim();
      if (fallbackIso.isNotEmpty || fallbackName.isNotEmpty) {
        available.add(
          MapCountryModel(
            isoCode: fallbackIso.isNotEmpty ? fallbackIso : fallbackName,
            name: fallbackName.isNotEmpty ? fallbackName : fallbackIso,
          ),
        );
      }
    }

    final matcher = CountryMatchService(availableCountries: available);
    MapCountryModel? matched;

    if (isoCandidate != null && isoCandidate.trim().isNotEmpty) {
      matched = matcher.matchByIsoCode(isoCandidate);
    }
    matched ??= (nameCandidate != null && nameCandidate.trim().isNotEmpty)
        ? matcher.matchByName(nameCandidate)
        : null;

    if (matched == null || matched.isoCode.trim().isEmpty) {
      errorMessage = 'Bu bölge oyun verilerinde yok.';
      notifyListeners();
      return;
    }

    _wsService.submitAnswer(
      SubmitConquestAnswerRequest(
        sessionId: sid,
        playerId: pid,
        selectedIsoCode: matched.isoCode,
        selectedCountryName: nameCandidate ?? matched.name,
      ),
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

  Future<void> refreshSessionState() async {
    final currentSessionId = sessionId;
    if (currentSessionId == null || currentSessionId.isEmpty) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      sessionState = await _apiService.getSessionState(currentSessionId);
    } catch (e) {
      errorMessage = errorMessageFrom(e);
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> leaveSession() async {
    final sid = sessionId;
    final pid = playerId;

    if (sid != null && pid != null && _wsService.isConnected) {
      _wsService.leaveSession(
        StartConquestGameRequest(sessionId: sid, playerId: pid),
      );
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }

    _wsService.disconnect();
    isConnected = false;
    isLoading = false;

    sessionId = null;
    roomCode = null;
    playerId = null;
    playerName = null;
    sessionState = null;
    errorMessage = null;
    isQuickMatchMode = false;

    notifyListeners();
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
}
