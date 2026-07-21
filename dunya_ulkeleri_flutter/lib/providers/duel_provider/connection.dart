part of '../duel_provider.dart';

extension DuelProviderConnection on DuelProvider {
  Future<void> connectToCurrentSession() => connectToSession();

  Future<void> connectToSession() async {
    final sid = sessionId;
    if (sid == null || sid.isEmpty) return;

    if (_connectingSessionId == sid) return;
    _connectingSessionId = sid;

    _wsService.connect(
      sessionId: sid,
      onState: (state) {
        sessionState = state;
        _captureMyAnswerResult(state);
        isConnected = true;
        _connectingSessionId = null;
        if ((state.status ?? '').toUpperCase() != 'WAITING') {
          _stopQuickMatchPolling();
        }
        _emit();
      },
      onError: (message) {
        errorMessage = message.trim().isEmpty ? null : message.trim();
        _connectingSessionId = null;
        isConnected = false;
        _emit();
      },
      onConnected: () {
        isConnected = true;
        _connectingSessionId = null;
        _emit();
        _wsService.requestState(sid);
      },
    );
  }
}
