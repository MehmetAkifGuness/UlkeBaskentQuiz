class GameStatusModel {
  final int sessionId;
  final bool? lastAnswerCorrect;
  final String? lastCorrectAnswer;
  final int currentScore;
  final int remainingLives;
  final String? countryName;
  final List<String>? options;
  final String? message;
  final bool finished;

  // 🚨 YENİ EKLENEN DEĞİŞKENLER
  final String? ghostName;
  final int? ghostScore;
  final int? totalQuestions;
  final int? remainingQuestions;

  GameStatusModel({
    required this.sessionId,
    this.lastAnswerCorrect,
    this.lastCorrectAnswer,
    required this.currentScore,
    required this.remainingLives,
    this.countryName,
    this.options,
    this.message,
    required this.finished,
    this.ghostName,
    this.ghostScore,
    this.totalQuestions,
    this.remainingQuestions,
  });

  factory GameStatusModel.fromJson(Map<String, dynamic> json) {
    return GameStatusModel(
      sessionId: json['sessionId'],
      lastAnswerCorrect: json['lastAnswerCorrect'],
      lastCorrectAnswer: json['lastCorrectAnswer'],
      currentScore: json['currentScore'],
      remainingLives: json['remainingLives'],
      countryName: json['countryName'],
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : null,
      message: json['message'],
      finished: json['finished'],
      ghostName: json['ghostName'],
      ghostScore: json['ghostScore'],
      totalQuestions: json['totalQuestions'],
      remainingQuestions: json['remainingQuestions'],
    );
  }
}
