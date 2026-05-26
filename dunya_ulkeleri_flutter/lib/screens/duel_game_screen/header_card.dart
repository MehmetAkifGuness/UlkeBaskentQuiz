part of '../duel_game_screen.dart';

class _HeaderCard extends StatelessWidget {
  final String? roomCode;
  final String? category;
  final String? mode;
  final String? status;

  const _HeaderCard({
    required this.roomCode,
    required this.category,
    required this.mode,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      tint: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
              color: AppColors.actionBlue.withValues(alpha: 0.16),
            ),
            child: const Icon(
              Icons.sports_kabaddi_rounded,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roomCode == null || roomCode!.trim().isEmpty
                      ? 'Oda'
                      : 'Oda: ${roomCode!.trim()}',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(category ?? '-')} • ${(mode ?? '-')} • ${(status ?? '-')}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
