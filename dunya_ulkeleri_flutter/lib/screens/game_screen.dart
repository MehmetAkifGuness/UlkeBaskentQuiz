// lib/screens/game_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_button.dart';
import '../providers/settings_provider.dart';

part 'game_screen/score_progress_widget.dart';
part 'game_screen/body_impl.dart';
part 'game_screen/answer_list_impl.dart';
part 'game_screen/game_over_impl.dart';

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
  GameScreenState createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> {
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
      final token = context.read<AuthProvider>().token;
      if (token != null && token.trim().isNotEmpty) {
        context.read<ProfileProvider>().refresh(token);
      }
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
      onPopInvokedWithResult: (didPop, result) async {
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
    return _buildBodyImpl(
      context,
      gameProvider,
      authProvider,
      status,
      isDaily,
      isEndless,
    );
  }

  Widget _buildGameOver(
    BuildContext context,
    int score,
    String? message,
    bool isDaily,
  ) {
    return _buildGameOverImpl(
      context,
      score,
      message,
      isDaily,
    );
  }

}

