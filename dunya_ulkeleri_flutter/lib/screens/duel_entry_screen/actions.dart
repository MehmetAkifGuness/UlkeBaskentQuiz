part of '../duel_entry_screen.dart';

Future<void> _createRoomImpl(_DuelEntryScreenState state) async {
  state._triggerHaptic();
  final token = state.context.read<AuthProvider>().token;
  if (token == null || token.trim().isEmpty) {
    state._showSnackOnce('Lütfen giriş yapın.');
    return;
  }

  final ok = await state.context.read<DuelProvider>().createSession(
        token: token,
        category: state._selectedCategory,
        mode: state._selectedMode,
      );
  if (!ok || !state.mounted) return;

  Navigator.push(
    state.context,
    FadePageRoute(page: const DuelGameScreen()),
  );
}

Future<void> _botMatchImpl(_DuelEntryScreenState state) async {
  state._triggerHaptic();
  final token = state.context.read<AuthProvider>().token;
  if (token == null || token.trim().isEmpty) {
    state._showSnackOnce('Lütfen giriş yapın.');
    return;
  }

  final ok = await state.context.read<DuelProvider>().createSession(
        token: token,
        category: state._selectedCategory,
        mode: state._selectedMode,
        vsBot: true,
        botDifficulty: state._selectedBotDifficulty,
      );
  if (!ok || !state.mounted) return;

  Navigator.push(
    state.context,
    FadePageRoute(page: const DuelGameScreen()),
  );
}

Future<void> _quickMatchImpl(_DuelEntryScreenState state) async {
  state._triggerHaptic();
  final token = state.context.read<AuthProvider>().token;
  if (token == null || token.trim().isEmpty) {
    state._showSnackOnce('Lütfen giriş yapın.');
    return;
  }

  final ok = await state.context.read<DuelProvider>().quickMatch(
        token: token,
        category: state._selectedCategory,
        mode: state._selectedMode,
      );
  if (!ok || !state.mounted) return;

  Navigator.push(
    state.context,
    FadePageRoute(page: const DuelGameScreen()),
  );
}

Future<void> _joinRoomImpl(_DuelEntryScreenState state) async {
  state._triggerHaptic();
  final token = state.context.read<AuthProvider>().token;
  if (token == null || token.trim().isEmpty) {
    state._showSnackOnce('Lütfen giriş yapın.');
    return;
  }

  final rawCode = state._roomCodeController.text.trim();
  final roomCode = rawCode.replaceAll(RegExp(r'\s+'), '').toUpperCase();
  if (roomCode.isEmpty) {
    state._showSnackOnce('Oda kodunu girin.');
    return;
  }

  final ok = await state.context.read<DuelProvider>().joinSession(
        token: token,
        roomCode: roomCode,
      );
  if (!ok || !state.mounted) return;

  Navigator.push(
    state.context,
    FadePageRoute(page: const DuelGameScreen()),
  );
}
