class UserProfileModel {
  final String username;
  final String email;
  final String creationDate;
  final int maxWinStreak;
  final int totalGamesPlayed;

  // 🚨 YENİ EKLENEN DEĞİŞKEN (Bugün görevi yaptı mı?)
  final bool hasPlayedDaily;

  UserProfileModel({
    required this.username,
    required this.email,
    required this.creationDate,
    required this.maxWinStreak,
    required this.totalGamesPlayed,
    required this.hasPlayedDaily, // 🚨 CONSTRUCTOR'A EKLENDİ
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      username: json['username'] ?? 'Bilinmiyor',
      email: json['email'] ?? '',
      creationDate: json['creationDate'] ?? '',
      maxWinStreak: json['maxWinStreak'] ?? 0,
      totalGamesPlayed: json['totalGamesPlayed'] ?? 0,

      // 🚨 JSON'DAN OKUNAN DEĞER (Eğer backendden null gelirse varsayılan olarak false yap)
      hasPlayedDaily: json['hasPlayedDaily'] ?? false,
    );
  }
}
