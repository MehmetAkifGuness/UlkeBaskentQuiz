class UserProfileModel {
  final String username;
  final String email; // 🚨 YENİ EKLENDİ
  final String creationDate;
  final int maxWinStreak;
  final int totalGamesPlayed;

  UserProfileModel({
    required this.username,
    required this.email, // 🚨 YENİ EKLENDİ
    required this.creationDate,
    required this.maxWinStreak,
    required this.totalGamesPlayed,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      username: json['username'],
      email: json['email'] ?? '', // 🚨 YENİ EKLENDİ
      creationDate: json['creationDate'],
      maxWinStreak: json['maxWinStreak'] ?? 0,
      totalGamesPlayed: json['totalGamesPlayed'] ?? 0,
    );
  }
}
