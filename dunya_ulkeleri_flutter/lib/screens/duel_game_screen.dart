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

part 'duel_game_screen/header_card.dart';
part 'duel_game_screen/info_card.dart';
part 'duel_game_screen/question_card.dart';
part 'duel_game_screen/scoreboard_card.dart';

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
                  selectedAnswerCorrect:
                      duel.myAnswerCorrectForRound(round?.roundNumber),
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
