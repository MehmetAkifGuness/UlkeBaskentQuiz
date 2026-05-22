part of '../conquest_multiplayer_provider.dart';

extension ConquestMultiplayerProviderExit on ConquestMultiplayerProvider {
  Future<void> leaveSession({String? token}) async {
    final sid = sessionId;
    final pid = playerId;

    if (sid != null && pid != null) {
      if (_wsService.isConnected) {
        _wsService.leaveSession(
          StartConquestGameRequest(sessionId: sid, playerId: pid),
        );
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
          } catch (_) {
            // Kullanıcı çıkmak istiyor: ağ hatası olsa bile local state temizlenmeli.
          }
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
    playerName = null;
    sessionState = null;
    errorMessage = null;
    isQuickMatchMode = false;

    _emit();
  }
}
