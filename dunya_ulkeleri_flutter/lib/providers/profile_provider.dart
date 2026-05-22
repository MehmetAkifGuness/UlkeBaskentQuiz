import 'package:flutter/foundation.dart';

import '../models/user_profile_model.dart';
import '../services/user.service.dart';

class ProfileProvider with ChangeNotifier {
  final UserService _userService = UserService();

  int _revision = 0;
  UserProfileModel? _profile;

  int get revision => _revision;
  UserProfileModel? get profile => _profile;

  int? get avatarId => _profile?.avatarId;
  bool get hasCustomAvatar => _profile?.hasCustomAvatar ?? false;
  Uint8List? get customAvatarBytes => _profile?.customAvatarBytes;

  Future<void> refresh(String token) async {
    try {
      final profile = await _userService.getUserProfile(token);
      if (profile == null) return;

      Uint8List? avatarBytes;
      if (profile.hasCustomAvatar) {
        try {
          avatarBytes = await _userService.getCustomAvatarBytes(
            token,
            profile.username,
          );
        } catch (_) {
          avatarBytes = _profile?.customAvatarBytes;
        }
      }

      setProfile(
        profile.copyWith(customAvatarBytes: profile.hasCustomAvatar ? avatarBytes : null),
      );
    } catch (_) {}
  }

  void setProfile(UserProfileModel profile) {
    _profile = profile;
    _revision++;
    notifyListeners();
  }

  void bump() {
    _revision++;
    notifyListeners();
  }

  void clear() {
    _profile = null;
    _revision++;
    notifyListeners();
  }
}
