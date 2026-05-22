part of '../game_screen.dart';
class ScoreProgressWidget extends StatelessWidget {
  final String ghostName;
  final int ghostScore;
  final int currentScore;
  final int totalQuestions;
  final int remainingQuestions;

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
    int answeredQuestions = totalQuestions - remainingQuestions;
    double questionProgress = totalQuestions > 0
        ? (answeredQuestions / totalQuestions)
        : 0.0;
    if (questionProgress > 1.0) questionProgress = 1.0;

    // Maksimum alınabilecek teorik skor (Soru başı 2000 puan)
    int maxPossibleScore = totalQuestions * 2000;

    // Senin ve rakibin (hayaletin) bar üzerindeki yüzde hesaplamaları
    double scoreProgress = maxPossibleScore > 0
        ? (currentScore / maxPossibleScore)
        : 0.0;
    double ghostProgress = maxPossibleScore > 0
        ? (ghostScore / maxPossibleScore)
        : 0.0;

    if (scoreProgress > 1.0) scoreProgress = 1.0;
    if (ghostProgress > 1.0) ghostProgress = 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- 1. BAR: SORU DURUMU ---
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
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: questionProgress),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return FractionallySizedBox(
                  widthFactor: value > 0.0 ? value : 0.0,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.successGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 16), // Araya biraz daha nefes boşluğu ekledik
        // --- 2. BAR: SKOR VE HAYALET DURUMU ---
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
          clipBehavior: Clip
              .none, // 🚨 YENİ: Hedef çizgisinin barın dışına hafif taşabilmesi için
          children: [
            // 1. Gri Arka Plan Barı
            Container(
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // 2. Senin Skorun (Dolan Mavi Bar)
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: scoreProgress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return FractionallySizedBox(
                  widthFactor: value > 0.0 ? value : 0.0,
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

            // 3. 🚨 YENİ EKLENDİ: Rakibin (Hayaletin) Skoru İçin Hedef Çizgisi
            if (ghostProgress > 0.0)
              FractionallySizedBox(
                widthFactor: ghostProgress,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 4, // Çizginin kalınlığı
                    height:
                        24, // Bardan (16px) biraz daha uzun, belirgin bir hedef çizgisi
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ), // Şık dursun diye ince beyaz çerçeve
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
        const SizedBox(height: 8), // Alt boşluk
      ],
    );
  }
}

