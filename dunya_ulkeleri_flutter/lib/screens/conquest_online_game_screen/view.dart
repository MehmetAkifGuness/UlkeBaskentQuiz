part of '../conquest_online_game_screen.dart';

class _ConquestOnlineGameView extends StatelessWidget {
  final _ConquestOnlineGameScreenState state;

  const _ConquestOnlineGameView({required this.state});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ConquestMultiplayerProvider>();

    final error = context.select<ConquestMultiplayerProvider, String?>(
      (p) => p.errorMessage,
    );
    if (error != null) {
      state._showSnackOnce(error);
      provider.clearError();
    }

    final isGameFinished = context.select<ConquestMultiplayerProvider, bool>(
      (p) => p.isGameFinished,
    );
    if (isGameFinished) {
      state._showFinishedDialog(provider);
    }

    final targetName = context.select<ConquestMultiplayerProvider, String?>(
          (p) => p.currentTargetName,
        ) ??
        '...';
    final room = (context.select<ConquestMultiplayerProvider, String?>(
              (p) => p.roomCode,
            ) ??
            '')
        .trim();
    final sessionState = context.select<ConquestMultiplayerProvider, ConquestSessionState?>(
      (p) => p.sessionState,
    );
    final status = (sessionState?.status ?? '').toUpperCase();
    final players = sessionState?.players ?? const [];
    final lastMessage = sessionState?.lastEventMessage?.trim();
    final isConnected = context.select<ConquestMultiplayerProvider, bool>(
      (p) => p.isConnected,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        Navigator.pushReplacement(
          context,
          FadePageRoute(
            page: const ConquestOnlineLobbyScreen(autoNavigateToGame: false),
          ),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Online Dünya Fethi'),
          actions: [
            IconButton(
              tooltip: 'Lobi',
              icon: const Icon(Icons.meeting_room_outlined),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  FadePageRoute(
                    page: const ConquestOnlineLobbyScreen(autoNavigateToGame: false),
                  ),
                );
              },
            ),
          ],
        ),
        body: GeoBackground(
          safeArea: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            physics: const BouncingScrollPhysics(),
            children: [
              GlassCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hedef: $targetName',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (room.isNotEmpty)
                          Text(
                            'Oda: $room',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (room.isNotEmpty) const SizedBox(width: 12),
                        Text(
                          status.isEmpty ? '...' : status,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          isConnected ? 'Bağlandı' : 'Bağlanıyor...',
                          style: TextStyle(
                            color: isConnected
                                ? Colors.greenAccent
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    if (lastMessage != null && lastMessage.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        lastMessage,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fetih',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (players.isEmpty)
                      const Text(
                        'Oyuncu listesi bekleniyor...',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            for (final p in players)
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: _ScoreChip(player: p),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bir ülkeye dokunarak cevabını gönder.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _ConquestOnlineGameMapSection(state: state, provider: provider),
              if (!isConnected)
                const Text(
                  'Bağlantı kuruluyor... (WebSocket)',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
