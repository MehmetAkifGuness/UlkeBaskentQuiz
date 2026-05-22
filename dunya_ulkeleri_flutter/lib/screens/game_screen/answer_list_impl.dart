part of '../game_screen.dart';

extension _GameScreenStateAnswerListImpl on GameScreenState {
  Widget _buildAnswerList(
    BuildContext context,
    GameProvider gameProvider,
    AuthProvider authProvider,
    dynamic status,
  ) {
    final options = (status.options as List<dynamic>? ?? []);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: options
          .asMap()
          .entries
          .map<Widget>((entry) {
            final option = entry.value;
            final prefix = String.fromCharCode(65 + (entry.key % 26));

            var state = AnswerState.normal;
            if (gameProvider.showResult) {
              if (gameProvider.correctAnswer != null) {
                if (option == gameProvider.correctAnswer) {
                  state = AnswerState.correct;
                } else if (option == gameProvider.selectedAnswer) {
                  state = AnswerState.wrong;
                } else {
                  state = AnswerState.disabled;
                }
              } else {
                if (option == gameProvider.selectedAnswer) {
                  state = AnswerState.selected;
                } else {
                  state = AnswerState.disabled;
                }
              }
            }

            return AnswerButton(
              prefix: prefix,
              text: option.toString(),
              state: state,
              onPressed: () {
                if (!gameProvider.isLoading && !gameProvider.showResult) {
                  final settingsProvider = Provider.of<SettingsProvider>(
                    context,
                    listen: false,
                  );
                  gameProvider.sendGuess(
                    authProvider.token!,
                    option.toString(),
                    playSound: settingsProvider.isSoundEnabled,
                    vibrate: settingsProvider.isVibrationEnabled,
                  );
                }
              },
            );
          })
          .toList(),
    );
  }
}

