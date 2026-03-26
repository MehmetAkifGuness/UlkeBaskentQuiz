// lib/screens/game_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_button.dart';
import '../providers/settings_provider.dart';

class GameScreen extends StatefulWidget {
  final String category;
  final String mode;
  final bool isContinuing;

  const GameScreen({
    super.key,
    required this.category,
    required this.mode,
    required this.isContinuing,
  });

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

      if (!widget.isContinuing) {
        gameProvider.resetGame();
        gameProvider.startNewGame(
          authProvider.token!,
          widget.category,
          widget.mode,
        );
      }
    });
  }

  Future<bool> _onWillPop() async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    if (gameProvider.status?.finished == true) {
      gameProvider.resetGame();
      return true;
    }

    bool shouldPop =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.pause_circle_filled, color: Colors.amber, size: 28),
                SizedBox(width: 10),
                Text('Oyunu Duraklat', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Text(
              'Oyundan çıkmak istediğinize emin misiniz? İlerlemeniz kaydedilecek ve Ana Sayfadan devam edebileceksiniz.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Provider.of<SettingsProvider>(
                    context,
                    listen: false,
                  ).triggerButtonVibration();
                  Navigator.of(context).pop(false);
                },
                child: Text(
                  'Hayır, Devam Et',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  Provider.of<SettingsProvider>(
                    context,
                    listen: false,
                  ).triggerButtonVibration();
                  Navigator.of(context).pop(true);
                },
                child: Text('Evet, Çık'),
              ),
            ],
          ),
        ) ??
        false;

    return shouldPop;
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final status = gameProvider.status;

    bool isDaily = widget.category == "DailyChallenge";
    // ignore: unused_local_variable
    bool isEndless = widget.mode == "ENDLESS";

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: _buildBody(
        context,
        gameProvider,
        authProvider,
        status,
        isDaily,
        isEndless,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    GameProvider gameProvider,
    AuthProvider authProvider,
    dynamic status,
    bool isDaily,
    bool isEndless,
  ) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isDaily
              ? "Skor: ${status.currentScore} | 🎯 Günün Görevi"
              : isEndless
              ? "Skor: ${status.currentScore} | ♾️ Sonsuz Mod"
              : "Skor: ${status.currentScore} | ❤️ Can: ${status.remainingLives}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            Provider.of<SettingsProvider>(
              context,
              listen: false,
            ).triggerButtonVibration();
            bool shouldPop = await _onWillPop();
            if (shouldPop && mounted) Navigator.pop(context);
          },
        ),
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
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                            if (isEndless)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: Colors.redAccent,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.redAccent,
                                          size: 20,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          "Tek Yanlışta Biter!",
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      "👑 Rekor: ${status.ghostScore == 0 ? 'Yok' : status.ghostScore}",
                                      style: const TextStyle(
                                        color: AppColors.brown,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (status.ghostScore != null &&
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
                                mainAxisSize: MainAxisSize.min,
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
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: (status.options as List<dynamic>? ?? [])
                              .map<Widget>((option) {
                                AnswerState state = AnswerState.normal;

                                if (gameProvider.showResult) {
                                  // 🚨 YENİ MANTIK: Eğer API'den cevap döndüyse (correctAnswer null değilse)
                                  if (gameProvider.correctAnswer != null) {
                                    if (option == gameProvider.correctAnswer) {
                                      state = AnswerState.correct;
                                    } else if (option ==
                                        gameProvider.selectedAnswer) {
                                      state = AnswerState.wrong;
                                    } else {
                                      state = AnswerState.disabled;
                                    }
                                  }
                                  // 🚨 YENİ MANTIK: API'den cevap bekleniyorsa (Loading aşaması)
                                  else {
                                    if (option == gameProvider.selectedAnswer) {
                                      state = AnswerState
                                          .selected; // SARI BEKLEME RENGİ!
                                    } else {
                                      state = AnswerState
                                          .disabled; // Diğerleri soluklaşır
                                    }
                                  }
                                }

                                return AnswerButton(
                                  text: option.toString(),
                                  state: state,
                                  onPressed: () {
                                    if (!gameProvider.isLoading &&
                                        !gameProvider.showResult) {
                                      final settingsProvider =
                                          Provider.of<SettingsProvider>(
                                            context,
                                            listen: false,
                                          );

                                      gameProvider.sendGuess(
                                        authProvider.token!,
                                        option.toString(),
                                        playSound:
                                            settingsProvider.isSoundEnabled,
                                        vibrate:
                                            settingsProvider.isVibrationEnabled,
                                      );
                                    }
                                  },
                                );
                              })
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
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

    bool isEndless = widget.mode == "ENDLESS";

    String titleText;
    if (isVictory) {
      titleText = isDaily ? "GÖREV TAMAMLANDI!" : "MUHTEŞEM ZAFER!";
    } else {
      if (isDaily) {
        titleText = "GÜZEL DENEME!";
      } else if (isEndless)
        titleText = "HARİKA BİR TURDU!";
      else
        titleText = "YENİDEN DENE!";
    }

    Color mainColor = isVictory
        ? Colors.amberAccent
        : Colors.cyanAccent.shade400;

    IconData mainIcon = isVictory
        ? Icons.emoji_events_rounded
        : Icons.rocket_launch_rounded;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: mainColor.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: mainColor.withOpacity(0.3),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(mainIcon, size: 110, color: mainColor),
            ),
            const SizedBox(height: 35),
            Text(
              titleText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                color: mainColor,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 15),
            if (message != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isVictory
                      ? [Colors.amber.shade700, Colors.orangeAccent]
                      : [Colors.lightBlue.shade400, Colors.indigo.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: (isVictory ? Colors.orange : Colors.blue)
                        .withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Kazanılan Skor",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "$score",
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                elevation: 8,
                shadowColor: AppColors.primaryBlue.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 35,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(
                Icons.home_rounded,
                color: AppColors.white,
                size: 28,
              ),
              label: const Text(
                "Ana Sayfaya Dön",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              onPressed: () {
                Provider.of<SettingsProvider>(
                  context,
                  listen: false,
                ).triggerButtonVibration();
                Provider.of<GameProvider>(context, listen: false).resetGame();
                Navigator.pop(context);
              },
            ),
          ],
        ),
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
                          color: Colors.amber.withOpacity(0.8),
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
