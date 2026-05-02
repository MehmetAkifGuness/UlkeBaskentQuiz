// lib/screens/home_screen.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_profile_model.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../services/user.service.dart';
import '../theme/app_theme.dart';
import '../utils/page_trasitions.dart';
import '../widgets/geo_background.dart';
import '../widgets/glass_card.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserService _userService = UserService();

  bool _hasPlayedDaily = false;
  bool _isLoading = true;

  final List<_GeoCategory> _categories = const [
    _GeoCategory('Dünya', Icons.public),
    _GeoCategory('Avrupa', Icons.map),
    _GeoCategory('Asya', Icons.explore),
    _GeoCategory('Afrika', Icons.public),
    _GeoCategory('Kuzey Amerika', Icons.location_on),
    _GeoCategory('Güney Amerika', Icons.location_on_outlined),
    _GeoCategory('Okyanusya', Icons.waves),
  ];

  @override
  void initState() {
    super.initState();
    _checkDailyStatus();
  }

  Future<void> _checkDailyStatus() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    if (token == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    await Provider.of<GameProvider>(
      context,
      listen: false,
    ).checkAndLoadActiveGame(token);

    final UserProfileModel? profile = await _userService.getUserProfile(token);
    if (!mounted) return;
    setState(() {
      _hasPlayedDaily = profile?.hasPlayedDaily ?? false;
      _isLoading = false;
    });
  }

  void _triggerHaptic() {
    Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).triggerButtonVibration();
  }

  void _continueGame() {
    _triggerHaptic();
    Navigator.push(
      context,
      FadePageRoute(
        page: const GameScreen(
          category: 'Devam',
          mode: 'Devam',
          isContinuing: true,
        ),
      ),
    ).then((_) => _checkDailyStatus());
  }

  void _startDaily() {
    _triggerHaptic();
    Provider.of<GameProvider>(context, listen: false).resetGame();
    Navigator.push(
      context,
      FadePageRoute(
        page: const GameScreen(
          category: 'DailyChallenge',
          mode: 'MIXED',
          isContinuing: false,
        ),
      ),
    ).then((_) => _checkDailyStatus());
  }

  void _startEndless() {
    _triggerHaptic();
    Provider.of<GameProvider>(context, listen: false).resetGame();
    Navigator.push(
      context,
      FadePageRoute(
        page: const GameScreen(
          category: 'Dünya',
          mode: 'ENDLESS',
          isContinuing: false,
        ),
      ),
    ).then((_) => _checkDailyStatus());
  }

  Future<void> _openFreeModeSheet() async {
    _triggerHaptic();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) {
        final size = MediaQuery.of(context).size;
        return SizedBox(
          height: size.height,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(color: Colors.black.withOpacity(0.40)),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _FreeModeSheet(
                  categories: _categories,
                  onStart: (mode, category) {
                    Provider.of<GameProvider>(
                      context,
                      listen: false,
                    ).resetGame();
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      FadePageRoute(
                        page: GameScreen(
                          category: category,
                          mode: mode,
                          isContinuing: false,
                        ),
                      ),
                    ).then((_) => _checkDailyStatus());
                  },
                  onHaptic: _triggerHaptic,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final gameProvider = context.watch<GameProvider>();

    final username = authProvider.username ?? 'Kaşif';
    final hasActiveGame =
        gameProvider.status != null && gameProvider.status?.finished == false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GeoBackground(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryBlue),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                physics: const BouncingScrollPhysics(),
                children: [
                  Text(
                    'Hoş Geldin, $username!',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Zihnini zorlamaya ve zirveye tırmanmaya hazır mısın?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (hasActiveGame)
                    _ContinueCard(
                      score: gameProvider.status?.currentScore ?? 0,
                      lives: gameProvider.status?.remainingLives ?? 0,
                      onTap: _continueGame,
                    ),
                  const SizedBox(height: 14),
                  _DailyCard(
                    completed: _hasPlayedDaily,
                    onStart: _hasPlayedDaily ? null : _startDaily,
                  ),
                  const SizedBox(height: 14),
                  _EndlessCard(onStart: _startEndless),
                  const SizedBox(height: 16),
                  _FreeModeButton(onPressed: _openFreeModeSheet),
                ],
              ),
      ),
    );
  }
}

class _GeoCategory {
  final String title;
  final IconData icon;

  const _GeoCategory(this.title, this.icon);
}

class _ContinueCard extends StatelessWidget {
  final int score;
  final int lives;
  final VoidCallback onTap;

