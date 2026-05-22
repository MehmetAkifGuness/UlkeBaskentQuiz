part of '../conquest_online_entry_screen.dart';

Future<void> _createRoomImpl(_ConquestOnlineEntryScreenState state) async {
  state._triggerHaptic();

  final token = state.context.read<AuthProvider>().token;
  if (token == null || token.trim().isEmpty) {
    state._showSnackOnce('Online mod için giriş yapmalısın.');
    return;
  }

  final username = (state.context.read<AuthProvider>().username ??
          state._createUsernameController.text)
      .trim();
  if (username.isEmpty) {
    state._showSnackOnce('Kullanıcı adı boş olamaz.');
    return;
  }

  final provider = state.context.read<ConquestMultiplayerProvider>();
  await provider.leaveSession(token: token);
  final ok = await provider.createOnlineSession(
    token: token,
    username: username,
    color: state._selectedCreateColor,
    continentFilter: state._selectedContinent,
  );
  if (!ok || !state.mounted) return;

  await Navigator.of(state.context).push(
    FadePageRoute(page: const ConquestOnlineLobbyScreen()),
  );
}

Future<void> _quickGameImpl(_ConquestOnlineEntryScreenState state) async {
  state._triggerHaptic();

  final token = state.context.read<AuthProvider>().token;
  if (token == null || token.trim().isEmpty) {
    state._showSnackOnce('Online mod için giriş yapmalısın.');
    return;
  }

  final username = (state.context.read<AuthProvider>().username ??
          state._createUsernameController.text)
      .trim();
  if (username.isEmpty) {
    state._showSnackOnce('Kullanıcı adı boş olamaz.');
    return;
  }

  final provider = state.context.read<ConquestMultiplayerProvider>();
  await provider.leaveSession(token: token);
  final ok = await provider.quickMatch(
    token: token,
    username: username,
    color: state._selectedCreateColor,
    continentFilter: state._selectedContinent,
  );
  if (!ok || !state.mounted) return;

  await Navigator.of(state.context).push(
    FadePageRoute(page: const ConquestOnlineLobbyScreen()),
  );
}

Future<void> _joinRoomImpl(_ConquestOnlineEntryScreenState state) async {
  state._triggerHaptic();

  final token = state.context.read<AuthProvider>().token;
  if (token == null || token.trim().isEmpty) {
    state._showSnackOnce('Online mod için giriş yapmalısın.');
    return;
  }

  final username =
      (state.context.read<AuthProvider>().username ?? state._joinUsernameController.text)
          .trim();
  if (username.isEmpty) {
    state._showSnackOnce('Kullanıcı adı boş olamaz.');
    return;
  }

  final roomCode = state._roomCodeController.text.trim().toUpperCase();
  if (roomCode.isEmpty) {
    state._showSnackOnce('Oda kodu boş olamaz.');
    return;
  }

  final provider = state.context.read<ConquestMultiplayerProvider>();
  await provider.leaveSession(token: token);
  final ok = await provider.joinOnlineSession(
    token: token,
    username: username,
    roomCode: roomCode,
    color: state._selectedJoinColor,
  );
  if (!ok || !state.mounted) return;

  await Navigator.of(state.context).push(
    FadePageRoute(page: const ConquestOnlineLobbyScreen()),
  );
}

