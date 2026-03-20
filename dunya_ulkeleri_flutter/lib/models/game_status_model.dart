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

  final int? ghostScore;
  final int? totalQuestions;
  final int? remainingQuestions;

  final bool? finished;

  // 🚨 YENİ EKLENDİ: Backend'den gelen dinamik soru metni
  final String? questionText;

  GameStatusModel({
    this.sessionId,
    this.ghostName,
    this.ghostScore,
    this.totalQuestions,
    this.remainingQuestions,
    required this.currentScore,
    required this.remainingLives,
    this.countryName,
    this.options,
    this.message,
    this.lastAnswerCorrect,
    this.lastCorrectAnswer,
    this.finished,
    this.questionText, // 🚨 EKLENDİ
  });

  factory GameStatusModel.fromJson(Map<String, dynamic> json) {
    return GameStatusModel(
      sessionId: json['sessionId'],
      currentScore: json['currentScore'] ?? 0,
      remainingLives: json['remainingLives'] ?? 0,
      countryName: json['countryName'],
      ghostName: json['ghostName'],
      ghostScore: json['ghostScore'],
      totalQuestions: json['totalQuestions'],
      remainingQuestions: json['remainingQuestions'],
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : null,
      message: json['message'],
      lastAnswerCorrect: json['lastAnswerCorrect'],
      lastCorrectAnswer: json['lastCorrectAnswer'],
      finished: json['finished'],
      questionText: json['questionText'], // 🚨 EKLENDİ
    );
  }
}
