part of '../profile_screen.dart';

class _LeagueProgressCard extends StatelessWidget {
  final UserProfileModel profile;

  const _LeagueProgressCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final hasNextLeague = profile.nextLeague.isNotEmpty;
    final range = profile.nextLeagueMinTrophies - profile.leagueMinTrophies;
    final progress = !hasNextLeague || range <= 0
        ? 1.0
        : ((profile.trophies - profile.leagueMinTrophies) / range)
            .clamp(0.0, 1.0);

    return GlassCard(
      tint: AppColors.primaryBlueHover,
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_rounded, color: AppColors.primaryBlue, size: 25),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Kupa Ligi',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              Text(
                '${_formatLeagueNumber(profile.trophies)} kupa',
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                profile.league,
                style: const TextStyle(
                  color: AppColors.lightBlueHover,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  hasNextLeague
                      ? '${profile.trophiesToNextLeague} kupa sonra ${profile.nextLeague}'
                      : 'En yüksek lig',
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: AppColors.borderLight.withValues(alpha: 0.55),
              valueColor: const AlwaysStoppedAnimation(AppColors.primaryBlue),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Text(
                hasNextLeague
                    ? '${_formatLeagueNumber(profile.leagueMinTrophies)} - ${_formatLeagueNumber(profile.nextLeagueMinTrophies)} kupa'
                    : 'Sezon ${profile.trophySeason}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  '${profile.seasonDaysRemaining} gün sonra sezon yenilenir',
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatLeagueNumber(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write('.');
    buffer.write(text[i]);
  }
  return buffer.toString();
}