  const _ContinueCard({
    required this.score,
    required this.lives,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      tint: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.successGreen.withOpacity(0.26),
                  AppColors.surface2.withOpacity(0.40),
                ],
              ),
            ),
            child: const Icon(
              Icons.play_arrow,
              color: AppColors.successGreen,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kaldığın Yerden\nDevam Et',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _Badge(
                      label: 'Skor: $score',
                      color: AppColors.successGreen,
                    ),
                    _Badge(label: 'Can: $lives', color: AppColors.errorRed),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 26),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderLight),
        color: color.withOpacity(0.16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  final bool completed;
  final VoidCallback? onStart;

  const _DailyCard({required this.completed, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      tint: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
                color: AppColors.surface2.withOpacity(0.35),
              ),
              child: Icon(
                completed ? Icons.check_circle : Icons.calendar_month,
                color: completed
                    ? AppColors.successGreen
                    : AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Günün Görevi',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
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
                backgroundColor: completed
                    ? AppColors.borderLight
                    : const Color(0xFF7C3AED),
                foregroundColor: AppColors.textDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.rocket_launch, size: 18),
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
                  AppColors.errorRed.withOpacity(0.25),
                  AppColors.surface2.withOpacity(0.35),
                ],
              ),
            ),
            child: const Icon(
              Icons.all_inclusive,
              color: AppColors.errorRed,
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
              color: AppColors.errorRed,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.bolt, color: AppColors.errorRed, size: 18),
        ],
      ),
    );
  }
}

class _FreeModeButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _FreeModeButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      tint: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: Row(
        children: const [
          Icon(Icons.public, color: AppColors.primaryBlue),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Serbest Modda Oyna',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _FreeModeSheet extends StatefulWidget {
  final List<_GeoCategory> categories;
  final void Function(String mode, String category) onStart;
  final VoidCallback onHaptic;

  const _FreeModeSheet({
    required this.categories,
    required this.onStart,
    required this.onHaptic,
  });

  @override
  State<_FreeModeSheet> createState() => _FreeModeSheetState();
}

class _FreeModeSheetState extends State<_FreeModeSheet> {
  String _selectedMode = 'COUNTRY_TO_CAPITAL';
  _GeoCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    if (widget.categories.isNotEmpty) {
      _selectedCategory = widget.categories.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final height = size.height * 0.88;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SizedBox(
        height: height,
        child: GlassCard(
          padding: EdgeInsets.zero,
          blurSigma: 22,
          tint: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: AppColors.borderLight.withOpacity(0.7),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Oyun Modunu Seç',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ModeChip(
                      label: 'Ülke -> Başkent',
                      selected: _selectedMode == 'COUNTRY_TO_CAPITAL',
                      onTap: () {
                        widget.onHaptic();
                        setState(() => _selectedMode = 'COUNTRY_TO_CAPITAL');
                      },
                    ),
                    _ModeChip(
                      label: 'Başkent -> Ülke',
                      selected: _selectedMode == 'CAPITAL_TO_COUNTRY',
                      onTap: () {
                        widget.onHaptic();
                        setState(() => _selectedMode = 'CAPITAL_TO_COUNTRY');
                      },
                    ),
                    _ModeChip(
                      label: 'Karışık',
                      selected: _selectedMode == 'MIXED',
                      accent: const Color(0xFFF97316),
                      onTap: () {
                        widget.onHaptic();
                        setState(() => _selectedMode = 'MIXED');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Nerede oynamak istersin?',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final category = widget.categories[index];
                    final selected = category.title == _selectedCategory?.title;
                    return _CategoryTile(
                      title: category.title,
                      icon: category.icon,
                      selected: selected,
                      onTap: () {
                        widget.onHaptic();
                        setState(() => _selectedCategory = category);
                      },
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: widget.categories.length,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedCategory == null
                        ? null
                        : () {
                            widget.onHaptic();
                            widget.onStart(
                              _selectedMode,
                              _selectedCategory!.title,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'OYUNU BAŞLAT',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? accent;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final active = accent ?? AppColors.primaryBlue;
    final bg = selected ? active.withOpacity(0.28) : AppColors.surface2;
    final fg = selected ? AppColors.textDark : AppColors.textMuted;
    final border = selected ? active.withOpacity(0.45) : AppColors.borderLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: bg.withOpacity(0.9),
            border: Border.all(color: border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = selected
        ? AppColors.primaryBlue.withOpacity(0.45)
        : AppColors.borderLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
            color: AppColors.surface2.withOpacity(0.55),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                  color: AppColors.surface.withOpacity(0.35),
                ),
                child: Icon(icon, color: AppColors.successGreen),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
