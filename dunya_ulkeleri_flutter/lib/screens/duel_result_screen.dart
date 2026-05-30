import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/duel_session_dto.dart';
import '../providers/auth_provider.dart';
import '../providers/duel_provider.dart';
import '../theme/app_theme.dart';
import '../utils/page_trasitions.dart';
import '../widgets/geo_background.dart';
import '../widgets/glass_card.dart';
import 'duel_entry_screen.dart';

class DuelResultScreen extends StatefulWidget {
  final DuelSessionState initialState;

  const DuelResultScreen({super.key, required this.initialState});

  @override
  State<DuelResultScreen> createState() => _DuelResultScreenState();
}

class _DuelResultScreenState extends State<DuelResultScreen> {
  bool _isLeaving = false;

  Future<void> _exitToLobby() async {
    if (_isLeaving) return;
    setState(() => _isLeaving = true);

    final duel = context.read<DuelProvider>();
    final token = context.read<AuthProvider>().token;
    final navigator = Navigator.of(context);

    try {
      await duel.leaveSession(token: token);
    } catch (_) {}

    if (!mounted) return;
    navigator.pushAndRemoveUntil(
      FadePageRoute(page: const DuelEntryScreen()),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.initialState;
    final players = state.players;
    final modeLabel = _modeLabel(state.mode);
    final title = _resultTitle(state, players);
    final subtitle = _resultSubtitle(state, players);

    final bottomPad = MediaQuery.of(context).padding.bottom + 24.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _exitToLobby();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Maç Sonucu'),
          actions: [
            IconButton(
              tooltip: 'Lobi',
              icon: const Icon(Icons.meeting_room_outlined),
              onPressed: _isLeaving ? null : _exitToLobby,
            ),
          ],
        ),
        body: GeoBackground(
          safeArea: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad),
            physics: const BouncingScrollPhysics(),
            children: [
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _pill('Kategori', (state.category ?? '').trim().isEmpty ? '-' : state.category!.trim()),
                        const SizedBox(width: 10),
                        _pill('Mod', modeLabel),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Skor Tablosu',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (players.isEmpty)
                      const Text(
                        'Oyuncu bilgisi yok.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else
                      for (final p in players) _playerRow(p),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLeaving ? null : _exitToLobby,
                  icon: const Icon(Icons.exit_to_app_rounded),
                  label: const Text(
                    'LOBİYE DÖN',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _modeLabel(String? mode) {
    final m = (mode ?? '').trim().toUpperCase();
    return switch (m) {
      'COUNTRY_TO_CAPITAL' => 'Ülke → Başkent',
      'CAPITAL_TO_COUNTRY' => 'Başkent → Ülke',
      'MIXED' => 'Karışık',
      '' => '-',
      _ => m,
    };
  }

  static String _resultTitle(DuelSessionState state, List<DuelPlayerState> players) {
    final winner = _winnerName(state, players);
    if (winner != null) return 'Kazanan: $winner';
    return 'Berabere';
  }

  static String _resultSubtitle(DuelSessionState state, List<DuelPlayerState> players) {
    final room = (state.roomCode ?? '').trim();
    final parts = <String>[];
    if (room.isNotEmpty) parts.add('Oda: $room');
    final msg = (state.lastEventMessage ?? '').trim();
    if (msg.isNotEmpty) parts.add(msg);
    if (parts.isEmpty) return 'Maç tamamlandı.';
    return parts.join(' • ');
  }

  static String? _winnerName(DuelSessionState state, List<DuelPlayerState> players) {
    final raw = (state.winnerUsername ?? '').trim();
    if (raw.isNotEmpty) return raw;
    if (players.length < 2) return null;

    final sorted = List<DuelPlayerState>.from(players)
      ..sort((a, b) => b.score.compareTo(a.score));
    final top = sorted.first;
    final second = sorted[1];
    if (top.score == second.score) return null;
    final name = (top.username ?? '').trim();
    return name.isEmpty ? null : name;
  }

  static Widget _pill(String label, String value) {
    final v = value.trim().isEmpty ? '-' : value.trim();
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          color: AppColors.surface2.withValues(alpha: 0.45),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              v,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _playerRow(DuelPlayerState p) {
    final name = (p.username ?? '').trim().isEmpty ? '-' : p.username!.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (!p.connected)
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.borderLight),
              color: AppColors.surface.withValues(alpha: 0.45),
            ),
            child: Text(
              '${p.score}',
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
