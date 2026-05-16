import 'dart:convert';
import 'dart:typed_data';

class UserProfileModel {
  final String username;
  final String displayName;
  final String email;
  final String creationDate;
  final int maxWinStreak;
  final int totalGamesPlayed;
  final bool hasPlayedDaily;
  final int dailyStreak;

  // 🚨 YENİ EKLENEN
  final int avatarId;
  final Uint8List? customAvatarBytes;
  final String? customAvatarContentType;

  UserProfileModel({
    required this.username,
    required this.displayName,
    required this.email,
    required this.creationDate,
    required this.maxWinStreak,
    required this.totalGamesPlayed,
    required this.hasPlayedDaily,
    required this.dailyStreak,
    required this.avatarId, // 🚨 CONSTRUCTOR'A EKLENDİ
    this.customAvatarBytes,
    this.customAvatarContentType,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final customAvatarBase64 = json['customAvatarBase64'];
    Uint8List? customAvatarBytes;
    if (customAvatarBase64 is String && customAvatarBase64.isNotEmpty) {
      try {
        customAvatarBytes = base64Decode(customAvatarBase64);
      } catch (_) {
        customAvatarBytes = null;
      }
    }

    return UserProfileModel(
      username: json['username'] ?? 'Bilinmiyor',
      displayName: json['displayName'] ?? (json['username'] ?? 'Bilinmiyor'),
      email: json['email'] ?? '',
      creationDate: json['creationDate'] ?? '',
      maxWinStreak: json['maxWinStreak'] ?? 0,
      totalGamesPlayed: json['totalGamesPlayed'] ?? 0,
      hasPlayedDaily: json['hasPlayedDaily'] ?? false,
      dailyStreak: json['dailyStreak'] ?? 0,
      avatarId: json['avatarId'] ?? 1, // 🚨 EĞER BOŞ GELİRSE 1. AVATARI VER
      customAvatarBytes: customAvatarBytes,
      customAvatarContentType: json['customAvatarContentType'],
    );
  }
}
