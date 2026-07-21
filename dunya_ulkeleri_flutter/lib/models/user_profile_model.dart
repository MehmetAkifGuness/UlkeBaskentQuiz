import 'dart:typed_data';

class UserProfileModel {
  static const Object _noValue = Object();

  final String username;
  final String email;
  final String creationDate;
  final int maxWinStreak;
  final int totalGamesPlayed;
  final int totalMasteryPoints;
  final int trophies;
  final String league;
  final int leagueMinTrophies;
  final String nextLeague;
  final int nextLeagueMinTrophies;
  final int trophiesToNextLeague;
  final int trophySeason;
  final int seasonDaysRemaining;
  final bool hasPlayedDaily;
  final int dailyStreak;

  final int avatarId;
  final bool hasCustomAvatar;
  final Uint8List? customAvatarBytes;

  UserProfileModel({
    required this.username,
    required this.email,
    required this.creationDate,
    required this.maxWinStreak,
    required this.totalGamesPlayed,
    required this.totalMasteryPoints,
    required this.trophies,
    required this.league,
    required this.leagueMinTrophies,
    required this.nextLeague,
    required this.nextLeagueMinTrophies,
    required this.trophiesToNextLeague,
    required this.trophySeason,
    required this.seasonDaysRemaining,
    required this.hasPlayedDaily,
    required this.dailyStreak,
    required this.avatarId,
    required this.hasCustomAvatar,
    this.customAvatarBytes,
  });

  UserProfileModel copyWith({
    String? username,
    int? avatarId,
    bool? hasCustomAvatar,
    int? trophies,
    String? league,
    int? leagueMinTrophies,
    String? nextLeague,
    int? nextLeagueMinTrophies,
    int? trophiesToNextLeague,
    int? trophySeason,
    int? seasonDaysRemaining,
    Object? customAvatarBytes = _noValue,
  }) {
    return UserProfileModel(
      username: username ?? this.username,
      email: email,
      creationDate: creationDate,
      maxWinStreak: maxWinStreak,
      totalGamesPlayed: totalGamesPlayed,
      totalMasteryPoints: totalMasteryPoints,
      trophies: trophies ?? this.trophies,
      league: league ?? this.league,
      leagueMinTrophies: leagueMinTrophies ?? this.leagueMinTrophies,
      nextLeague: nextLeague ?? this.nextLeague,
      nextLeagueMinTrophies: nextLeagueMinTrophies ?? this.nextLeagueMinTrophies,
      trophiesToNextLeague: trophiesToNextLeague ?? this.trophiesToNextLeague,
      trophySeason: trophySeason ?? this.trophySeason,
      seasonDaysRemaining: seasonDaysRemaining ?? this.seasonDaysRemaining,
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
      email: json['email'] ?? '',
      creationDate: json['creationDate'] ?? '',
      maxWinStreak: json['maxWinStreak'] ?? 0,
      totalGamesPlayed: json['totalGamesPlayed'] ?? 0,
      totalMasteryPoints: ((json['totalMasteryPoints'] ?? 0) as num).toInt(),
      trophies: ((json['trophies'] ?? 0) as num).toInt(),
      league: (json['league'] ?? '').toString(),
      leagueMinTrophies: ((json['leagueMinTrophies'] ?? 0) as num).toInt(),
      nextLeague: (json['nextLeague'] ?? '').toString(),
      nextLeagueMinTrophies:
          ((json['nextLeagueMinTrophies'] ?? 0) as num).toInt(),
      trophiesToNextLeague:
          ((json['trophiesToNextLeague'] ?? 0) as num).toInt(),
      trophySeason: ((json['trophySeason'] ?? 0) as num).toInt(),
      seasonDaysRemaining: ((json['seasonDaysRemaining'] ?? 0) as num).toInt(),
      hasPlayedDaily: json['hasPlayedDaily'] ?? false,
      dailyStreak: json['dailyStreak'] ?? 0,
      avatarId: json['avatarId'] ?? 1,
      hasCustomAvatar: json['hasCustomAvatar'] ?? false,
    );
  }
}
