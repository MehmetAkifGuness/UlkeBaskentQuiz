part of '../duel_game_screen.dart';

class _QuestionCard extends StatelessWidget {
  final int? roundNumber;
  final String? questionText;
  final DateTime? deadlineAt;
  final bool locked;
  final List<String> options;
  final String? correctAnswer;
  final String? selectedOption;
  final bool? selectedAnswerCorrect;
  final ValueChanged<String> onSelect;

  const _QuestionCard({
    required this.roundNumber,
    required this.questionText,
    required this.deadlineAt,
    required this.locked,
    required this.options,
    required this.correctAnswer,
    required this.selectedOption,
    required this.selectedAnswerCorrect,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      tint: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Tur ${roundNumber ?? '-'}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              _CountdownPill(deadlineAt: deadlineAt, locked: locked),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            questionText ?? '-',
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < options.length; i++)
            AnswerButton(
              prefix: String.fromCharCode(65 + i),
              text: options[i],
              state: _answerStateForOption(options[i]),
              onPressed: () => onSelect(options[i]),
            ),
          if (locked && correctAnswer != null) ...[
            const SizedBox(height: 6),
            Text(
              'Doğru cevap: $correctAnswer',
              style: const TextStyle(
                color: AppColors.successGreen,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  AnswerState _answerStateForOption(String option) {
    final correct = (correctAnswer ?? '').trim();
    final selected = (selectedOption ?? '').trim();
    final selectedCorrect = selectedAnswerCorrect;

    if (locked) {
      if (correct.isNotEmpty &&
          option.trim().toLowerCase() == correct.toLowerCase()) {
        return AnswerState.correct;
      }
      if (selected.isNotEmpty &&
          option.trim().toLowerCase() == selected.toLowerCase()) {
        return AnswerState.wrong;
      }
      return AnswerState.disabled;
    }

    if (selected.isNotEmpty) {
      if (option.trim().toLowerCase() == selected.toLowerCase()) {
        if (selectedCorrect == true) return AnswerState.correct;
        if (selectedCorrect == false) return AnswerState.wrong;
        return AnswerState.selected;
      }
      return AnswerState.disabled;
    }

    return AnswerState.normal;
  }
}

class _CountdownPill extends StatelessWidget {
  final DateTime? deadlineAt;
  final bool locked;

  const _CountdownPill({required this.deadlineAt, required this.locked});

  @override
  Widget build(BuildContext context) {
    final deadline = deadlineAt;
    if (deadline == null) return const SizedBox.shrink();

    return StreamBuilder<int>(
      stream: Stream<int>.periodic(const Duration(milliseconds: 250), (x) => x),
      builder: (context, snapshot) {
        if (locked) return _pill('Bitti', AppColors.textMuted);

        final remaining = deadline.difference(DateTime.now());
        final seconds = remaining.inSeconds;
        if (seconds <= 0) return _pill('0s', AppColors.errorRed);
        final color = seconds <= 5 ? AppColors.errorRed : AppColors.primaryBlue;
        return _pill('${seconds}s', color);
      },
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderLight),
        color: color.withValues(alpha: 0.14),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
