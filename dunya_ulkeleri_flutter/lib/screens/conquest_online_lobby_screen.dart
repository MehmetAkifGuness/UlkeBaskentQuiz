import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/conquest_session_dto.dart';
import '../providers/auth_provider.dart';
import '../providers/conquest_multiplayer_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/color_hex_utils.dart';
import '../utils/page_trasitions.dart';
import '../widgets/geo_background.dart';
import '../widgets/glass_card.dart';
import 'conquest_online_entry_screen.dart';
import 'conquest_online_game_screen.dart';

part 'conquest_online_lobby_screen/widgets.dart';

class ConquestOnlineLobbyScreen extends StatefulWidget {
  final bool autoNavigateToGame;

  const ConquestOnlineLobbyScreen({
    super.key,
    this.autoNavigateToGame = true,
  });

  @override
  State<ConquestOnlineLobbyScreen> createState() =>
      _ConquestOnlineLobbyScreenState();
}

class _ConquestOnlineLobbyScreenState extends State<ConquestOnlineLobbyScreen> {
  String? _lastSnackMessage;
  bool _didAutoNavigateToGame = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<ConquestMultiplayerProvider>();
      if (!provider.isConnected && provider.sessionId != null) {
        await provider.connectToCurrentSession();
      }
    });
  }

  void _triggerHaptic() {
    context.read<SettingsProvider>().triggerButtonVibration();
  }

  void _showSnackOnce(String message) {
    if (message.trim().isEmpty) return;
    if (_lastSnackMessage == message) return;
    _lastSnackMessage = message;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
          ),
        );
    });
  }

  Future<void> _copyRoomCode(String code) async {
    _triggerHaptic();
    await Clipboard.setData(ClipboardData(text: code));
    _showSnackOnce('Oda kodu kopyalandı.');
  }

  Future<void> _leave() async {
    _triggerHaptic();
    final provider = context.read<ConquestMultiplayerProvider>();
    final token = context.read<AuthProvider>().token;
    await provider.leaveSession(token: token);
    if (!mounted) return;
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    nav.pushReplacement(
      FadePageRoute(page: const ConquestOnlineEntryScreen()),
    );
  }

  Future<void> _startGame(ConquestMultiplayerProvider provider) async {
    _triggerHaptic();
    final players =
        provider.sessionState?.players ?? const <ConquestPlayerState>[];
    if (players.length < 2) {
      _showSnackOnce(
        'Rakip bekleniyor. Oyun başlatmak için en az 2 oyuncu gerekli.',
      );
      return;
    }

    final allReady = players.isNotEmpty && players.every((p) => p.ready);
    if (!allReady) {
      _showSnackOnce('Oyunu başlatmak için iki oyuncu da hazır olmalı.');
      return;
    }
    await provider.startOnlineGame();
  }

  Future<void> _resumeGame(ConquestMultiplayerProvider provider) async {
    _triggerHaptic();
    final resumed = await provider.resumeGame(
      token: context.read<AuthProvider>().token,
    );
    if (!mounted || !resumed) return;
    Navigator.pushReplacement(
      context,
      FadePageRoute(page: const ConquestOnlineGameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ConquestMultiplayerProvider>();

    final error = context.select<ConquestMultiplayerProvider, String?>(
      (p) => p.errorMessage,
    );
    if (error != null) {
      _showSnackOnce(error);
      provider.clearError();
    }

    final isGameStarted = context.select<ConquestMultiplayerProvider, bool>(
      (p) => p.isGameStarted,
    );
    if (widget.autoNavigateToGame && isGameStarted && !_didAutoNavigateToGame) {
      _didAutoNavigateToGame = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          FadePageRoute(page: const ConquestOnlineGameScreen()),
        );
      });
    }

    final state = context.select<ConquestMultiplayerProvider, ConquestSessionState?>(
      (p) => p.sessionState,
    );
    final isQuickMatchMode = context.select<ConquestMultiplayerProvider, bool>(
      (p) => p.isQuickMatchMode,
    );
    final roomCodeValue = context.select<ConquestMultiplayerProvider, String?>(
      (p) => p.roomCode,
    );
    final isConnected = context.select<ConquestMultiplayerProvider, bool>(
      (p) => p.isConnected,
    );
    final playerId = context.select<ConquestMultiplayerProvider, String?>(
      (p) => p.playerId,
    );

    final isQuickMatch = state?.quickMatch ?? isQuickMatchMode;
    final roomCode = (roomCodeValue ?? state?.roomCode ?? '').trim();
    final status = (state?.status ?? 'WAITING').toUpperCase();
    final players = state?.players ?? const <ConquestPlayerState>[];
    final allReady = players.isNotEmpty && players.every((p) => p.ready);
    final canToggleReady =
        isConnected && state != null && !isQuickMatch && status == 'WAITING';
    final myId = (playerId ?? '').trim();
    final me = myId.isEmpty
        ? null
        : players.cast<ConquestPlayerState?>().firstWhere(
              (p) => (p?.playerId ?? '').trim() == myId,
              orElse: () => null,
            );
    final amIReady = me?.ready ?? false;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _leave();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(isQuickMatch ? 'Hızlı Oyun Lobisi' : 'Online Lobi'),
          actions: [
            IconButton(
              onPressed: _leave,
              tooltip: 'Ayrıl',
              icon: const Icon(Icons.exit_to_app),
            ),
          ],
        ),
        body: GeoBackground(
          safeArea: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            physics: const BouncingScrollPhysics(),
            children: [
              _LobbyRoomCard(
                roomCode: roomCode,
                status: status,
                isConnected: isConnected,
                showWaiting: players.length < 2,
                waitingText:
                    isQuickMatch ? 'Rakip aranıyor...' : 'Rakip bekleniyor...',
                onCopyRoomCode:
                    roomCode.isEmpty ? null : () => _copyRoomCode(roomCode),
              ),
              const SizedBox(height: 14),
              _LobbyPlayersCard(
                players: players,
                canToggleReady: canToggleReady,
                amIReady: amIReady,
                onToggleReady: () => provider.setReady(!amIReady),
              ),
              const SizedBox(height: 14),
              if (status == 'PAUSED')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: !provider.isLoading
                        ? () => _resumeGame(provider)
                        : null,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Oyuna Dön'),
                  ),
                )
              else if (!isQuickMatch)
                SizedBox(
                  width: double.infinity,
                  child: (() {
                    final hostId = (state?.hostPlayerId ?? '').trim();
                    final isHost =
                        hostId.isNotEmpty && myId.isNotEmpty && hostId == myId;
                    return isHost;
                  })()
                      ? ElevatedButton.icon(
                          onPressed: isConnected &&
                                  state != null &&
                                  players.length >= 2 &&
                                  allReady
                              ? () => _startGame(provider)
                              : null,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Oyunu Başlat'),
                        )
                      : ElevatedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.lock_outline),
                          label: const Text('Oda sahibini bekle'),
                        ),
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _leave,
                  icon: const Icon(Icons.logout),
                  label: Text(isQuickMatch ? 'Eşleşmeyi İptal Et' : 'Ayrıl'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
