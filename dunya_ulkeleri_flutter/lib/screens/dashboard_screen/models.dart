part of '../dashboard_screen.dart';

class _DashboardData {
  final UserProfileModel? profile;
  final List<RecentSessionModel> recentSessions;

  const _DashboardData({required this.profile, required this.recentSessions});
}

int _nextRewardInDays(int streakDays) {
  const rewardEvery = 7;
  if (streakDays <= 0) return rewardEvery;
  final mod = streakDays % rewardEvery;
  final remaining = mod == 0 ? 0 : rewardEvery - mod;
  return remaining;
}

double _streakProgress(int streakDays) {
  const rewardEvery = 7;
  if (streakDays <= 0) return 0;
  final mod = streakDays % rewardEvery;
  if (mod == 0) return 1.0;
  return (mod / rewardEvery).clamp(0.0, 1.0);
}

List<_RecentUiItem> _mapRecentItems(List<RecentSessionModel> sessions) {
  return sessions.map(_RecentUiItem.fromSession).toList();
}

class _RecentUiItem {
  final String title;
  final String subtitle;
  final String badge;
  final String scoreText;
  final Color accent;

  const _RecentUiItem({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.scoreText,
    required this.accent,
  });

  factory _RecentUiItem.fromSession(RecentSessionModel session) {
    final modeLabel = switch (session.gameMode) {
      'COUNTRY_TO_CAPITAL' => 'Ülke → Başkent',
      'CAPITAL_TO_COUNTRY' => 'Başkent → Ülke',
      'MIXED' => 'Karışık',
      'ENDLESS' => 'Sonsuz',
      _ => session.gameMode,
    };

    final when = _timeAgo(session.updateAt ?? session.createdAt);
    final subtitle = when == null ? modeLabel : '$when • $modeLabel';
    final badge = session.category.toUpperCase();

    final accent = switch (session.gameMode) {
      'ENDLESS' => AppColors.errorRed,
      'MIXED' => AppColors.yellow,
      'CAPITAL_TO_COUNTRY' => AppColors.successGreen,
      _ => AppColors.primaryBlue,
    };

    return _RecentUiItem(
      title: session.category,
      subtitle: subtitle,
      badge: badge,
      scoreText: '${session.currentScore}',
      accent: accent,
    );
  }

  static String? _timeAgo(DateTime? dt) {
    if (dt == null) return null;
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    return '${diff.inDays} gün önce';
  }
}

