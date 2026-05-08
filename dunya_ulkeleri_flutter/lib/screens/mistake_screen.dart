import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../services/user.service.dart';
import '../theme/app_theme.dart';
import '../widgets/geo_background.dart';
import '../widgets/glass_card.dart';

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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mistakes = [];
        _isLoading = false;
        _errorMessage = 'Hata defteri yüklenemedi. Lütfen tekrar dene.';
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

    final success = await _userService.removeMistake(token, questionId);
    if (!success || !mounted) return;
    setState(() {
      _mistakes.removeWhere((item) {
        if (item is! Map) return false;
        return item['id'] == questionId;
      });
      _solvedCount += 1;
    });
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

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color accent;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      tint: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _MistakeTile extends StatelessWidget {
  final dynamic raw;
  final ValueChanged<int> onDone;

  const _MistakeTile({required this.raw, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final map = raw is Map ? raw : const <String, dynamic>{};
    final countryName = map['countryName']?.toString() ?? 'Bilinmiyor';
    final capitalName = map['capitalName']?.toString() ?? 'Bilinmiyor';
    final continent = map['continent']?.toString() ?? 'Bilinmiyor';
    final idRaw = map['id'];
    final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        tint: AppColors.surface,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.errorRed.withOpacity(0.12),
                border: Border.all(
                  color: AppColors.errorRed.withOpacity(0.35),
                ),
              ),
              child: const Icon(
                Icons.priority_high,
                color: AppColors.errorRed,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    countryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Başkent: $capitalName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Kıta: $continent',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GlassCard(
              onTap: id == null ? null : () => onDone(id),
              padding: const EdgeInsets.all(10),
              tint: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              child: const Icon(
                Icons.check,
                color: AppColors.successGreen,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final Widget? trailing;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        tint: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withOpacity(0.12),
                border: Border.all(color: iconColor.withOpacity(0.25)),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerLeft, child: trailing!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final double progress;
  final int remainingPercent;

  const _ProgressCard({required this.progress, required this.remainingPercent});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tint: AppColors.surface,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.28,
                child: CustomPaint(
                  painter: _DotsPainter(
                    color: AppColors.primaryBlue.withOpacity(0.25),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Çalışmaya devam et!',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hedefine %$remainingPercent kaldı',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 14),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.easeOutCubic,
                  tween:
                      Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
                  builder: (context, value, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 12,
                        backgroundColor: AppColors.borderLight.withOpacity(0.8),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.primaryBlue,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  final Color color;

  const _DotsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 18.0;
    const radius = 1.7;

    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter oldDelegate) =>
      oldDelegate.color != color;
}
