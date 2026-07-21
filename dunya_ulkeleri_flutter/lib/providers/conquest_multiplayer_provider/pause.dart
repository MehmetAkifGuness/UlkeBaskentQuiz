part of '../conquest_multiplayer_provider.dart';

extension ConquestMultiplayerProviderPause on ConquestMultiplayerProvider {
  Future<bool> pauseGame({required String? token}) =>
      _changePauseState(token: token, resume: false);

  Future<bool> resumeGame({required String? token}) =>
      _changePauseState(token: token, resume: true);

  Future<bool> _changePauseState({
    required String? token,
    required bool resume,
  }) async {
    final sid = sessionId;
    final pid = playerId;
    final effectiveToken = token?.trim();
    if (sid == null || pid == null || effectiveToken == null || effectiveToken.isEmpty) {
      errorMessage = 'Oyun durumu için oturum bilgileri gerekli.';
      _emit();
      return false;
    }
    if (isLoading) return false;

    isLoading = true;
    errorMessage = null;
    _emit();
    try {
      sessionState = resume
          ? await _apiService.resumeSession(
              sessionId: sid,
              playerId: pid,
              token: effectiveToken,
            )
          : await _apiService.pauseSession(
              sessionId: sid,
              playerId: pid,
              token: effectiveToken,
            );
      return true;
    } catch (e) {
      errorMessage = errorMessageFrom(e);
      return false;
    } finally {
      isLoading = false;
      _emit();
    }
  }
}
