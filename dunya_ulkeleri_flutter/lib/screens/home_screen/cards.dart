part of '../home_screen.dart';

class _GeoCategory {
  final String title;
  final IconData icon;

  const _GeoCategory(this.title, this.icon);
}

class _ContinueCard extends StatelessWidget {
  final int score;
  final int lives;
  final VoidCallback onTap;

  const _ContinueCard({
    required this.score,
    required this.lives,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      tint: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.successGreen.withValues(alpha: 0.26),
                  AppColors.surface2.withValues(alpha: 0.40),
                ],
              ),
            ),
            child: const Icon(
              Icons.play_arrow,
              color: AppColors.successGreen,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kaldığın Yerden\nDevam Et',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _Badge(
                      label: 'Skor: $score',
                      color: AppColors.successGreen,
                    ),
                    _Badge(label: 'Can: $lives', color: AppColors.errorRed),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textMuted,
            size: 26,
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderLight),
        color: color.withValues(alpha: 0.16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
