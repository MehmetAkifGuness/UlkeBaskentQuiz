import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
// ignore: unused_import
import '../models/game_status_model.dart';

class GameScreen extends StatefulWidget {
  final String category;

  const GameScreen({Key? key, required this.category}) : super(key: key);

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
      gameProvider.startNewGame(authProvider.token!, widget.category);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final status = gameProvider.status;

    if (gameProvider.isLoading && status == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    if (status == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Hata")),
        body: Center(
          child: Text(
            "Oyun yüklenirken hata oluştu veya bu kategoride soru yok.",
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
          style: TextStyle(fontWeight: FontWeight.bold),
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
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      status.message ?? "Oyun Devam Ediyor...",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),

                    // ⏱️ --- KRONOMETRE UI ---
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.amber, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer, color: Colors.amber, size: 28),
                          SizedBox(width: 10),
                          Text(
                            gameProvider.formattedTime,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Courier',
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),

                    // 👻 --- AKILLI HAYALET SÜRÜCÜ BÖLÜMÜ ---
                    if (status.ghostScore != null &&
                        status.totalQuestions != null)
                      // KİMSE OYNAMAMIŞSA: Motive edici mesaj
                      if (status.ghostScore == 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 10.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Kalan Soru: ${status.remainingQuestions}",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.emoji_events,
                                    color: Colors.amber,
                                    size: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "İlk rekoru sen kır!",
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      else
                        // REKOR VARSA: İkili Barı Göster
                        ScoreProgressWidget(
                          ghostName: status.ghostName!,
                          ghostScore: status.ghostScore!,
                          currentScore: status.currentScore,
                          totalQuestions: status.totalQuestions!,
                          remainingQuestions: status.remainingQuestions ?? 0,
                        ),

                    SizedBox(height: 20),

                    // SORU METNİ
                    Text(
                      "${status.countryName} ülkesinin başkenti neresidir?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 30),

                    // ŞIKLAR
                    ...(status.options ?? []).map((option) {
                      Color? buttonColor;
                      if (gameProvider.showResult &&
                          gameProvider.correctAnswer != null) {
                        if (option == gameProvider.correctAnswer) {
                          buttonColor = Colors.green;
                        } else if (option == gameProvider.selectedAnswer) {
                          buttonColor = Colors.red;
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 55),
                            backgroundColor:
                                buttonColor ?? Colors.blueGrey[800],
                            disabledBackgroundColor: buttonColor,
                            disabledForegroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed:
                              (gameProvider.isLoading ||
                                  gameProvider.showResult)
                              ? null
                              : () => gameProvider.sendGuess(
                                  authProvider.token!,
                                  option,
                                ),
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
                // ignore: unnecessary_null_comparison
                if (gameProvider.isLoading && status != null)
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: CircularProgressIndicator(color: Colors.amber),
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
            color: isVictory ? Colors.amber : Colors.red,
          ),
          SizedBox(height: 20),
          Text(
            isDaily
                ? "GÖREV TAMAMLANDI!"
                : (isVictory ? "MUHTEŞEM ZAFER!" : "OYUN BİTTİ!"),
            style: TextStyle(
              fontSize: 32,
              color: isVictory ? Colors.amber : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 15),
          if (message != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
            ),
          SizedBox(height: 30),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber, width: 2),
            ),
            child: Text(
              "Skorun: $score",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
          ),
          SizedBox(height: 40),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: Icon(Icons.home),
            label: Text(
              "Ana Sayfaya Dön",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

// 🏁 --- YENİ: İKİLİ İLERLEME ÇUBUĞU (SORU VE SKOR) --- 🏃
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
    // 1. SORU İLERLEMESİ HESAPLARI
    int answeredQuestions = totalQuestions - remainingQuestions;
    double questionProgress = totalQuestions > 0
        ? (answeredQuestions / totalQuestions)
        : 0.0;
    if (questionProgress > 1.0) questionProgress = 1.0;

    // 2. SKOR İLERLEMESİ HESAPLARI (Maksimum Olası Skor: Soru Sayısı * 2000)
    int maxPossibleScore = totalQuestions * 2000;
    double scoreProgress = maxPossibleScore > 0
        ? (currentScore / maxPossibleScore)
        : 0.0;
    double ghostProgress = maxPossibleScore > 0
        ? (ghostScore / maxPossibleScore)
        : 0.0;

    if (scoreProgress > 1.0) scoreProgress = 1.0;
    if (ghostProgress > 1.0) ghostProgress = 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- 1. BAR: SORU DURUMU ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Soru İlerlemesi",
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                "$answeredQuestions / $totalQuestions",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: questionProgress),
                duration: Duration(milliseconds: 500),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return FractionallySizedBox(
                    widthFactor: value > 0.0 ? value : 0.0,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          SizedBox(height: 15),

          // --- 2. BAR: SKOR VE HAYALET DURUMU ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Sen ($currentScore Puan)",
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                "👑 $ghostName ($ghostScore Puan)",
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Arka Plan
              Container(
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                ),
              ),
              // Senin Skorunun Çubuğu
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: scoreProgress),
                duration: Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return FractionallySizedBox(
                    widthFactor: value > 0.0 ? value : 0.0,
                    child: Container(
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange, Colors.amber],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.centerRight,
                      child: value > 0.05
                          ? Padding(
                              padding: const EdgeInsets.only(right: 2.0),
                              child: Text("🏃", style: TextStyle(fontSize: 12)),
                            )
                          : null,
                    ),
                  );
                },
              ),
              // Hayaletin Sabit Bayrağı (Rekor Konumu)
              FractionallySizedBox(
                widthFactor: ghostProgress,
                child: Container(
                  alignment: Alignment.centerRight,
                  height: 18,
                  child: OverflowBox(
                    maxWidth: 30,
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 2,
                          height: 18,
                          color: Colors.redAccent,
                        ),
                        Text("🏁", style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
