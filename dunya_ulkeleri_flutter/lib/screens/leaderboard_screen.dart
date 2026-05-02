// lib/screens/leaderboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../services/user.service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_avatar.dart';
import '../widgets/geo_background.dart';
import '../widgets/geo_top_bar.dart';
import '../widgets/glass_card.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final UserService _userService = UserService();

  final List<String> _categories = const [
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
  String _selectedMode = "COUNTRY_TO_CAPITAL";

  List<Map<String, dynamic>> _leaderboardData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        String apiCategory = _selectedCategory;
        String apiMode = _selectedMode;

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
      }
    } catch (e) {
      // ignore: avoid_print
      print("Leaderboard hatası: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _categoryAccent(String category) {
    if (category == "🔥 Günün Görevi") return AppColors.errorRed;
    if (category == "♾️ Sonsuz Mod") return AppColors.brown;
    return AppColors.primaryBlue;
  }

  bool get _modeLocked =>
      _selectedCategory == "🔥 Günün Görevi" ||
      _selectedCategory == "♾️ Sonsuz Mod";

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
                avatarId: myUsername == null
                    ? null
                    : AppAvatar.stableAvatarIdFromText(myUsername),
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
                    if (!_modeLocked) _buildModePicker(),
                    if (_modeLocked)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _selectedCategory == "🔥 Günün Görevi"
                              ? 'Günün görevi karışık modda oynanır.'
                              : 'Sonsuz modda sorular bitmez.',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
                    else if (_leaderboardData.isEmpty)
                      _EmptyState(category: _selectedCategory)
                    else ...[
                      _PodiumCard(
                        category: _selectedCategory,
                        mode: _modeLocked ? null : _selectedMode,
                        users: _leaderboardData,
                      ),
                      const SizedBox(height: 14),
                      _RankList(
                        users: _leaderboardData,
                        myUsername: myUsername,
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
        separatorBuilder: (_, __) => const SizedBox(width: 10),
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
            backgroundColor: AppColors.surface2.withOpacity(0.55),
            selectedColor: accent.withOpacity(0.22),
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

  Widget _buildModePicker() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          _ModeChip(
            label: "Ülke → Başkent",
            selected: _selectedMode == "COUNTRY_TO_CAPITAL",
            onTap: () {
              Provider.of<SettingsProvider>(
                context,
                listen: false,
              ).triggerButtonVibration();
              setState(() => _selectedMode = "COUNTRY_TO_CAPITAL");
              _fetchLeaderboard();
            },
          ),
          _ModeChip(
            label: "Başkent → Ülke",
            selected: _selectedMode == "CAPITAL_TO_COUNTRY",
            onTap: () {
              Provider.of<SettingsProvider>(
                context,
                listen: false,
              ).triggerButtonVibration();
              setState(() => _selectedMode = "CAPITAL_TO_COUNTRY");
              _fetchLeaderboard();
            },
          ),
          _ModeChip(
            label: "🔀 Karışık",
            selected: _selectedMode == "MIXED",
            onTap: () {
              Provider.of<SettingsProvider>(
                context,
                listen: false,
              ).triggerButtonVibration();
              setState(() => _selectedMode = "MIXED");
              _fetchLeaderboard();
            },
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryBlue.withOpacity(0.22),
      backgroundColor: AppColors.surface2.withOpacity(0.55),
      side: BorderSide(
        color: selected ? AppColors.primaryBlue : AppColors.borderLight,
      ),
      labelStyle: TextStyle(
        color: selected ? AppColors.textDark : AppColors.textMuted,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

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

  const _PodiumCard({
    required this.category,
    required this.mode,
    required this.users,
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
                ),
              ),
              Expanded(
                child: _PodiumUser(
                  rank: 1,
                  user: first,
                  size: 92,
                  ring: AppColors.yellow,
                ),
              ),
              Expanded(
                child: _PodiumUser(
                  rank: 3,
                  user: third,
                  size: 72,
                  ring: const Color(0xFFF59E0B),
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

  const _PodiumUser({
    required this.rank,
    required this.user,
    required this.size,
    required this.ring,
  });

  @override
  Widget build(BuildContext context) {
    final username = user?['username']?.toString() ?? '—';
    final score = (user?['score'] is num)
        ? (user!['score'] as num).toInt()
        : user?['score'] ?? 0;

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
                    color: ring.withOpacity(0.25),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(color: ring.withOpacity(0.8), width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: AppAvatar(
                  avatarId: AppAvatar.stableAvatarIdFromText(username),
                  size: size,
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

  const _RankList({required this.users, required this.myUsername});

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
  final bool highlight;

  const _RankRow({
    required this.rank,
    required this.user,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final username = user['username']?.toString() ?? '—';
    final score = (user['score'] is num)
        ? (user['score'] as num).toInt()
        : user['score'] ?? 0;

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
            avatarId: AppAvatar.stableAvatarIdFromText(username),
            size: 36,
            showDot: highlight,
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
            '${score.toString()}',
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
