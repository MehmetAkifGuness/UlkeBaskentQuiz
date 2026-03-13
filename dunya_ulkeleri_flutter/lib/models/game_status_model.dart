class GameStatusModel {
  final int? sessionId;
  final int currentScore;
  final int remainingLives;
  final String? countryName;
  final List<String>? options;
  final String? message;
  final bool? lastAnswerCorrect;
  final String? lastCorrectAnswer;

  GameStatusModel({
    this.sessionId,
    required this.currentScore,
    required this.remainingLives,
    this.countryName,
    this.options,
    this.message,
    this.lastAnswerCorrect,
    this.lastCorrectAnswer,
  });

  //backend den gelen veriyi fluttera dönüştüren kısım
  factory GameStatusModel.fromJson(Map<String, dynamic> json) {
    return GameStatusModel(
      lastAnswerCorrect: json['lastAnswerCorrect'],
      lastCorrectAnswer: json['lastCorrectAnswer'],
      sessionId: json['sessionId'],
      currentScore: json['currentScore'] ?? 0,
      remainingLives: json['remainingLives'] ?? 0,
      countryName: json['countryName'],
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : null,
      message: json['message'],
    );
  }
}
