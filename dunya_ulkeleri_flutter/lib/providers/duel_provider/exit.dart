part of '../duel_provider.dart';

extension DuelProviderExit on DuelProvider {
  Future<void> leaveSession({String? token}) async {
    final sid = sessionId;
    final pid = playerId;

    if (sid != null && pid != null) {
      if (_wsService.isConnected) {
        _wsService.leaveSession(LeaveDuelSessionRequest(sessionId: sid, playerId: pid));
        await Future<void>.delayed(const Duration(milliseconds: 150));
      } else {
        final effectiveToken = token?.trim();
        if (effectiveToken != null && effectiveToken.isNotEmpty) {
          try {
            await _apiService.leaveSession(
              sessionId: sid,
              playerId: pid,
              token: effectiveToken,
            );
          } catch (_) {}
        }
      }
    }

    _wsService.disconnect();
    isConnected = false;
    isLoading = false;
    _connectingSessionId = null;

    sessionId = null;
    roomCode = null;
    playerId = null;
    category = null;
    mode = null;
    sessionState = null;
    errorMessage = null;
    isQuickMatchMode = false;
    _myAnswerCorrectByRound.clear();

    _emit();
  }
}
