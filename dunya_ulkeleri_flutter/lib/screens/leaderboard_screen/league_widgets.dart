part of '../leaderboard_screen.dart';

class _LeagueLeaderboardView extends StatelessWidget {
  final LeagueLeaderboardModel leaderboard;
  final Map<String, Uint8List> avatarBytesByUsername;

  const _LeagueLeaderboardView({
    required this.leaderboard,
    required this.avatarBytesByUsername,
  });

  @override
  Widget build(BuildContext context) {
    final current = leaderboard.currentUser;
    final currentInTop = current != null && leaderboard.topPlayers.any(
      (entry) => entry.username == current.username,
    );

    return Column(
      children: [
        GlassCard(
          tint: AppColors.primaryBlueHover,
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(22),
          child: Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: AppColors.yellow, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KUPA LİGİ',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Sezon ${leaderboard.season} • ${leaderboard.totalPlayers} oyuncu',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'TOP 100',
                style: TextStyle(
                  color: AppColors.lightBlueHover,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final entry in leaderboard.topPlayers)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _LeagueRankRow(
              entry: entry,
              avatarBytes: avatarBytesByUsername[entry.username],
            ),
          ),
        if (current != null && !currentInTop) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Divider(color: AppColors.borderLight)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'SENİN SIRAN',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: AppColors.borderLight)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _LeagueRankRow(
            entry: current,
            avatarBytes: avatarBytesByUsername[current.username],
          ),
        ],
      ],
    );
  }
}

class _LeagueRankRow extends StatelessWidget {
  final LeagueLeaderboardEntry entry;
  final Uint8List? avatarBytes;

  const _LeagueRankRow({required this.entry, required this.avatarBytes});

  @override
  Widget build(BuildContext context) {
    final color = _leagueColor(entry.league);
    return GlassCard(
      tint: entry.currentUser ? color.withValues(alpha: 0.16) : AppColors.surface2,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              entry.rank.toString().padLeft(2, '0'),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          AppAvatar(
            avatarId: entry.avatarId,
            size: 38,
            showDot: entry.currentUser,
            imageBytes: avatarBytes,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                Text(
                  entry.league,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            entry.trophies.toString(),
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 5),
          Icon(Icons.emoji_events_rounded, color: color, size: 18),
        ],
      ),
    );
  }
}

Color _leagueColor(String league) {
  final value = league.toLowerCase();
  if (value.contains('usta')) return const Color(0xFFEF4444);
  if (value.contains('elmas')) return const Color(0xFF0EA5E9);
  if (value.contains('platin')) return const Color(0xFF64748B);
  if (value.contains('alt')) return const Color(0xFFF59E0B);
  if (value.contains('güm') || value.contains('gum')) return const Color(0xFF94A3B8);
  return const Color(0xFFB7791F);
}
