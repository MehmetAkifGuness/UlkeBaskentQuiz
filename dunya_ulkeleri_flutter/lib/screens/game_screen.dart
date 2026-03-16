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
      return Scaffold(body: Center(child: CircularProgressIndicator()));
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Skor: ${status.currentScore} | Can: ${status.remainingLives}",
        ),
        automaticallyImplyLeading: false,
      ),
      // 🚨 DEĞİŞİKLİK BURADA: status.finished == true şartı ve status.message eklendi
      body: (status.remainingLives <= 0 || status.finished == true)
          ? _buildGameOver(context, status.currentScore, status.message)
          : Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hangi modda oynadığını üste küçük yazıyla ekleyebiliriz
                    Text(
                      "Mod: ${widget.category}",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    SizedBox(height: 20),

                    // ⏱️ --- YENİ EKLENEN ŞIK KRONOMETRE UI ---
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
                            gameProvider
                                .formattedTime, // ⏱️ SAAT BURADA CANLI AKIYOR
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Courier', // Dijital saat görünümü
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),

                    // --------------------------------------
                    Text(
                      "${status.countryName} ülkesinin başkenti neresidir?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 30),

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
                          vertical: 5,
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                            backgroundColor: buttonColor,
                            disabledBackgroundColor: buttonColor,
                            disabledForegroundColor: Colors.white,
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
    );
  }

  // 🚨 DEĞİŞİKLİK BURADA: Zafer durumunu da kapsayan yeni Oyun Bitti tasarımı
  Widget _buildGameOver(BuildContext context, int score, String? message) {
    // Mesajın içinde "TEBRİKLER" geçiyorsa kazanmış demektir, yoksa kaybetmiştir.
    bool isVictory = message != null && message.contains("TEBRİKLER");

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Kazanma ve kaybetmeye göre değişen ikon
          Icon(
            isVictory ? Icons.emoji_events : Icons.videogame_asset_off,
            size: 100,
            color: isVictory ? Colors.amber : Colors.red,
          ),
          SizedBox(height: 20),

          // Kazanma ve kaybetmeye göre değişen başlık
          Text(
            isVictory ? "MUHTEŞEM ZAFER!" : "OYUN BİTTİ!",
            style: TextStyle(
              fontSize: 32,
              color: isVictory ? Colors.amber : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 15),

          // Backend'den gelen mesaj (Örn: +5000 Puan Bonus mesajı)
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

          // Skor
          Text(
            "Toplam Skorun: $score",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 40),

          // Buton
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber, // Altın sarısı buton
              foregroundColor: Colors.black, // Siyah yazı
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () {
              Provider.of<GameProvider>(context, listen: false).resetGame();
              Navigator.pop(context); // Ana sayfaya dön
            },
            child: Text(
              "Ana Sayfaya Dön",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
