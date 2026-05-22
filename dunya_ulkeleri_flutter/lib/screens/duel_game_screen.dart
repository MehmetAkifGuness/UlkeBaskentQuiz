import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/duel_session_dto.dart';
import '../providers/auth_provider.dart';
import '../providers/duel_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_button.dart';
import '../widgets/geo_background.dart';
import '../widgets/glass_card.dart';

class DuelGameScreen extends StatefulWidget {
  const DuelGameScreen({super.key});

  @override
  State<DuelGameScreen> createState() => _DuelGameScreenState();
}

class _DuelGameScreenState extends State<DuelGameScreen> {
  String? _selectedOption;
  int? _roundNumber;
  bool _didRefreshProfileOnFinish = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DuelProvider>().connectToCurrentSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final duel = context.watch<DuelProvider>();
    final state = duel.sessionState;
    final token = context.watch<AuthProvider>().token;
    final myPlayerId = duel.playerId;

    final round = state?.currentRound;
    final currentRoundNumber = round?.roundNumber;
    if (currentRoundNumber != null && currentRoundNumber != _roundNumber) {
      _roundNumber = currentRoundNumber;
      _selectedOption = null;
    }

    if ((state?.finished ?? false) && !_didRefreshProfileOnFinish) {
      _didRefreshProfileOnFinish = true;
      if (token != null && token.trim().isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.read<ProfileProvider>().refresh(token);
        });
      }
    }

    final bottomPad = MediaQuery.of(context).padding.bottom + 24.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        await duel.leaveSession(token: token);
        if (!context.mounted) return;
        navigator.pop(result);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Düello'),
          actions: [
            IconButton(
              onPressed: duel.isLoading ? null : duel.requestState,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Yenile',
            ),
            IconButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await duel.leaveSession(token: token);
                if (!context.mounted) return;
                navigator.maybePop();
              },
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Çık',
            ),
          ],
        ),
        body: GeoBackground(
          safeArea: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad),
            physics: const BouncingScrollPhysics(),
            children: [
              _HeaderCard(
                roomCode: state?.roomCode,
                category: state?.category,
                mode: state?.mode,
                status: state?.status,
              ),
              const SizedBox(height: 12),
              if (state == null)
                const _InfoCard(
                  title: 'Bağlanılıyor…',
                  text: 'Oturum bilgisi bekleniyor.',
                  icon: Icons.wifi_tethering_rounded,
                )
              else if ((state.status ?? '').toUpperCase() == 'WAITING')
                const _InfoCard(
                  title: 'Rakip Bekleniyor',
                  text: 'Bir oyuncu katıldığında oyun otomatik başlayacak.',
                  icon: Icons.hourglass_bottom_rounded,
                )
              else
                _QuestionCard(
                  roundNumber: round?.roundNumber,
                  questionText: round?.questionText,
                  deadlineAt: round?.deadlineAt,
                  locked: round?.locked ?? false,
                  options: round?.options ?? const <String>[],
                  correctAnswer: round?.correctAnswer,
                  selectedOption: _selectedOption,
                  onSelect: (value) {
                    setState(() => _selectedOption = value);
                    duel.submitAnswer(value);
                  },
                ),
              const SizedBox(height: 12),
              _ScoreboardCard(
                myPlayerId: myPlayerId,
                players: state?.players ?? const [],
                winnerUsername: state?.winnerUsername,
                finished: state?.finished ?? false,
              ),
              if (duel.errorMessage != null) ...[
                const SizedBox(height: 12),
                _InfoCard(
                  title: 'Hata',
                  text: duel.errorMessage!,
                  icon: Icons.error_outline,
                  accent: AppColors.errorRed,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String? roomCode;
  final String? category;
  final String? mode;
  final String? status;

  const _HeaderCard({
    required this.roomCode,
    required this.category,
    required this.mode,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      tint: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
              color: AppColors.actionBlue.withValues(alpha: 0.16),
            ),
            child: const Icon(Icons.sports_kabaddi_rounded, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roomCode == null || roomCode!.trim().isEmpty
                      ? 'Oda'
                      : 'Oda: ${roomCode!.trim()}',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(category ?? '-')} • ${(mode ?? '-')} • ${(status ?? '-')}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String text;
  final IconData icon;
  final Color accent;

  const _InfoCard({
    required this.title,
    required this.text,
    required this.icon,
    this.accent = AppColors.primaryBlue,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      tint: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
              color: accent.withValues(alpha: 0.14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int? roundNumber;
  final String? questionText;
  final DateTime? deadlineAt;
  final bool locked;
  final List<String> options;
  final String? correctAnswer;
  final String? selectedOption;
  final ValueChanged<String> onSelect;

  const _QuestionCard({
    required this.roundNumber,
    required this.questionText,
    required this.deadlineAt,
    required this.locked,
    required this.options,
    required this.correctAnswer,
    required this.selectedOption,
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

    if (locked) {
      if (correct.isNotEmpty && option.trim().toLowerCase() == correct.toLowerCase()) {
        return AnswerState.correct;
      }
      if (selected.isNotEmpty && option.trim().toLowerCase() == selected.toLowerCase()) {
        return AnswerState.wrong;
      }
      return AnswerState.disabled;
    }

    if (selected.isNotEmpty) {
      if (option.trim().toLowerCase() == selected.toLowerCase()) {
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
        if (locked) {
          return _pill('Bitti', AppColors.textMuted);
        }

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

class _ScoreboardCard extends StatelessWidget {
  final String? myPlayerId;
  final List<DuelPlayerState> players;
  final String? winnerUsername;
  final bool finished;

  const _ScoreboardCard({
    required this.myPlayerId,
    required this.players,
    required this.winnerUsername,
    required this.finished,
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
              const Text(
                'Skor',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (finished && winnerUsername != null && winnerUsername!.trim().isNotEmpty)
                Text(
                  'Kazanan: ${winnerUsername!.trim()}',
                  style: const TextStyle(
                    color: AppColors.yellow,
                    fontWeight: FontWeight.w900,
                  ),
                )
              else if (finished)
                const Text(
                  'Berabere',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (players.isEmpty)
            const Text(
              'Oyuncu bilgisi yok.',
              style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
            )
          else
            for (final p in players) _playerRow(p),
          if (finished) ...[
            const SizedBox(height: 10),
            const Text(
              'Kupa güncellemesi maç sonunda uygulanır (profilde görebilirsin).',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _playerRow(DuelPlayerState p) {
    final isMe = (myPlayerId ?? '').trim().isNotEmpty &&
        (p.playerId ?? '').trim().isNotEmpty &&
        (p.playerId ?? '').trim() == (myPlayerId ?? '').trim();
    final name = (p.username ?? '').trim().isEmpty ? '-' : p.username!.trim();
    final label = isMe ? '$name (Sen)' : name;
    final color = isMe ? AppColors.primaryBlue : AppColors.textDark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (!p.connected)
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.wifi_off_rounded, size: 16, color: AppColors.textMuted),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.borderLight),
              color: AppColors.surface2.withValues(alpha: 0.5),
            ),
            child: Text(
              '${p.score}',
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
