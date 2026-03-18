class GameStatusModel {
  final int? sessionId;
  final int currentScore;
  final int remainingLives;
  final String? countryName;
  final List<String>? options;
  final String? message;
  final bool? lastAnswerCorrect;
  final String? lastCorrectAnswer;
  final String? ghostName;
  final double? ghostSpeed;

  // 1. YENİ EKLENDİ: Oyunun bitip bitmediğini tutan değişken
  final bool? finished;

  GameStatusModel({
    this.sessionId,
    this.ghostName,
    this.ghostSpeed,
    required this.currentScore,
    required this.remainingLives,
    this.countryName,
    this.options,
    this.message,
    this.lastAnswerCorrect,
    this.lastCorrectAnswer,

    // 2. YENİ EKLENDİ: Constructor'a ekledik
    this.finished,
  });

  factory GameStatusModel.fromJson(Map<String, dynamic> json) {
    return GameStatusModel(
      sessionId: json['sessionId'],
      currentScore: json['currentScore'] ?? 0,
      remainingLives: json['remainingLives'] ?? 0,
      countryName: json['countryName'],
      ghostName: json['ghostName'],
      ghostSpeed: json['ghostSpeed'] != null
          ? (json['ghostSpeed'] as num).toDouble()
          : 8.0,
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : null,
      message: json['message'],
      lastAnswerCorrect: json['lastAnswerCorrect'],
      lastCorrectAnswer: json['lastCorrectAnswer'],

      // 3. YENİ EKLENDİ: JSON'dan gelen değeri okuyoruz
      finished: json['finished'],
    );
  }
}
