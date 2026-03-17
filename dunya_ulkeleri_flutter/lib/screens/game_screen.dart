import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';

class GameScreen extends StatefulWidget {
  final String category; // Hangi kıtada oynanacağını tutan değişken

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
      // Seçilen kategoriyi göndererek oyunu başlatıyoruz
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

    // 🚨 YENİ: Hangi modda olduğumuzu anlıyoruz
    bool isDaily = widget.category == "DailyChallenge";

    return Scaffold(
      appBar: AppBar(
        // 🚨 YENİ: Günün Görevinde can barını gizleyip özel başlık ekliyoruz
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
                    // Backend'den gelen mesajı (Örn: Soru 3/10) burada gösteriyoruz
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
                    SizedBox(height: 30),

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
                // YÜKLENİYOR ANİMASYONU
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

  // --- OYUN BİTTİ EKRANI ---
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

          // 🚨 YENİ: Günün görevinde kazanılan puan daha vurgulu
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
              Navigator.pop(context); // Ana sayfaya dön
            },
          ),
        ],
      ),
    );
  }
}
