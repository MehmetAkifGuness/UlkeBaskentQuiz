// lib/providers/duel_provider.dart
import 'package:flutter/foundation.dart';

import '../models/duel_session_dto.dart';
import '../services/duel_api_service.dart';
import '../services/duel_websocket_service.dart';
import '../utils/error_message_utils.dart';

part 'duel_provider/connection.dart';
part 'duel_provider/exit.dart';

class DuelProvider with ChangeNotifier {
  final DuelApiService _apiService = DuelApiService();
  final DuelWebSocketService _wsService = DuelWebSocketService();

  String? _connectingSessionId;

  bool isConnected = false;
  bool isLoading = false;
  String? errorMessage;

  String? sessionId;
  String? roomCode;
  String? playerId;

  String? category;
  String? mode;

  DuelSessionState? sessionState;
  bool isQuickMatchMode = false;

  bool get isInLobby => (sessionState?.status ?? '').toUpperCase() == 'WAITING';
  bool get isGameStarted => (sessionState?.status ?? '').toUpperCase() == 'STARTED';
  bool get isGameFinished => (sessionState?.status ?? '').toUpperCase() == 'FINISHED';

  Future<bool> createSession({
    required String token,
    required String category,
    required String mode,
  }) async {
    if (isLoading) return false;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.createSession(
        CreateDuelSessionRequest(category: category, mode: mode),
        token: token,
      );

      sessionId = response.sessionId;
      roomCode = response.roomCode;
      playerId = response.playerId;
      this.category = category;
      this.mode = mode;
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

  Future<bool> joinSession({
    required String token,
    required String roomCode,
  }) async {
    if (isLoading) return false;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.joinSession(
        roomCode,
        const JoinDuelSessionRequest(),
        token: token,
      );

      sessionId = response.sessionId;
      this.roomCode = response.roomCode;
      playerId = response.playerId;
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
    required String category,
    required String mode,
  }) async {
    if (isLoading) return false;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.quickMatch(
        CreateDuelSessionRequest(category: category, mode: mode),
        token: token,
      );

      sessionId = response.sessionId;
      roomCode = response.roomCode;
      playerId = response.playerId;
      this.category = category;
      this.mode = mode;
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

  Future<void> refreshSessionState({
    required String token,
  }) async {
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

  void submitAnswer(String option) {
    final sid = sessionId;
    final pid = playerId;
    if (sid == null || pid == null) {
      errorMessage = 'Cevap için sessionId/playerId gerekli.';
      notifyListeners();
      return;
    }

    _wsService.submitAnswer(
      SubmitDuelAnswerRequest(sessionId: sid, playerId: pid, selectedOption: option),
    );
  }

  void requestState() {
    final sid = sessionId;
    if (sid == null || sid.isEmpty) return;
    _wsService.requestState(sid);
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void _emit() => notifyListeners();
}

