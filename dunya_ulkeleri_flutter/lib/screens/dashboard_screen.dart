import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recent_session_model.dart';
import '../models/user_profile_model.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../services/user.service.dart';
import '../theme/app_theme.dart';
import '../utils/error_message_utils.dart';
import '../utils/page_trasitions.dart';
import '../widgets/geo_background.dart';
import '../widgets/geo_top_bar.dart';
import '../widgets/glass_card.dart';
import 'conquest_bot_screen.dart';
import 'conquest_online_entry_screen.dart';
import 'conquest_practice_screen.dart';
import 'world_map_screen.dart';

part 'dashboard_screen/hero_nav_cards.dart';
part 'dashboard_screen/models.dart';
part 'dashboard_screen/streak_recent_cards.dart';

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

  void _showErrorSnack(String message) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.errorRed,
        ),
      );
    });
  }

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
    List<RecentSessionModel> recent = const [];
    try {
      recent = await _userService.getRecentSessions(token, limit: 3);
    } catch (e) {
      _showErrorSnack(errorMessageFrom(e));
    }

    return _DashboardData(profile: profile, recentSessions: recent);
  }

  void _goToTab(int index) {
    Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).triggerButtonVibration();
    widget.onNavigateTab?.call(index);
  }

  void _openWorldMap() {
    Provider.of<SettingsProvider>(context, listen: false).triggerButtonVibration();
    Navigator.push(context, FadePageRoute(page: const WorldMapScreen()));
  }

  void _openConquestPractice() {
    Provider.of<SettingsProvider>(context, listen: false).triggerButtonVibration();
    Navigator.push(context, FadePageRoute(page: const ConquestPracticeScreen()));
  }

  void _openConquestBot() {
    Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).triggerButtonVibration();
    Navigator.push(context, FadePageRoute(page: const ConquestBotScreen()));
  }

  void _openConquestOnline() {
    Provider.of<SettingsProvider>(context, listen: false).triggerButtonVibration();
    Navigator.push(
      context,
      FadePageRoute(page: const ConquestOnlineEntryScreen()),
    );
  }

  void _refresh() {
    setState(() {
      _dashboardFuture = _loadDashboard();
    });
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
                            onAvatarTap: () => _goToTab(4),
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
                                onTap: () => _goToTab(3),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MiniNavCard(
                                icon: Icons.person_rounded,
                                title: 'Profil',
                                subtitle: 'İstatistikler',
                                onTap: () => _goToTab(4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _MiniNavCard(
                          icon: Icons.map_outlined,
                          title: 'Dünya Haritası',
                          subtitle: 'Ülkeleri harita üzerinden öğren',
                          onTap: _openWorldMap,
                        ),
                        const SizedBox(height: 12),
                        _MiniNavCard(
                          icon: Icons.public_rounded,
                          title: 'Dünya Fethi Pratik',
                          subtitle: 'Hedef ülkeyi bul, doğru bil ve haritada fethet.',
                          onTap: _openConquestPractice,
                        ),
                        const SizedBox(height: 12),
                        _MiniNavCard(
                          icon: Icons.smart_toy_outlined,
                          title: 'Botlarla Dünya Fethi',
                          subtitle:
                              'Kolay, orta veya zor botlara karşı ülkeleri fethet.',
                          onTap: _openConquestBot,
                        ),
                        const SizedBox(height: 12),
                        _MiniNavCard(
                          icon: Icons.wifi_tethering_rounded,
                          title: 'Online Dünya Fethi',
                          subtitle:
                              'Oda kur, arkadaşlarınla ülkeleri fethet.',
                          onTap: _openConquestOnline,
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

