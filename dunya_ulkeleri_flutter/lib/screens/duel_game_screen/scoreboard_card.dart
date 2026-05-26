part of '../duel_game_screen.dart';

class _ScoreboardCard extends StatelessWidget {
  final String? myPlayerId;
  final List<DuelPlayerState> players;
  final String? winnerUsername;
  final bool finished;

  const _ScoreboardCard({
    required this.myPlayerId,
    required this.players,
    required this.winnerUsername,
    required this.finished,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      tint: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Skor',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (finished &&
                  winnerUsername != null &&
                  winnerUsername!.trim().isNotEmpty)
                Text(
                  'Kazanan: ${winnerUsername!.trim()}',
                  style: const TextStyle(
                    color: AppColors.yellow,
                    fontWeight: FontWeight.w900,
                  ),
                )
              else if (finished)
                const Text(
                  'Berabere',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (players.isEmpty)
            const Text(
              'Oyuncu bilgisi yok.',
              style:
                  TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
            )
          else
            for (final p in players) _playerRow(p),
          if (finished) ...[
            const SizedBox(height: 10),
            const Text(
              'Kupa güncellemesi maç sonunda uygulanır (profilde görebilirsin).',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _playerRow(DuelPlayerState p) {
    final isMe = (myPlayerId ?? '').trim().isNotEmpty &&
        (p.playerId ?? '').trim().isNotEmpty &&
        (p.playerId ?? '').trim() == (myPlayerId ?? '').trim();
    final name = (p.username ?? '').trim().isEmpty ? '-' : p.username!.trim();
    final label = isMe ? '$name (Sen)' : name;
    final color = isMe ? AppColors.primaryBlue : AppColors.textDark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
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
              color: AppColors.surface2.withValues(alpha: 0.5),
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
