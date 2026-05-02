import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recent_session_model.dart';
import '../models/user_profile_model.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../services/user.service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_avatar.dart';
import '../widgets/geo_background.dart';
import '../widgets/geo_top_bar.dart';
import '../widgets/glass_card.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final bool isActive;

  const DashboardScreen({super.key, this.onNavigateTab, this.isActive = false});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final UserService _userService = UserService();
  Future<_DashboardData>? _dashboardFuture;

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _dashboardFuture = _loadDashboard();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dashboardFuture ??= _loadDashboard();
  }

  Future<_DashboardData> _loadDashboard() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      return const _DashboardData(profile: null, recentSessions: []);
    }

    final profile = await _userService.getUserProfile(token);
    final recent = await _userService.getRecentSessions(token, limit: 3);
    return _DashboardData(profile: profile, recentSessions: recent);
  }

  void _goToTab(int index) {
    Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).triggerButtonVibration();
    widget.onNavigateTab?.call(index);
  }

  void _refresh() {
    setState(() => _dashboardFuture = _loadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final username = context.watch<AuthProvider>().username ?? 'Kaşif';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GeoBackground(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _refresh(),
                child: FutureBuilder<_DashboardData>(
                  future: _dashboardFuture,
                  builder: (context, snapshot) {
                    final profile = snapshot.data?.profile;
                    final recentSessions =
                        snapshot.data?.recentSessions ?? const [];

                    final avatarId =
                        profile?.avatarId ??
                        AppAvatar.stableAvatarIdFromText(username);

                    final dailyStreak = profile?.dailyStreak ?? 0;
                    final streakProgress = _streakProgress(dailyStreak);
                    final nextRewardInDays = _nextRewardInDays(dailyStreak);

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          child: GeoTopBar(
                            avatarId: avatarId,
                            onAvatarTap: () => _goToTab(3),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _HeroCard(
                          username: username,
                          onStartQuiz: () => _goToTab(1),
                          onViewTutorial: () {
                            Provider.of<SettingsProvider>(
                              context,
                              listen: false,
                            ).triggerButtonVibration();
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: AppColors.surface2,
                                title: const Text(
                                  'Kısa Rehber',
                                  style: TextStyle(color: AppColors.textDark),
                                ),
                                content: const Text(
                                  'Oyun sekmesinden oyun modunu seçip başlayabilirsin. '
                                  'Sıralama sekmesinde liderlik tablosunu görebilirsin.',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Tamam'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _MiniNavCard(
                                icon: Icons.leaderboard_rounded,
                                title: 'Sıralama',
                                subtitle: 'Sıralamayı gör',
                                onTap: () => _goToTab(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MiniNavCard(
                                icon: Icons.person_rounded,
                                title: 'Profil',
                                subtitle: 'İstatistikler',
                                onTap: () => _goToTab(3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _StreakCard(
                          onTap: () => _goToTab(1),
                          streakDays: dailyStreak,
                          progress: streakProgress,
                          nextRewardInDays: nextRewardInDays,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Son Performans',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (recentSessions.isEmpty)
                          const Text(
                            'Henüz performans kaydı yok.',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          for (final item in _mapRecentItems(recentSessions))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _RecentItemCard(
                                title: item.title,
                                subtitle: item.subtitle,
                                badge: item.badge,
                                scoreText: item.scoreText,
                                accent: item.accent,
                              ),
                            ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class _HeroCard extends StatelessWidget {
  final String username;
  final VoidCallback onStartQuiz;
  final VoidCallback onViewTutorial;

  const _HeroCard({
    required this.username,
    required this.onStartQuiz,
    required this.onViewTutorial,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoş geldin, $username',
            style: const TextStyle(
              fontSize: 24,
              height: 1.1,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sınırları, başkentleri ve kültürleri test etmeye hazır mısın?',
            style: const TextStyle(
              color: AppColors.textMuted,
              height: 1.4,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onStartQuiz,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Oyuna Başla',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewTutorial,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: AppColors.textDark,
                    side: const BorderSide(color: AppColors.borderLight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Kısa Rehber',
                    style: TextStyle(fontWeight: FontWeight.w800),
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

class _MiniNavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MiniNavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryBlue.withOpacity(0.14),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Icon(icon, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final VoidCallback onTap;
  final int streakDays;
  final double progress;
  final int nextRewardInDays;

  const _StreakCard({
    required this.onTap,
    required this.streakDays,
    required this.progress,
    required this.nextRewardInDays,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'GÜNLÜK SERİ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.textMuted,
                ),
              ),
              Spacer(),
              Icon(
                Icons.bolt_rounded,
                color: AppColors.lightBlueHover,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$streakDays',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'Gün Aktif',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: AppColors.borderLight),
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(gradient: AppGradients.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            nextRewardInDays == 0
                ? 'Ödül hazır!'
                : 'Sonraki ödül $nextRewardInDays gün sonra',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final String scoreText;
  final Color accent;

  const _RecentItemCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.scoreText,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withOpacity(0.28),
                  AppColors.surface2.withOpacity(0.35),
                ],
              ),
            ),
            child: Center(
              child: Text(
                badge,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            scoreText,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
