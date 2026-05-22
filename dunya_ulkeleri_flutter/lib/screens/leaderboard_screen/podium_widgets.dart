part of '../leaderboard_screen.dart';

class _EmptyState extends StatelessWidget {
  final String category;

  const _EmptyState({required this.category});

  @override
  Widget build(BuildContext context) {
    final message = category == "🔥 Günün Görevi"
        ? "Bugün listeye henüz kimse giremedi.\nİlk giren sen ol!"
        : category == "♾️ Sonsuz Mod"
        ? "Sonsuz modda henüz kimse rekor kırmadı.\nİlk rekoru sen belirle!"
        : "Bu modda henüz skor yok.";

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          height: 1.45,
        ),
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final String category;
  final String? mode;
  final List<Map<String, dynamic>> users;
  final Map<String, Uint8List> avatarBytesByUsername;

  const _PodiumCard({
    required this.category,
    required this.mode,
    required this.users,
    required this.avatarBytesByUsername,
  });

  @override
  Widget build(BuildContext context) {
    final top = users.take(3).toList();
    Map<String, dynamic>? first = top.isNotEmpty ? top[0] : null;
    Map<String, dynamic>? second = top.length >= 2 ? top[1] : null;
    Map<String, dynamic>? third = top.length >= 3 ? top[2] : null;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          const Text(
            'SEZON SIRALAMASI',
            style: TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _titleText(),
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Container(color: AppColors.borderLight),
                  const FractionallySizedBox(
                    widthFactor: 0.55,
                    child: DecoratedBox(
                      decoration: BoxDecoration(gradient: AppGradients.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _PodiumUser(
                  rank: 2,
                  user: second,
                  size: 72,
                  ring: const Color(0xFFCBD5E1),
                  avatarBytesByUsername: avatarBytesByUsername,
                ),
              ),
              Expanded(
                child: _PodiumUser(
                  rank: 1,
                  user: first,
                  size: 92,
                  ring: AppColors.yellow,
                  avatarBytesByUsername: avatarBytesByUsername,
                ),
              ),
              Expanded(
                child: _PodiumUser(
                  rank: 3,
                  user: third,
                  size: 72,
                  ring: const Color(0xFFF59E0B),
                  avatarBytesByUsername: avatarBytesByUsername,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _titleText() {
    final modeText = (mode == null || mode!.isEmpty) ? '' : ' • $mode';
    return '$category$modeText';
  }
}

class _PodiumUser extends StatelessWidget {
  final int rank;
  final Map<String, dynamic>? user;
  final double size;
  final Color ring;
  final Map<String, Uint8List> avatarBytesByUsername;

  const _PodiumUser({
    required this.rank,
    required this.user,
    required this.size,
    required this.ring,
    required this.avatarBytesByUsername,
  });

  @override
  Widget build(BuildContext context) {
    final username = user?['username']?.toString() ?? '—';
    final score = (user?['score'] is num)
        ? (user!['score'] as num).toInt()
        : user?['score'] ?? 0;
    final avatarId = (user?['avatarId'] is num)
        ? (user!['avatarId'] as num).toInt()
        : AppAvatar.stableAvatarIdFromText(username);
    final avatarBytes = avatarBytesByUsername[username];

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: size + 10,
              height: size + 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ring.withValues(alpha: 0.25),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(color: ring.withValues(alpha: 0.8), width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: AppAvatar(
                  avatarId: avatarId,
                  size: size,
                  imageBytes: avatarBytes,
                ),
              ),
            ),
            Positioned(
              bottom: -8,
              child: _RankBadge(rank: rank, color: ring),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          username,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: rank == 1 ? AppColors.yellow : AppColors.textDark,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_formatScore(score)} PUAN',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  String _formatScore(int score) {
    final raw = score.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final idxFromEnd = raw.length - i;
      buffer.write(raw[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }
}


