part of '../leaderboard_screen.dart';

class _RankBadge extends StatelessWidget {
  final int rank;
  final Color color;

  const _RankBadge({required this.rank, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: AppColors.background, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _RankList extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final String? myUsername;
  final Map<String, Uint8List> avatarBytesByUsername;

  const _RankList({
    required this.users,
    required this.myUsername,
    required this.avatarBytesByUsername,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < users.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RankRow(
              rank: i + 1,
              user: users[i],
              avatarBytesByUsername: avatarBytesByUsername,
              highlight:
                  myUsername != null &&
                  users[i]['username']?.toString() == myUsername,
            ),
          ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> user;
  final Map<String, Uint8List> avatarBytesByUsername;
  final bool highlight;

  const _RankRow({
    required this.rank,
    required this.user,
    required this.avatarBytesByUsername,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final username = user['username']?.toString() ?? '—';
    final score = (user['score'] is num)
        ? (user['score'] as num).toInt()
        : user['score'] ?? 0;
    final avatarId = (user['avatarId'] is num)
        ? (user['avatarId'] as num).toInt()
        : AppAvatar.stableAvatarIdFromText(username);
    final avatarBytes = avatarBytesByUsername[username];

    return GlassCard(
      tint: highlight ? AppColors.primaryBlueHover : AppColors.surface2,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              rank.toString().padLeft(2, '0'),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          AppAvatar(
            avatarId: avatarId,
            size: 36,
            showDot: highlight,
            imageBytes: avatarBytes,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            score.toString(),
            style: const TextStyle(
              color: AppColors.lightBlueHover,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'PUAN',
            style: TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
