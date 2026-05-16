// lib/screens/profile_screen.dart
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/user_profile_model.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../services/user.service.dart';
import '../theme/app_theme.dart';
import '../utils/page_trasitions.dart';
import '../widgets/app_avatar.dart';
import '../widgets/geo_background.dart';
import '../widgets/glass_card.dart';
import 'dictionary_screen.dart';
import 'login_screen.dart';
import 'mistake_screen.dart';
import 'setup_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const ProfileScreen({super.key, this.onNavigateTab});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  late Future<_ProfileData?> _profileFuture;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    _profileFuture = token == null
        ? Future.value(null)
        : _fetchProfileData(token);
  }

  Future<_ProfileData?> _fetchProfileData(String token) async {
    final profile = await _userService.getUserProfile(token);
    if (profile == null) return null;
    final scores = await _userService.getMyCategoryScores(token);
    return _ProfileData(profile: profile, scores: scores);
  }

  void _refresh() {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    setState(() => _profileFuture = _fetchProfileData(token));
  }

  Future<void> _showAvatarOptions(String token) async {
    Provider.of<SettingsProvider>(context, listen: false).triggerButtonVibration();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.32,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Profil Fotoğrafı',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
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
                const SizedBox(height: 6),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _pickAndUploadAvatar(token);
                  },
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeriden Seç'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showAvatarSelection(token);
                  },
                  icon: const Icon(Icons.grid_view_rounded),
                  label: const Text('Hazır Avatarlar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDark,
                    side: BorderSide(color: AppColors.borderLight.withOpacity(0.9)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadAvatar(String token) async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 768,
        maxHeight: 768,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final name = file.name;
      final contentType = _guessImageContentType(name);

      final ok = await _userService.uploadCustomAvatar(
        token,
        bytes,
        filename: name,
        contentType: contentType,
      );
      if (!ok) return;
      if (!mounted) return;
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profil fotoğrafı yüklenemedi: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  String _guessImageContentType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _editDisplayName(String token, String currentName) async {
    final controller = TextEditingController(text: currentName);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('İsim Güncelle'),
          content: TextField(
            controller: controller,
            maxLength: 40,
            decoration: const InputDecoration(
              hintText: 'Görünen isim',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );

    final newName = result == null ? null : result.trim();
    if (newName == null || newName.isEmpty || newName == currentName) return;

    try {
      final ok = await _userService.updateDisplayName(token, newName);
      if (!ok) return;
      if (!mounted) return;
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İsim güncellenemedi: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  void _goToTab(int index) {
    Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).triggerButtonVibration();
    widget.onNavigateTab?.call(index);
  }

  void _handleLogout() async {
    Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).triggerButtonVibration();
    await Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.of(context).pushAndRemoveUntil(
      FadePageRoute(page: const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _openDictionary() {
    Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).triggerButtonVibration();
    Navigator.push(context, FadePageRoute(page: const DictionaryScreen()));
  }

  void _openMistakes() {
    Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).triggerButtonVibration();
    Navigator.push(context, FadePageRoute(page: const MistakeScreen()));
  }

  void _showTierInfoSheet(_TierInfo currentTier) {
    Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).triggerButtonVibration();

    final tiers = _TierInfo.tiers;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final height = MediaQuery.of(context).size.height * 0.72;
        return SizedBox(
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
                    color: AppColors.borderLight.withOpacity(0.8),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Rütbe Sistemi',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
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
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: tiers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final tier = tiers[index];
                      final selected = tier.name == currentTier.name;
                      final border = selected
                          ? tier.color.withOpacity(0.55)
                          : AppColors.borderLight;
                      return GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        tint: AppColors.surface2,
                        borderRadius: BorderRadius.circular(18),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: border),
                                color: tier.color.withOpacity(0.14),
                              ),
                              child: Icon(tier.icon, color: tier.color),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tier.name,
                                    style: const TextStyle(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tier.rangeLabel,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (selected)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.successGreen,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAvatarSelection(String token) {
    Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).triggerButtonVibration();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final height = MediaQuery.of(context).size.height * 0.72;
        return SizedBox(
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
                    color: AppColors.borderLight.withOpacity(0.8),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Profil Fotoğrafı Seç',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
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
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: 15,
                    itemBuilder: (context, index) {
                      final currentId = index + 1;
                      return GestureDetector(
                        onTap: () async {
                          Provider.of<SettingsProvider>(
                            context,
                            listen: false,
                          ).triggerButtonVibration();
                          Navigator.of(context).pop();

                          final success = await _userService.updateAvatar(
                            token,
                            currentId,
                          );
                          if (!success) return;
                          if (!mounted) return;
                          _refresh();
                        },
                        child: Center(
                          child: AppAvatar(avatarId: currentId, size: 56),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GeoBackground(
        child: FutureBuilder<_ProfileData?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryBlue),
              );
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(
                child: Text(
                  'Profil bilgileri alınamadı.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              );
            }

            final data = snapshot.data!;
            final profile = data.profile;
            final scores = data.scores;

            final totalScore = scores.values.fold<int>(
              0,
              (sum, item) => sum + item,
            );
            final tier = _TierInfo.fromScore(totalScore);

            final createdAt = DateTime.tryParse(profile.creationDate);
            final creationDateText = createdAt == null
                ? '-'
                : '${createdAt.day.toString().padLeft(2, '0')}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.year}';

            final progress = _progressToNextTier(totalScore);
            final analysisText = _generateAnalysisText(scores);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              physics: const BouncingScrollPhysics(),
              children: [
                _TopRow(
                  onBack: () {
                    if (widget.onNavigateTab != null) {
                      _goToTab(0);
                      return;
                    }
                    Navigator.of(context).maybePop();
                  },
                  onSettings: () {
                    Provider.of<SettingsProvider>(
                      context,
                      listen: false,
                    ).triggerButtonVibration();
                    Navigator.push(
                      context,
                      FadePageRoute(page: const SetupScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      final token = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      ).token;
                      if (token == null) return;
                      _showAvatarOptions(token);
                    },
                    child: _AvatarRing(
                      avatarId: profile.avatarId,
                      avatarBytes: profile.customAvatarBytes,
                      ringColor: tier.color,
                      progress: progress,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profile.displayName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: () {
                          final token = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          ).token;
                          if (token == null) return;
                          _editDisplayName(token, profile.displayName);
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
                Text(
                  '@${profile.username}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                _TierPill(
                  title: '${tier.name.toUpperCase()} SEVİYESİ',
                  color: tier.color,
                  icon: tier.icon,
                  onInfo: () => _showTierInfoSheet(tier),
                ),
                const SizedBox(height: 14),
                _AnalysisCard(
                  text: analysisText,
                  onDictionary: _openDictionary,
                  onMistakes: _openMistakes,
                ),
                const SizedBox(height: 18),
                _SectionHeader(
                  title: 'Ustalık Seviyeleri',
                  trailing: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.bar_chart),
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                _MasteryGrid(items: _buildMasteryCards(scores)),
                const SizedBox(height: 18),
                const _SectionHeader(title: 'Genel İstatistikler'),
                const SizedBox(height: 10),
                _StatsGrid(
                  items: [
                    _StatItem(
                      title: 'Kayıt Tarihi',
                      value: creationDateText,
                      icon: Icons.calendar_month,
                      iconColor: AppColors.successGreen,
                    ),
                    _StatItem(
                      title: 'En Yüksek Skor',
                      value: _formatNumber(profile.maxWinStreak),
                      icon: Icons.emoji_events,
                      iconColor: AppColors.brown,
                    ),
                    _StatItem(
                      title: 'Oynanan Oyun',
                      value: _formatNumber(profile.totalGamesPlayed),
                      icon: Icons.extension_rounded,
                      iconColor: AppColors.errorRed,
                    ),
                    _StatItem(
                      title: 'Toplam Ustalık',
                      value: _formatCompact(totalScore),
                      icon: Icons.military_tech,
                      iconColor: AppColors.successGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _handleLogout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorRed,
                    side: BorderSide(
                      color: AppColors.errorRed.withOpacity(0.6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'Çıkış Yap',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildMasteryCards(Map<String, int> scores) {
    const specialModes = [
      _SpecialModeInfo(
        title: 'Günün Görevi',
        scoreKey: 'DailyChallenge_MIXED',
        maxScore: 20000,
      ),
      _SpecialModeInfo(
        title: 'Sonsuz Mod',
        scoreKey: 'Dünya_ENDLESS',
        maxScore: 40000,
      ),
    ];

    const continents = [
      _ContinentInfo('Avrupa', 44),
      _ContinentInfo('Asya', 48),
      _ContinentInfo('Afrika', 54),
      _ContinentInfo('Kuzey Amerika', 23),
      _ContinentInfo('Güney Amerika', 12),
      _ContinentInfo('Okyanusya', 14),
    ];

    return [
      for (final item in specialModes)
        _MasteryCard.fromSingleScore(
          title: item.title,
          scoreKey: item.scoreKey,
          maxScore: item.maxScore,
          scores: scores,
        ),
      for (final continent in continents)
        _MasteryCard.fromScores(continent: continent, scores: scores),
    ];
  }

  String _generateAnalysisText(Map<String, int> scores) {
    const categories = [
      _ContinentInfo('Avrupa', 44),
      _ContinentInfo('Asya', 48),
      _ContinentInfo('Afrika', 54),
      _ContinentInfo('Kuzey Amerika', 23),
      _ContinentInfo('Güney Amerika', 12),
      _ContinentInfo('Okyanusya', 14),
    ];

    final unplayed = <String>[];
    final weak = <String>[];

    for (final item in categories) {
      final c2c = scores['${item.name}_COUNTRY_TO_CAPITAL'] ?? 0;
      final c2cRev = scores['${item.name}_CAPITAL_TO_COUNTRY'] ?? 0;
      final mixed = scores['${item.name}_MIXED'] ?? 0;

      final maxScoreMode = math.max(c2c, math.max(c2cRev, mixed));
      final maxPossible = item.questions * 2000;
      final percentage = maxPossible > 0 ? (maxScoreMode / maxPossible) : 0;

      if (maxScoreMode == 0) {
        unplayed.add(item.name);
      } else if (percentage < 0.4) {
        weak.add(item.name);
      }
    }

    if (unplayed.length == categories.length) {
      return 'Henüz hiçbir kıtada oynamamışsın! Hemen bir oyuna girerek dünyayı keşfetmeye başla.';
    }

    final buffer = StringBuffer();
    if (weak.isNotEmpty) {
      buffer.writeln(
        'İstatistiklerine göre ${weak.join(', ')} bölgelerinde zorlandığın görünüyor. '
        'Farklı oyun modlarında pratik yaparak doğruluğunu artırabilirsin.',
      );
      buffer.writeln();
    }
    if (unplayed.isNotEmpty) {
      buffer.write(
        'Ayrıca ${unplayed.join(', ')} bölgelerinde henüz hiç oynamamışsın. '
        'Şansını oralarda da denemeni öneririm.',
      );
    }

    return buffer.toString().trim();
  }

  double _progressToNextTier(int totalScore) {
    final tiers = _TierInfo.tiers;
    for (var i = 0; i < tiers.length; i++) {
      final current = tiers[i];
      final next = i + 1 < tiers.length ? tiers[i + 1] : null;
      if (next == null) return 1.0;
      if (totalScore < next.minScore) {
        final span = (next.minScore - current.minScore)
            .clamp(1, 1 << 30)
            .toDouble();
        return ((totalScore - current.minScore) / span).clamp(0.0, 1.0);
      }
    }
    return 1.0;
  }

  static String _formatNumber(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buffer.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buffer.write('.');
    }
    return buffer.toString();
  }

  static String _formatCompact(int value) {
    if (value >= 1_000_000) {
      final v = value / 1_000_000;
      return '${v.toStringAsFixed(v < 10 ? 1 : 0)}M';
    }
    if (value >= 1_000) {
      final v = value / 1_000;
      return '${v.toStringAsFixed(v < 10 ? 1 : 0)}K';
    }
    return value.toString();
  }
}

class _ProfileData {
  final UserProfileModel profile;
  final Map<String, int> scores;

  const _ProfileData({required this.profile, required this.scores});
}

class _TopRow extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSettings;

  const _TopRow({this.onBack, this.onSettings});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          _IconGlassButton(icon: Icons.arrow_back, onTap: onBack),
          const Spacer(),
          _IconGlassButton(icon: Icons.settings, onTap: onSettings),
        ],
      ),
    );
  }
}

class _IconGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _IconGlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      tint: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: Icon(icon, color: AppColors.textDark),
    );
  }
}

class _AvatarRing extends StatelessWidget {
  final int avatarId;
  final Uint8List? avatarBytes;
  final Color ringColor;
  final double progress;

  const _AvatarRing({
    required this.avatarId,
    this.avatarBytes,
    required this.ringColor,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final ringSize = 132.0;
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: ringSize,
          height: ringSize,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            backgroundColor: AppColors.borderLight.withOpacity(0.6),
            valueColor: AlwaysStoppedAnimation(ringColor),
          ),
        ),
        AppAvatar(avatarId: avatarId, size: 112, imageBytes: avatarBytes),
        Positioned(
          right: 10,
          bottom: 10,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Icon(
              Icons.edit,
              size: 18,
              color: AppColors.successGreen,
            ),
          ),
        ),
      ],
    );
  }
}

class _TierPill extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final VoidCallback onInfo;

  const _TierPill({
    required this.title,
    required this.color,
    required this.icon,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      tint: AppColors.surface,
      borderRadius: BorderRadius.circular(999),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onInfo,
            borderRadius: BorderRadius.circular(99),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.help_outline, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final String text;
  final VoidCallback onDictionary;
  final VoidCallback onMistakes;

  const _AnalysisCard({
    required this.text,
    required this.onDictionary,
    required this.onMistakes,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      tint: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 190,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFBBF24), Color(0xFF38BDF8)],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      _AnalysisIcon(),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Stratejik Analiz',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    text,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onDictionary,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textDark,
                            side: const BorderSide(
                              color: AppColors.borderLight,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Sözlüğe Git',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onMistakes,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.successGreen,
                            side: BorderSide(
                              color: AppColors.successGreen.withOpacity(0.45),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Hata Defterimi\nİncele',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisIcon extends StatelessWidget {
  const _AnalysisIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.brown.withOpacity(0.18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: const Icon(Icons.show_chart, color: Color(0xFFFBBF24)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _ContinentInfo {
  final String name;
  final int questions;

  const _ContinentInfo(this.name, this.questions);
}

class _SpecialModeInfo {
  final String title;
  final String scoreKey;
  final int maxScore;

  const _SpecialModeInfo({
    required this.title,
    required this.scoreKey,
    required this.maxScore,
  });
}

class _MasteryGrid extends StatelessWidget {
  final List<Widget> items;

  const _MasteryGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }
}

class _MasteryCard extends StatelessWidget {
  final String title;
  final int score;
  final double percentage;
  final String label;
  final Color labelColor;

  const _MasteryCard({
    required this.title,
    required this.score,
    required this.percentage,
    required this.label,
    required this.labelColor,
  });

  factory _MasteryCard.fromScores({
    required _ContinentInfo continent,
    required Map<String, int> scores,
  }) {
    final c2c = scores['${continent.name}_COUNTRY_TO_CAPITAL'] ?? 0;
    final c2cRev = scores['${continent.name}_CAPITAL_TO_COUNTRY'] ?? 0;
    final mixed = scores['${continent.name}_MIXED'] ?? 0;

    final best = math.max(c2c, math.max(c2cRev, mixed));
    final maxScore = continent.questions * 2000;
    final percentage = maxScore <= 0 ? 0.0 : (best / maxScore).clamp(0.0, 1.0);

    final mastery = _MasteryLabel.fromPercentage(percentage);
    final label = best == 0 ? 'Oynanmadı' : mastery.text;
    final labelColor = best == 0 ? AppColors.textMuted : mastery.color;

    return _MasteryCard(
      title: continent.name,
      score: best,
      percentage: percentage,
      label: label,
      labelColor: labelColor,
    );
  }

  factory _MasteryCard.fromSingleScore({
    required String title,
    required String scoreKey,
    required int maxScore,
    required Map<String, int> scores,
  }) {
    final score = scores[scoreKey] ?? 0;
    final percentage = maxScore <= 0 ? 0.0 : (score / maxScore).clamp(0.0, 1.0);

    final mastery = _MasteryLabel.fromPercentage(percentage);
    final label = score == 0 ? 'Oynanmadı' : mastery.text;
    final labelColor = score == 0 ? AppColors.textMuted : mastery.color;

    return _MasteryCard(
      title: title,
      score: score,
      percentage: percentage,
      label: label,
      labelColor: labelColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      tint: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_ProfileScreenState._formatNumber(score)} Puan',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: labelColor.withOpacity(0.14),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const Spacer(),
          _MasteryRing(
            percentage: percentage,
            color: labelColor,
          ),
        ],
      ),
    );
  }
}

class _MasteryRing extends StatelessWidget {
  final double percentage;
  final Color color;

  const _MasteryRing({required this.percentage, required this.color});

  @override
  Widget build(BuildContext context) {
    final percentText = '${(percentage * 100).round()}%';

    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: CircularProgressIndicator(
              value: percentage,
              strokeWidth: 9,
              backgroundColor: AppColors.borderLight.withOpacity(0.22),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Text(
            percentText,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _MasteryLabel {
  final String text;
  final Color color;

  const _MasteryLabel(this.text, this.color);

  static _MasteryLabel fromPercentage(double percentage) {
    if (percentage == 0) {
      return const _MasteryLabel('Oynanmadı', AppColors.textMuted);
    }
    if (percentage >= 0.8) {
      return const _MasteryLabel('Çok İyi', AppColors.successGreen);
    }
    if (percentage >= 0.6) {
      return const _MasteryLabel('İyi', AppColors.successGreen);
    }
    if (percentage >= 0.4) {
      return const _MasteryLabel('Ortalama', AppColors.brown);
    }
    if (percentage >= 0.2) {
      return const _MasteryLabel('Geliştir', AppColors.yellow);
    }
    return const _MasteryLabel('Kötü', AppColors.errorRed);
  }
}

class _StatsGrid extends StatelessWidget {
  final List<_StatItem> items;

  const _StatsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _StatCard(item: items[index]),
    );
  }
}

class _StatItem {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItem item;

  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      tint: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            item.title.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          Icon(item.icon, color: item.iconColor, size: 26),
          const Spacer(),
          Text(
            item.value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _TierInfo {
  final String name;
  final int minScore;
  final String rangeLabel;
  final Color color;
  final IconData icon;

  const _TierInfo({
    required this.name,
    required this.minScore,
    required this.rangeLabel,
    required this.color,
    required this.icon,
  });

  static const tiers = <_TierInfo>[
    _TierInfo(
      name: 'Turist',
      minScore: 0,
      rangeLabel: '0 - 99.999',
      color: Colors.green,
      icon: Icons.flight_takeoff,
    ),
    _TierInfo(
      name: 'Gezgin',
      minScore: 100000,
      rangeLabel: '100.000 - 249.999',
      color: Colors.blue,
      icon: Icons.explore,
    ),
    _TierInfo(
      name: 'Yol Kaşifi',
      minScore: 250000,
      rangeLabel: '250.000 - 499.999',
      color: Colors.yellow,
      icon: Icons.explore,
    ),
    _TierInfo(
      name: 'Dünya Yolcusu',
      minScore: 500000,
      rangeLabel: '500.000 - 999.999',
      color: Colors.brown,
      icon: Icons.public,
    ),
    _TierInfo(
      name: 'Kıta Fatihi',
      minScore: 1000000,
      rangeLabel: '1.000.000 - 4.999.999',
      color: Colors.cyanAccent,
      icon: Icons.emoji_events,
    ),
    _TierInfo(
      name: 'Harita Ustası',
      minScore: 5000000,
      rangeLabel: '5.000.000 - 9.999.999',
      color: Colors.teal,
      icon: Icons.map,
    ),
    _TierInfo(
      name: 'Küresel Zihin',
      minScore: 10000000,
      rangeLabel: '10.000.000 - 19.999.999',
      color: Color.fromARGB(255, 1, 90, 90),
      icon: Icons.psychology,
    ),
    _TierInfo(
      name: 'Evrensel Bilge',
      minScore: 20000000,
      rangeLabel: '20.000.000+',
      color: Colors.amber,
      icon: Icons.school,
    ),
  ];

  static _TierInfo fromScore(int totalScore) {
    var selected = tiers.first;
    for (final tier in tiers) {
      if (totalScore >= tier.minScore) selected = tier;
    }
    return selected;
  }
}
