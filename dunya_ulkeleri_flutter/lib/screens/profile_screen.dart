// lib/screens/profile_screen.dart
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/user_profile_model.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/settings_provider.dart';
import '../services/user.service.dart';
import '../theme/app_theme.dart';
import '../utils/error_message_utils.dart';
import '../utils/page_trasitions.dart';
import '../widgets/app_avatar.dart';
import '../widgets/geo_background.dart';
import '../widgets/glass_card.dart';
import 'dictionary_screen.dart';
import 'login_screen.dart';
import 'mistake_screen.dart';
import 'setup_screen.dart';

part 'profile_screen/logic.dart';
part 'profile_screen/bottom_sheets.dart';
part 'profile_screen/content.dart';
part 'profile_screen/analysis_widgets.dart';
part 'profile_screen/mastery.dart';
part 'profile_screen/stats_and_tier.dart';

class ProfileScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final bool isActive;

  const ProfileScreen({
    super.key,
    this.onNavigateTab,
    this.isActive = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  late Future<_ProfileData?> _profileFuture;
  _ProfileData? _cachedProfileData;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    _profileFuture = token == null
        ? Future.value(null)
        : _fetchProfileData(token);
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _refresh();
    }
  }

  Future<_ProfileData?> _fetchProfileData(String token) {
    return _fetchProfileDataImpl(_userService, token);
  }

  void _refresh() {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    setState(() {
      _profileFuture = _fetchProfileData(token);
    });
  }

  void _updateLocalProfile(UserProfileModel Function(UserProfileModel current) updater) {
    final current = _cachedProfileData;
    if (current == null) {
      _refresh();
      return;
    }

    final updatedProfile = updater(current.profile);
    final updatedData = _ProfileData(profile: updatedProfile, scores: current.scores);

    setState(() {
      _cachedProfileData = updatedData;
      _profileFuture = Future.value(updatedData);
    });

    Provider.of<ProfileProvider>(context, listen: false).setProfile(updatedProfile);
  }

  Future<void> _showAvatarOptions(String token) async {
    Provider.of<SettingsProvider>(context, listen: false).triggerButtonVibration();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _AvatarOptionsSheet(
          onPickFromGallery: () {
            _pickAndUploadAvatar(token);
          },
          onReadyAvatars: () {
            _showAvatarSelection(token);
          },
        );
      },
    );
  }

  Future<void> _pickAndUploadAvatar(String token) {
    return _pickAndUploadAvatarImpl(this, token);
  }

  String _guessImageContentType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _editDisplayName(
    String token,
    String currentName,
    String currentUsername,
  ) {
    return _editDisplayNameImpl(this, token, currentName, currentUsername);
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
    if (!mounted) return;
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

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TierInfoSheet(currentTier: currentTier),
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
      builder: (_) {
        return _AvatarSelectionSheet(
          onAvatarSelected: (currentId) async {
            try {
              final success = await _userService.updateAvatar(token, currentId);
              if (!success) return;
              if (!mounted) return;
              _updateLocalProfile(
                (current) => current.copyWith(
                  avatarId: currentId,
                  hasCustomAvatar: false,
                  customAvatarBytes: null,
                ),
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMessageFrom(e)),
                  backgroundColor: AppColors.errorRed,
                ),
              );
            }
          },
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
            _cachedProfileData = data;
            final profile = data.profile;
            final scores = data.scores;

            final totalScore = profile.totalMasteryPoints;
            final tier = _TierInfo.fromScore(totalScore);

            final createdAt = DateTime.tryParse(profile.creationDate);
            final creationDateText = createdAt == null
                ? '-'
                : '${createdAt.day.toString().padLeft(2, '0')}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.year}';

            final progress = _progressToNextTier(totalScore);
            final analysisText = _generateAnalysisText(scores);

            return _ProfileContentList(
              profile: profile,
              scores: scores,
              totalScore: totalScore,
              tier: tier,
              progress: progress,
              analysisText: analysisText,
              creationDateText: creationDateText,
              onBack: () {
                if (widget.onNavigateTab != null) {
                  _goToTab(0);
                  return;
                }
                Navigator.of(context).maybePop();
              },
              onSettings: () {
                Provider.of<SettingsProvider>(context, listen: false)
                    .triggerButtonVibration();
                Navigator.push(
                  context,
                  FadePageRoute(page: const SetupScreen()),
                );
              },
              onAvatarTap: () {
                final token = Provider.of<AuthProvider>(context, listen: false).token;
                if (token == null) return;
                _showAvatarOptions(token);
              },
              onEditDisplayName: () {
                final token = Provider.of<AuthProvider>(context, listen: false).token;
                if (token == null) return;
                _editDisplayName(token, profile.displayName, profile.username);
              },
              onShowTierInfo: () => _showTierInfoSheet(tier),
              onDictionary: _openDictionary,
              onMistakes: _openMistakes,
              onLogout: _handleLogout,
            );
          },
        ),
      ),
    );
  }

}
