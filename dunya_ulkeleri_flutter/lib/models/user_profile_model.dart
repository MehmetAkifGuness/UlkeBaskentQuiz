class UserProfileModel {
  final String username;
  final String email;
  final String creationDate;
  final int maxWinStreak;
  final int totalGamesPlayed;
  final bool hasPlayedDaily;

  // 🚨 YENİ EKLENEN
  final int avatarId;

  UserProfileModel({
    required this.username,
    required this.email,
    required this.creationDate,
    required this.maxWinStreak,
    required this.totalGamesPlayed,
    required this.hasPlayedDaily,
    required this.avatarId, // 🚨 CONSTRUCTOR'A EKLENDİ
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      username: json['username'] ?? 'Bilinmiyor',
      email: json['email'] ?? '',
      creationDate: json['creationDate'] ?? '',
      maxWinStreak: json['maxWinStreak'] ?? 0,
      totalGamesPlayed: json['totalGamesPlayed'] ?? 0,
      hasPlayedDaily: json['hasPlayedDaily'] ?? false,
      avatarId: json['avatarId'] ?? 1, // 🚨 EĞER BOŞ GELİRSE 1. AVATARI VER
    );
  }
}
