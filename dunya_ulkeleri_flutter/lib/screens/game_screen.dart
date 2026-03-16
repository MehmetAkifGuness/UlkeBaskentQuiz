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
      body: status.remainingLives <= 0
          ? _buildGameOver(context, status.currentScore)
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

  Widget _buildGameOver(BuildContext context, int score) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "OYUN BİTTİ!",
            style: TextStyle(
              fontSize: 32,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text("Toplam Skorun: $score", style: TextStyle(fontSize: 24)),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Provider.of<GameProvider>(context, listen: false).resetGame();
              Navigator.pop(context); // Ana sayfaya dön
            },
            child: Text("Ana Sayfaya Dön"),
          ),
        ],
      ),
    );
  }
}
