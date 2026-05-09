/// Bot zorluk seviyeleri.
///
/// Not: Bu model local bot simülasyonu içindir. İleride multiplayer/back-end
/// senaryolarında da aynı zorluk değerleri yeniden kullanılabilir.
enum BotDifficulty {
  easy(
    displayName: 'Kolay Bot',
    minAnswerDelayMs: 4200,
    maxAnswerDelayMs: 6200,
    minRetryDelayMs: 5200,
    maxRetryDelayMs: 8200,
    correctAnswerChance: 0.30,
  ),
  medium(
    displayName: 'Orta Bot',
    minAnswerDelayMs: 2400,
    maxAnswerDelayMs: 3900,
    minRetryDelayMs: 2700,
    maxRetryDelayMs: 4300,
    correctAnswerChance: 0.55,
  ),
  hard(
    displayName: 'Zor Bot',
    minAnswerDelayMs: 1000,
    maxAnswerDelayMs: 2100,
    minRetryDelayMs: 900,
    maxRetryDelayMs: 1700,
    correctAnswerChance: 0.75,
  );

  final String displayName;
  final int minAnswerDelayMs;
  final int maxAnswerDelayMs;
  final int minRetryDelayMs;
  final int maxRetryDelayMs;
  final double correctAnswerChance;

  const BotDifficulty({
    required this.displayName,
    required this.minAnswerDelayMs,
    required this.maxAnswerDelayMs,
    required this.minRetryDelayMs,
    required this.maxRetryDelayMs,
    required this.correctAnswerChance,
  });
}

