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
import 'duel_entry_screen.dart';

part 'home_screen/cards.dart';
part 'home_screen/free_mode_sheet.dart';
part 'home_screen/category_tile.dart';

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
                      child: Container(color: Colors.black.withValues(alpha: 0.40)),
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
    final bottomPad = MediaQuery.of(context).padding.bottom + 120.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GeoBackground(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryBlue),
              )
            : ListView(
                padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPad),
                physics: const BouncingScrollPhysics(),
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                        height: 1.1,
                      ),
                      children: [
                        const TextSpan(text: 'Hoş Geldin, '),
                        TextSpan(
                          text: '$username!',
                          style: const TextStyle(color: AppColors.primaryBlue),
                        ),
                      ],
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
                  const SizedBox(height: 14),
                  _DuelCard(
                    onStart: () {
                      _triggerHaptic();
                      Navigator.push(
                        context,
                        FadePageRoute(page: const DuelEntryScreen()),
                      ).then((_) => _checkDailyStatus());
                    },
                  ),
                  const SizedBox(height: 16),
                  _FreeModeButton(onPressed: _openFreeModeSheet),
                ],
              ),
      ),
    );
  }
}

