/// Bot zorluk seviyeleri.
///
/// Not: Bu model local bot simülasyonu içindir. İleride multiplayer/back-end
/// senaryolarında da aynı zorluk değerleri yeniden kullanılabilir.
enum BotDifficulty {
  easy(
    displayName: 'Kolay Bot',
    minAnswerDelayMs: 4000,
    maxAnswerDelayMs: 5500,
    correctAnswerChance: 0.55,
  ),
  medium(
    displayName: 'Orta Bot',
    minAnswerDelayMs: 2500,
    maxAnswerDelayMs: 4000,
    correctAnswerChance: 0.75,
  ),
  hard(
    displayName: 'Zor Bot',
    minAnswerDelayMs: 1000,
    maxAnswerDelayMs: 2200,
    correctAnswerChance: 0.90,
  );

  final String displayName;
  final int minAnswerDelayMs;
  final int maxAnswerDelayMs;
  final double correctAnswerChance;

  const BotDifficulty({
    required this.displayName,
    required this.minAnswerDelayMs,
    required this.maxAnswerDelayMs,
    required this.correctAnswerChance,
  });
}

