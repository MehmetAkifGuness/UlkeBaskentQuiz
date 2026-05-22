part of '../game_screen.dart';
extension _GameScreenStateBodyImpl on GameScreenState {
  Widget _buildBodyImpl(
    BuildContext context,
    GameProvider gameProvider,
    AuthProvider authProvider,
    dynamic status,
    bool isDaily,
    bool isEndless,
  ) {
    if (gameProvider.isLoading && status == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }
    if (status == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Hata")),
        body: const Center(
          child: Text(
            "Oyun yüklenirken hata oluştu veya bu kategoride soru yok.",
            style: TextStyle(color: AppColors.textDark),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isDaily
              ? "Skor: ${status.currentScore} | 🎯 Günün Görevi"
              : isEndless
              ? "Skor: ${status.currentScore} | ♾️ Sonsuz Mod"
              : "Skor: ${status.currentScore} | ❤️ Can: ${status.remainingLives}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            Provider.of<SettingsProvider>(
              context,
              listen: false,
            ).triggerButtonVibration();
            final shouldPop = await _onWillPop();
            if (!context.mounted) return;
            if (shouldPop) {
              Navigator.of(context).pop();
            }
          },
        ),
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
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          children: [
                            Text(
                              status.message ?? "Oyun Devam Ediyor...",
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface2.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: AppColors.borderLight,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue.withValues(alpha: 
                                      0.12,
                                    ),
                                    blurRadius: 14,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.timer_outlined,
                                    color: AppColors.primaryBlue,
                                    size: 26,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    gameProvider.formattedTime,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                      fontFamily: 'Courier',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (isEndless)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: Colors.redAccent,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.redAccent,
                                          size: 20,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          "Tek Yanlışta Biter!",
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      "👑 Rekor: ${status.ghostScore == 0 ? 'Yok' : status.ghostScore}",
                                      style: const TextStyle(
                                        color: AppColors.brown,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (status.ghostScore != null &&
                                status.totalQuestions != null)
                              if (status.ghostScore == 0)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Kalan Soru: ${status.remainingQuestions}",
                                      style: const TextStyle(
                                        color: AppColors.textDark,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Row(
                                      children: const [
                                        Icon(
                                          Icons.emoji_events,
                                          color: AppColors.yellow,
                                          size: 20,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          "İlk rekoru sen kır!",
                                          style: TextStyle(
                                            color: AppColors.yellow,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              else
                                ScoreProgressWidget(
                                  ghostName: status.ghostName!,
                                  ghostScore: status.ghostScore!,
                                  currentScore: status.currentScore,
                                  totalQuestions: status.totalQuestions!,
                                  remainingQuestions:
                                      status.remainingQuestions ?? 0,
                                ),
                          ],
                        ),
                        Expanded(
                          child: Center(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.surface2.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.borderLight,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue.withValues(alpha: 
                                      0.10,
                                    ),
                                    blurRadius: 18,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.public,
                                    color: AppColors.primaryBlue,
                                    size: 44,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    status.questionText ??
                                        "${status.countryName} ülkesinin başkenti neresidir?",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        _buildAnswerList(
                          context,
                          gameProvider,
                          authProvider,
                          status,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                if (gameProvider.isLoading && status != null)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface2.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withValues(alpha: 0.12),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: const CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }}
