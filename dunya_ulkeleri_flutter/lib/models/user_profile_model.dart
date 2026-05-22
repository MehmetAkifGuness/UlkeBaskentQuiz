import 'dart:typed_data';

class UserProfileModel {
  static const Object _noValue = Object();

  final String username;
  final String displayName;
  final String email;
  final String creationDate;
  final int maxWinStreak;
  final int totalGamesPlayed;
  final int totalMasteryPoints;
  final int trophies;
  final String league;
  final int trophySeason;
  final bool hasPlayedDaily;
  final int dailyStreak;

  final int avatarId;
  final bool hasCustomAvatar;
  final Uint8List? customAvatarBytes;

  UserProfileModel({
    required this.username,
    required this.displayName,
    required this.email,
    required this.creationDate,
    required this.maxWinStreak,
    required this.totalGamesPlayed,
    required this.totalMasteryPoints,
    required this.trophies,
    required this.league,
    required this.trophySeason,
    required this.hasPlayedDaily,
    required this.dailyStreak,
    required this.avatarId,
    required this.hasCustomAvatar,
    this.customAvatarBytes,
  });

  UserProfileModel copyWith({
    String? username,
    String? displayName,
    int? avatarId,
    bool? hasCustomAvatar,
    int? trophies,
    String? league,
    int? trophySeason,
    Object? customAvatarBytes = _noValue,
  }) {
    return UserProfileModel(
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      email: email,
      creationDate: creationDate,
      maxWinStreak: maxWinStreak,
      totalGamesPlayed: totalGamesPlayed,
      totalMasteryPoints: totalMasteryPoints,
      trophies: trophies ?? this.trophies,
      league: league ?? this.league,
      trophySeason: trophySeason ?? this.trophySeason,
      hasPlayedDaily: hasPlayedDaily,
      dailyStreak: dailyStreak,
      avatarId: avatarId ?? this.avatarId,
      hasCustomAvatar: hasCustomAvatar ?? this.hasCustomAvatar,
      customAvatarBytes: identical(customAvatarBytes, _noValue)
          ? this.customAvatarBytes
          : customAvatarBytes as Uint8List?,
    );
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      username: json['username'] ?? 'Bilinmiyor',
      displayName: json['displayName'] ?? (json['username'] ?? 'Bilinmiyor'),
      email: json['email'] ?? '',
      creationDate: json['creationDate'] ?? '',
      maxWinStreak: json['maxWinStreak'] ?? 0,
      totalGamesPlayed: json['totalGamesPlayed'] ?? 0,
      totalMasteryPoints: ((json['totalMasteryPoints'] ?? 0) as num).toInt(),
      trophies: ((json['trophies'] ?? 0) as num).toInt(),
      league: (json['league'] ?? '').toString(),
      trophySeason: ((json['trophySeason'] ?? 0) as num).toInt(),
      hasPlayedDaily: json['hasPlayedDaily'] ?? false,
      dailyStreak: json['dailyStreak'] ?? 0,
      avatarId: json['avatarId'] ?? 1,
      hasCustomAvatar: json['hasCustomAvatar'] ?? false,
    );
  }
}
