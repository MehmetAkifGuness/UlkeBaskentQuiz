import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/conquest_session_dto.dart';
import '../providers/conquest_multiplayer_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/color_hex_utils.dart';
import '../utils/page_trasitions.dart';
import '../widgets/geo_background.dart';
import '../widgets/glass_card.dart';
import 'conquest_online_entry_screen.dart';
import 'conquest_online_game_screen.dart';

class ConquestOnlineLobbyScreen extends StatefulWidget {
  const ConquestOnlineLobbyScreen({super.key});

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
    await provider.leaveSession();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      FadePageRoute(page: const ConquestOnlineEntryScreen()),
    );
  }

  Future<void> _startGame(ConquestMultiplayerProvider provider) async {
    _triggerHaptic();
    final players = provider.sessionState?.players ?? const <ConquestPlayerState>[];
    if (players.length < 2) {
      _showSnackOnce('Rakip bekleniyor. Oyun başlatmak için en az 2 oyuncu gerekli.');
      return;
    }

    final allReady = players.isNotEmpty && players.every((p) => p.ready);
    if (!allReady) {
      _showSnackOnce('Oyunu başlatmak için iki oyuncu da hazır olmalı.');
      return;
    }
    await provider.startOnlineGame();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConquestMultiplayerProvider>();

    final error = provider.errorMessage;
    if (error != null) {
      _showSnackOnce(error);
      provider.clearError();
    }

    if (provider.isGameStarted && !_didAutoNavigateToGame) {
      _didAutoNavigateToGame = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          FadePageRoute(page: const ConquestOnlineGameScreen()),
        );
      });
    }

    final state = provider.sessionState;
    final isQuickMatch = state?.quickMatch ?? provider.isQuickMatchMode;
    final roomCode = (provider.roomCode ?? state?.roomCode ?? '').trim();
    final status = (state?.status ?? 'WAITING').toUpperCase();
    final players = state?.players ?? const <ConquestPlayerState>[];
    final allReady = players.isNotEmpty && players.every((p) => p.ready);
    final canToggleReady =
        provider.isConnected && state != null && !isQuickMatch && status == 'WAITING';
    final myId = (provider.playerId ?? '').trim();
    final me = myId.isEmpty
        ? null
        : players.cast<ConquestPlayerState?>().firstWhere(
              (p) => (p?.playerId ?? '').trim() == myId,
              orElse: () => null,
            );
    final amIReady = me?.ready ?? false;

    return Scaffold(
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
            GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Oda Kodu',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          roomCode.isEmpty ? '-' : roomCode,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: roomCode.isEmpty ? null : () => _copyRoomCode(roomCode),
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Kopyala'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text(
                        'Durum: ',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        status,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        provider.isConnected ? 'Bağlandı' : 'Bağlanıyor...',
                        style: TextStyle(
                          color: provider.isConnected
                              ? Colors.greenAccent
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  if (players.length < 2) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isQuickMatch ? 'Rakip aranıyor...' : 'Rakip bekleniyor...',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Oyuncular',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (players.isEmpty)
                    const Text(
                      'Oyuncu listesi bekleniyor...',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    Column(
                      children: [
                        for (final p in players)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PlayerRow(player: p),
                          ),
                      ],
                    ),
                  if (canToggleReady) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => provider.setReady(!amIReady),
                        icon: Icon(
                          amIReady ? Icons.check_circle : Icons.hourglass_bottom,
                          size: 18,
                        ),
                        label: Text(amIReady ? 'Hazırım' : 'Bekliyorum'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (!isQuickMatch)
              SizedBox(
                width: double.infinity,
                child: provider.isHost
                    ? ElevatedButton.icon(
                        onPressed: provider.isConnected &&
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
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final ConquestPlayerState player;

  const _PlayerRow({required this.player});

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(player.colorHex ?? '');
    final ready = player.ready;
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            (player.username ?? 'Oyuncu').toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Skor: ${player.score}',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          ready ? Icons.check_circle : Icons.hourglass_bottom,
          size: 18,
          color: ready ? Colors.greenAccent : AppColors.textMuted,
        ),
        const SizedBox(width: 8),
        Icon(
          player.connected ? Icons.wifi : Icons.wifi_off,
          size: 18,
          color: player.connected ? Colors.greenAccent : Colors.redAccent,
        ),
      ],
    );
  }
}

