part of '../conquest_multiplayer_provider.dart';

extension ConquestMultiplayerProviderConnection on ConquestMultiplayerProvider {
  Future<void> connectToSession() async {
    final currentSessionId = sessionId;
    if (currentSessionId == null || currentSessionId.isEmpty) {
      errorMessage = "sessionId bulunamadı.";
      _emit();
      return;
    }

    final pid = playerId;

    // Ülke adı çevirisi (ISO -> TR) ve ISO2/ISO3 eşleştirmeleri için gerekli.
    try {
      await IsoCountryService.ensureLoaded();
    } catch (_) {}

    // Aynı oturum için bağlantı zaten başlatıldıysa (veya bağlıysa) tekrar bağlanma.
    // Hızlı ekran geçişlerinde birden fazla connect() çağrısı önceki bağlantıyı kapatıp
    // kullanıcıya "WebSocket bağlantısı kapandı" gibi hatalar gösterebiliyor.
    if (_wsService.connectedSessionId == currentSessionId) {
      if (_wsService.isConnected) {
        if (pid != null && pid.isNotEmpty) {
          _wsService.requestState(
            StartConquestGameRequest(sessionId: currentSessionId, playerId: pid),
          );
        }
        return;
      }

      // Bağlantı devam ederken (henüz connected değilken) yeniden connect çağrısı yapma.
      if (_connectingSessionId == currentSessionId) {
        return;
      }
      // Aynı sessionId için daha önce denendi ama şu an bağlı değil -> yeniden dene.
    }

    errorMessage = null;
    _connectingSessionId = currentSessionId;
    _emit();

    _wsService.connect(
      sessionId: currentSessionId,
      onState: (state) {
        _connectingSessionId = null;
        sessionState = state;
        roomCode = state.roomCode ?? roomCode;
        isQuickMatchMode = state.quickMatch;
        isConnected = true;
        _emit();
      },
      onError: (message) {
        _connectingSessionId = null;
        errorMessage = message;
        isConnected = false;
        _emit();
      },
      onConnected: () {
        _connectingSessionId = null;
        isConnected = true;
        _emit();

        if (pid != null && pid.isNotEmpty) {
          _wsService.requestState(
            StartConquestGameRequest(sessionId: currentSessionId, playerId: pid),
          );
        }
      },
    );

    // Not: STOMP bağlantısı asenkron kurulur; ilk state gelince isConnected true olur.
  }
}
