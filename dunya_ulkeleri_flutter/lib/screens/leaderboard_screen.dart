// lib/screens/leaderboard_screen.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/settings_provider.dart';
import '../models/league_leaderboard_model.dart';
import '../services/user.service.dart';
import '../theme/app_theme.dart';
import '../utils/error_message_utils.dart';
import '../widgets/app_avatar.dart';
import '../widgets/geo_background.dart';
import '../widgets/geo_top_bar.dart';
import '../widgets/glass_card.dart';


part 'leaderboard_screen/podium_widgets.dart';
part 'leaderboard_screen/rank_widgets.dart';
part 'leaderboard_screen/league_widgets.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final UserService _userService = UserService();
  late final ProfileProvider _profileProvider;
  int _lastProfileRevision = 0;
  final Map<String, Uint8List> _customAvatarBytesByUsername = {};

  final List<String> _categories = const [
    'Ligler',
    "🔥 Günün Görevi",
    "♾️ Sonsuz Mod",
    "Dünya",
    "Avrupa",
    "Asya",
    "Afrika",
    "Kuzey Amerika",
    "Güney Amerika",
    "Okyanusya",
  ];

  String _selectedCategory = "🔥 Günün Görevi";

  List<Map<String, dynamic>> _leaderboardData = [];
  LeagueLeaderboardModel? _leagueLeaderboard;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    _lastProfileRevision = _profileProvider.revision;
    _profileProvider.addListener(_onProfileChanged);
    _fetchLeaderboard();
  }

  void _onProfileChanged() {
    final rev = _profileProvider.revision;
    if (rev == _lastProfileRevision) return;
    _lastProfileRevision = rev;
    if (!mounted) return;
    _customAvatarBytesByUsername.clear();
    _fetchLeaderboard();
  }

  @override
  void dispose() {
    _profileProvider.removeListener(_onProfileChanged);
    super.dispose();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        final isLeague = _selectedCategory == 'Ligler';
        _leagueLeaderboard = null;
        if (isLeague) {
          _leagueLeaderboard = await _userService.getLeagueLeaderboard(token);
          _leaderboardData = [];
          await _prefetchLeagueAvatars(token, _leagueLeaderboard!);
          return;
        }

        String apiCategory = _selectedCategory;
        String apiMode = 'MIXED';

        if (_selectedCategory == "🔥 Günün Görevi") {
          apiCategory = "DailyChallenge";
          apiMode = "MIXED";
        } else if (_selectedCategory == "♾️ Sonsuz Mod") {
          apiCategory = "Dünya";
          apiMode = "ENDLESS";
        }

        _leaderboardData = await _userService.getCategoryLeaderboard(
          token,
          apiCategory,
          apiMode,
        );

        await _prefetchCustomAvatars(token, _leaderboardData);
      }
    } catch (e) {
      _leaderboardData = [];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessageFrom(e)),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _prefetchLeagueAvatars(
    String token,
    LeagueLeaderboardModel leaderboard,
  ) async {
    final users = <Map<String, dynamic>>[
      for (final entry in leaderboard.topPlayers)
        {
          'username': entry.username,
          'hasCustomAvatar': entry.hasCustomAvatar,
        },
      if (leaderboard.currentUser != null)
        {
          'username': leaderboard.currentUser!.username,
          'hasCustomAvatar': leaderboard.currentUser!.hasCustomAvatar,
        },
    ];
    await _prefetchCustomAvatars(token, users);
  }

  Future<void> _prefetchCustomAvatars(
    String token,
    List<Map<String, dynamic>> users,
  ) async {
    final tasks = <Future<void>>[];
    final usernamesInList = <String>{};

    for (final user in users) {
      final username = user['username']?.toString();
      if (username == null || username.isEmpty) continue;
      usernamesInList.add(username);

      final hasCustomAvatar = user['hasCustomAvatar'] == true;
      if (!hasCustomAvatar) {
        _customAvatarBytesByUsername.remove(username);
        continue;
      }

      if (_customAvatarBytesByUsername.containsKey(username)) continue;

      tasks.add(
        _userService.getCustomAvatarBytes(token, username).then((bytes) {
          if (bytes == null) return;
          _customAvatarBytesByUsername[username] = bytes;
        }).catchError((_) {}),
      );
    }

    _customAvatarBytesByUsername.removeWhere((key, _) => !usernamesInList.contains(key));

    if (tasks.isEmpty) return;
    await Future.wait(tasks);

    if (!mounted) return;
    setState(() {});
  }

  Color _categoryAccent(String category) {
    if (category == "🔥 Günün Görevi") return AppColors.errorRed;
    if (category == "♾️ Sonsuz Mod") return AppColors.brown;
    return AppColors.primaryBlue;
  }

  @override
  Widget build(BuildContext context) {
    final myUsername = context.watch<AuthProvider>().username;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GeoBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GeoTopBar(
                title: 'GENEL SIRALAMA',
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryBlue,
                backgroundColor: AppColors.surface2,
                onRefresh: _fetchLeaderboard,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  children: [
                    _buildCategoryPicker(),
                    const SizedBox(height: 10),
                    const SizedBox(height: 14),
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: CircularProgressIndicator(
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      )
                    else if (_selectedCategory == 'Ligler' &&
                        _leagueLeaderboard != null)
                      _LeagueLeaderboardView(
                        leaderboard: _leagueLeaderboard!,
                        avatarBytesByUsername: _customAvatarBytesByUsername,
                      )
                    else if (_leaderboardData.isEmpty)
                      _EmptyState(category: _selectedCategory)
                    else ...[
                      _PodiumCard(
                        category: _selectedCategory,
                        mode: null,
                        users: _leaderboardData,
                        avatarBytesByUsername: _customAvatarBytesByUsername,
                      ),
                      const SizedBox(height: 14),
                      _RankList(
                        users: _leaderboardData,
                        myUsername: myUsername,
                        avatarBytesByUsername: _customAvatarBytesByUsername,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPicker() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = category == _selectedCategory;
          final accent = _categoryAccent(category);

          return ChoiceChip(
            selected: selected,
            label: Text(
              category,
              style: TextStyle(
                color: selected ? AppColors.textDark : AppColors.textMuted,
                fontWeight: FontWeight.w800,
              ),
            ),
            backgroundColor: AppColors.surface2.withValues(alpha: 0.55),
            selectedColor: accent.withValues(alpha: 0.22),
            side: BorderSide(color: selected ? accent : AppColors.borderLight),
            onSelected: (_) {
              Provider.of<SettingsProvider>(
                context,
                listen: false,
              ).triggerButtonVibration();
              setState(() => _selectedCategory = category);
              _fetchLeaderboard();
            },
          );
        },
      ),
    );
  }
}


