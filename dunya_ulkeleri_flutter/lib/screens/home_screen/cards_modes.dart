part of '../home_screen.dart';

class _DailyCard extends StatelessWidget {
  final bool completed;
  final VoidCallback? onStart;

  const _DailyCard({required this.completed, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      tint: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderLight),
                  color: AppColors.actionBlue.withValues(alpha: 0.18),
                ),
                child: Icon(
                  completed ? Icons.check_circle : Icons.emoji_events_rounded,
                  color: completed ? AppColors.successGreen : AppColors.primaryBlue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Günün Görevi',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            completed
                ? 'Bugünkü görevi tamamladın.\nYarın tekrar gel.'
                : 'Dünyadaki herkesle aynı 10 soruyu çöz ve liderlik tablosuna gir!',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    completed ? AppColors.borderLight : AppColors.actionBlue,
                disabledBackgroundColor: AppColors.borderLight,
                foregroundColor: AppColors.textDark,
                disabledForegroundColor: AppColors.textMuted,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              icon: Icon(
                completed ? Icons.check_rounded : Icons.send_rounded,
                size: 18,
              ),
              label: Text(
                completed ? 'Tamamlandı' : 'Görevi Başlat',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EndlessCard extends StatelessWidget {
  final VoidCallback onStart;

  const _EndlessCard({required this.onStart});

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.primaryBlue;
    return GlassCard(
      onTap: onStart,
      padding: const EdgeInsets.all(16),
      tint: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.22),
                  AppColors.surface2.withValues(alpha: 0.35),
                ],
              ),
            ),
            child: const Icon(
              Icons.all_inclusive,
              color: accent,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Sonsuz Mod',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Tek bir yanlışta oyun biter! Bakalım ne kadar dayanacaksın?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Meydan Oku',
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.bolt, color: accent, size: 18),
        ],
      ),
    );
  }
}

class _DuelCard extends StatelessWidget {
  final VoidCallback onStart;

  const _DuelCard({required this.onStart});

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.yellow;
    return GlassCard(
      onTap: onStart,
      padding: const EdgeInsets.all(16),
      tint: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.22),
                  AppColors.surface2.withValues(alpha: 0.35),
                ],
              ),
            ),
            child: const Icon(
              Icons.sports_kabaddi_rounded,
              color: accent,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Online Düello',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Lig & kupa sistemiyle 1v1 ülke/başkent kapışması.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Başla',
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.emoji_events_rounded, color: accent, size: 18),
        ],
      ),
    );
  }
}
