part of '../game_screen.dart';

class ScoreProgressWidget extends StatelessWidget {
  final String ghostName;
  final int ghostScore;
  final int currentScore;
  final int totalQuestions;
  final int remainingQuestions;

  // Sabit değerler sınıf değişkeni olarak tanımlandı
  static const int _maxScorePerQuestion = 2000;
  static const Duration _questionAnimDuration = Duration(milliseconds: 500);
  static const Duration _scoreAnimDuration = Duration(milliseconds: 800);

  const ScoreProgressWidget({
    super.key,
    required this.ghostName,
    required this.ghostScore,
    required this.currentScore,
    required this.totalQuestions,
    required this.remainingQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final int answeredQuestions = totalQuestions - remainingQuestions;
    final int maxPossibleScore = totalQuestions * _maxScorePerQuestion;

    // .clamp(0.0, 1.0) kullanılarak sınır kontrolleri kısaltıldı
    final double questionProgress = totalQuestions > 0
        ? (answeredQuestions / totalQuestions).clamp(0.0, 1.0)
        : 0.0;

    final double scoreProgress = maxPossibleScore > 0
        ? (currentScore / maxPossibleScore).clamp(0.0, 1.0)
        : 0.0;

    final double ghostProgress = maxPossibleScore > 0
        ? (ghostScore / maxPossibleScore).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildQuestionProgressSection(answeredQuestions, questionProgress),
        const SizedBox(height: 16),
        _buildScoreProgressSection(scoreProgress, ghostProgress),
        const SizedBox(height: 8),
      ],
    );
  }

  // --- 1. BAR: SORU DURUMU ---
  Widget _buildQuestionProgressSection(
    int answeredQuestions,
    double questionProgress,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Soru İlerlemesi",
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              "$answeredQuestions / $totalQuestions",
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // TweenAnimationBuilder optimizasyonu: Sabit UI child üzerinden geçildi
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: questionProgress),
              duration: _questionAnimDuration,
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return FractionallySizedBox(widthFactor: value, child: child);
              },
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.successGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- 2. BAR: SKOR VE HAYALET DURUMU ---
  Widget _buildScoreProgressSection(
    double scoreProgress,
    double ghostProgress,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Sen ($currentScore Puan)",
              style: const TextStyle(
                color: AppColors.primaryBlueHover,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              "👑 $ghostName ($ghostScore Puan)",
              style: const TextStyle(
                color: AppColors.brown,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          alignment: Alignment.centerLeft,
          clipBehavior: Clip.none,
          children: [
            // Gri Arka Plan Barı
            Container(
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Senin Skorun (Dolan Mavi Bar)
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: scoreProgress),
              duration: _scoreAnimDuration,
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.lightBlueHover,
                          AppColors.primaryBlue,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.centerRight,
                    child: value > 0.05
                        ? const Padding(
                            padding: EdgeInsets.only(right: 2.0),
                            child: Text("🏃", style: TextStyle(fontSize: 10)),
                          )
                        : null,
                  ),
                );
              },
            ),

            // Rakibin (Hayaletin) Skoru İçin Hedef Çizgisi
            if (ghostProgress > 0.0)
              FractionallySizedBox(
                widthFactor: ghostProgress,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: Colors.white, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.8),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
