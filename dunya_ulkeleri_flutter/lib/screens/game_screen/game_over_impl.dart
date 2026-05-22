part of '../game_screen.dart';
extension _GameScreenStateGameOverImpl on GameScreenState {
  Widget _buildGameOverImpl(
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
      } else if (isEndless) {
        titleText = "HARİKA BİR TURDU!";
      } else {
        titleText = "YENİDEN DENE!";
      }
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
                color: mainColor.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: mainColor.withValues(alpha: 0.3),
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
                        .withValues(alpha: 0.4),
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
                      color: Colors.white.withValues(alpha: 0.9),
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
                shadowColor: AppColors.primaryBlue.withValues(alpha: 0.5),
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
                final token = context.read<AuthProvider>().token;
                if (token != null && token.trim().isNotEmpty) {
                  context.read<ProfileProvider>().refresh(token);
                }
                Provider.of<GameProvider>(context, listen: false).resetGame();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }}

