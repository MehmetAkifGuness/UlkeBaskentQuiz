import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../services/user.service.dart';
import '../theme/app_theme.dart';
import '../utils/error_message_utils.dart';
import '../widgets/geo_background.dart';
import '../widgets/glass_card.dart';

part 'mistake_screen/widgets.dart';
part 'mistake_screen/progress_widgets.dart';

class MistakeScreen extends StatefulWidget {
  const MistakeScreen({super.key});

  @override
  State<MistakeScreen> createState() => _MistakeScreenState();
}

class _MistakeScreenState extends State<MistakeScreen> {
  final UserService _userService = UserService();

  List<dynamic> _mistakes = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _solvedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMistakes();
  }

  Future<void> _loadMistakes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null || token.trim().isEmpty) {
      setState(() {
        _mistakes = [];
        _isLoading = false;
        _errorMessage = 'Hata defterini görmek için giriş yapmalısın.';
      });
      return;
    }

    try {
      final data = await _userService.getMistakes(token);
      if (!mounted) return;
      setState(() {
        _mistakes = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mistakes = [];
        _isLoading = false;
        _errorMessage = errorMessageFrom(e);
      });
    }
  }

  Future<void> _removeMistake(int questionId) async {
    Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).triggerButtonVibration();

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null || token.trim().isEmpty) return;

    try {
      final success = await _userService.removeMistake(token, questionId);
      if (!success || !mounted) return;
      setState(() {
        _mistakes.removeWhere((item) {
          if (item is! Map) return false;
          return item['id'] == questionId;
        });
        _solvedCount += 1;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessageFrom(e)),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _mistakes.length;
    final totalForProgress = pendingCount + _solvedCount;
    final progress =
        totalForProgress == 0 ? 1.0 : _solvedCount / totalForProgress;
    final remainingPercent = ((1 - progress) * 100).round().clamp(0, 100);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GeoBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                children: [
                  GlassCard(
                    onTap: () => Navigator.of(context).maybePop(),
                    padding: const EdgeInsets.all(10),
                    tint: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    child: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Hata Defterim',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  GlassCard(
                    padding: const EdgeInsets.all(10),
                    tint: AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    child: const Icon(
                      Icons.public,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryBlue,
                backgroundColor: AppColors.surface2,
                onRefresh: _loadMistakes,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            title: 'TOPLAM HATA',
                            value: pendingCount.toString().padLeft(2, '0'),
                            accent: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            title: 'ÇÖZÜLENLER',
                            value: _solvedCount.toString().padLeft(2, '0'),
                            accent: AppColors.successGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'İnceleme Bekleyenler',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 18, bottom: 10),
                          child: CircularProgressIndicator(
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    if (!_isLoading && _errorMessage != null)
                      _InfoCard(
                        icon: Icons.wifi_off,
                        iconColor: AppColors.errorRed,
                        title: 'Bağlantı sorunu',
                        message: _errorMessage!,
                        trailing: TextButton(
                          onPressed: _loadMistakes,
                          child: const Text('Tekrar Dene'),
                        ),
                      ),
                    if (!_isLoading &&
                        _errorMessage == null &&
                        _mistakes.isEmpty)
                      const _InfoCard(
                        icon: Icons.emoji_events,
                        iconColor: AppColors.yellow,
                        title: 'Harika gidiyorsun!',
                        message:
                            'Hata defterinde inceleme bekleyen soru yok.',
                      ),
                    if (!_isLoading && _mistakes.isNotEmpty) ...[
                      for (final raw in _mistakes)
                        _MistakeTile(raw: raw, onDone: _removeMistake),
                    ],
                    const SizedBox(height: 16),
                    _ProgressCard(
                      progress: progress,
                      remainingPercent: remainingPercent,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
