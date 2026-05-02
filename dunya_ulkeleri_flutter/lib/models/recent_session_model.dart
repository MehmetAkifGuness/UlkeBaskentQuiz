class RecentSessionModel {
  final int id;
  final String category;
  final String gameMode;
  final int currentScore;
  final int remainingLives;
  final bool finished;
  final DateTime? createdAt;
  final DateTime? updateAt;

  const RecentSessionModel({
    required this.id,
    required this.category,
    required this.gameMode,
    required this.currentScore,
    required this.remainingLives,
    required this.finished,
    required this.createdAt,
    required this.updateAt,
  });

  factory RecentSessionModel.fromJson(Map<String, dynamic> json) {
    return RecentSessionModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      category: (json['category'] as String?) ?? 'Dünya',
      gameMode: (json['gameMode'] as String?) ?? 'MIXED',
      currentScore: (json['currentScore'] as num?)?.toInt() ?? 0,
      remainingLives: (json['remainingLives'] as num?)?.toInt() ?? 0,
      finished: json['finished'] == true,
      createdAt: _parseDate(json['createdAt']),
      updateAt: _parseDate(json['updateAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    if (value is Map<String, dynamic>) {
      final year = (value['year'] as num?)?.toInt();
      final month = (value['monthValue'] as num?)?.toInt();
      final day = (value['dayOfMonth'] as num?)?.toInt();
      final hour = (value['hour'] as num?)?.toInt() ?? 0;
      final minute = (value['minute'] as num?)?.toInt() ?? 0;
      final second = (value['second'] as num?)?.toInt() ?? 0;
      if (year == null || month == null || day == null) return null;
      return DateTime(year, month, day, hour, minute, second);
    }
    return null;
  }
}
