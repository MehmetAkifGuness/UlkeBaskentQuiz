// lib/screens/game_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_button.dart';

class GameScreen extends StatefulWidget {
  final String category;
  final String mode;
  const GameScreen({Key? key, required this.category, required this.mode})
    : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final gameProvider = Provider.of<GameProvider>(context, listen: false);

      gameProvider.resetGame();
      gameProvider.startNewGame(
        authProvider.token!,
        widget.category,
        widget.mode,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final status = gameProvider.status;

    if (gameProvider.isLoading && status == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    if (status == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Hata")),
        body: const Center(
          child: Text(
            "Oyun yüklenirken hata oluştu veya bu kategoride soru yok.",
            style: TextStyle(color: AppColors.textDark),
          ),
        ),
      );
    }

    bool isDaily = widget.category == "DailyChallenge";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isDaily
              ? "Skor: ${status.currentScore} | 🎯 Günün Görevi"
              : "Skor: ${status.currentScore} | ❤️ Can: ${status.remainingLives}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: (status.remainingLives <= 0 || status.finished == true)
          ? _buildGameOver(
              context,
              status.currentScore,
              status.message,
              isDaily,
            )
          : Stack(
              children: [
                // YENİ: SafeArea ve Scroll olmayan, esnek Column yapısı
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. ÜST KISIM (Mesaj, Timer ve Bar)
                        Column(
                          children: [
                            Text(
                              status.message ?? "Oyun Devam Ediyor...",
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ⏱️ Kronometre UI
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: AppColors.borderBlueish,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue.withOpacity(
                                      0.1,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.timer_outlined,
                                    color: AppColors.primaryBlue,
                                    size: 26,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    gameProvider.formattedTime,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                      fontFamily: 'Courier',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 👻 Akıllı Hayalet / Soru İlerlemesi
                            if (status.ghostScore != null &&
                                status.totalQuestions != null)
                              if (status.ghostScore == 0)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Kalan Soru: ${status.remainingQuestions}",
                                      style: const TextStyle(
                                        color: AppColors.textDark,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Row(
                                      children: const [
                                        Icon(
                                          Icons.emoji_events,
                                          color: AppColors.yellow,
                                          size: 20,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          "İlk rekoru sen kır!",
                                          style: TextStyle(
                                            color: AppColors.yellow,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              else
                                ScoreProgressWidget(
                                  ghostName: status.ghostName!,
                                  ghostScore: status.ghostScore!,
                                  currentScore: status.currentScore,
                                  totalQuestions: status.totalQuestions!,
                                  remainingQuestions:
                                      status.remainingQuestions ?? 0,
                                ),
                          ],
                        ),

                        // YENİ: Soru Kartını ekranın ortasında kalan boşluğa yayarak ortalayan yapı
                        Expanded(
                          child: Center(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.borderLight,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize
                                    .min, // Kart sadece içeriği kadar büyür
                                children: [
                                  const Icon(
                                    Icons.public,
                                    color: AppColors.brown,
                                    size: 44,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    status.questionText ??
                                        "${status.countryName} ülkesinin başkenti neresidir?",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // 3. ALT KISIM (Şıklar - Sabit olarak en altta durur)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: (status.options ?? []).map((option) {
                            AnswerState state = AnswerState.normal;

                            if (gameProvider.showResult) {
                              if (option == gameProvider.correctAnswer) {
                                state = AnswerState.correct;
                              } else if (option ==
                                  gameProvider.selectedAnswer) {
                                state = AnswerState.wrong;
                              } else {
                                state = AnswerState.disabled;
                              }
                            }

                            return AnswerButton(
                              text: option,
                              state: state,
                              onPressed: () {
                                if (!gameProvider.isLoading &&
                                    !gameProvider.showResult) {
                                  gameProvider.sendGuess(
                                    authProvider.token!,
                                    option,
                                  );
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(
                          height: 8,
                        ), // Ekranın en altında minik bir nefes boşluğu
                      ],
                    ),
                  ),
                ),

                // Yüklenme (Loading) Göstergesi
                // ignore: unnecessary_null_comparison
                if (gameProvider.isLoading && status != null)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildGameOver(
    BuildContext context,
    int score,
    String? message,
    bool isDaily,
  ) {
    bool isVictory =
        message != null &&
        (message.contains("TEBRİKLER") || message.contains("Tamamlandı"));

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isVictory ? Icons.emoji_events : Icons.videogame_asset_off,
            size: 100,
            color: isVictory ? AppColors.yellow : AppColors.errorRed,
          ),
          const SizedBox(height: 20),
          Text(
            isDaily
                ? "GÖREV TAMAMLANDI!"
                : (isVictory ? "MUHTEŞEM ZAFER!" : "OYUN BİTTİ!"),
            style: TextStyle(
              fontSize: 32,
              color: isVictory ? AppColors.yellow : AppColors.errorRed,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          if (message != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: AppColors.textDark),
              ),
            ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.yellow, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.yellow.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              "Skorun: $score",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.yellow,
              ),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
            ),
            icon: const Icon(Icons.home, color: AppColors.white),
            label: const Text(
              "Ana Sayfaya Dön",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            onPressed: () {
              Provider.of<GameProvider>(context, listen: false).resetGame();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

// 🏁 --- İKİLİ İLERLEME ÇUBUĞU --- 🏃
class ScoreProgressWidget extends StatelessWidget {
  final String ghostName;
  final int ghostScore;
  final int currentScore;
  final int totalQuestions;
  final int remainingQuestions;

  const ScoreProgressWidget({
    Key? key,
    required this.ghostName,
    required this.ghostScore,
    required this.currentScore,
    required this.totalQuestions,
    required this.remainingQuestions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int answeredQuestions = totalQuestions - remainingQuestions;
    double questionProgress = totalQuestions > 0
        ? (answeredQuestions / totalQuestions)
        : 0.0;
    if (questionProgress > 1.0) questionProgress = 1.0;

    int maxPossibleScore = totalQuestions * 2000;
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

        const SizedBox(height: 12),

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
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
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
            /* FractionallySizedBox(
              widthFactor: ghostProgress,
              child: Container(
                alignment: Alignment.centerRight,
                height: 16,
                child: OverflowBox(
                  maxWidth: 30,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 2,
                        height: 16,
                        color: AppColors.errorRed,
                      ),
                      const Text("🏁", style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ),*/
          ],
        ),
      ],
    );
  }
}
