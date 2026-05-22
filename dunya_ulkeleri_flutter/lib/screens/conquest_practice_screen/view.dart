part of '../conquest_practice_screen.dart';

class _ConquestPracticeView extends StatelessWidget {
  final _ConquestPracticeScreenState state;

  const _ConquestPracticeView({required this.state});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConquestProvider>();
    final err = provider.errorMessage;
    if (err == null || err.trim().isEmpty) {
      state._lastSnackMessage = null;
    } else {
      state._showSnackOnce(err);
    }

    final targetName = provider.targetCountry?.name ?? '—';
    final total = provider.playableCountries.length;
    final conquered = provider.conqueredIsoCodes.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Dünya Fethi Pratik')),
      body: GeoBackground(
        safeArea: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            state._continentFilterBar(context),
            const SizedBox(height: 10),
            state._colorPickerBar(context),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(
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
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Haritada hedef ülkeyi bul ve dokun.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Fethedilen: $conquered / $total',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: provider.progressRatio.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: AppColors.borderLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          provider.playerColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: AppColors.errorRed,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Can: ${provider.remainingLives}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        for (int i = 0; i < 3; i++)
                          Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Icon(
                              i < provider.remainingLives
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 18,
                              color: AppColors.errorRed.withValues(
                                alpha:
                                    i < provider.remainingLives ? 0.95 : 0.32,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatPill(
                            label: 'Doğru',
                            value: '${provider.correctCount}',
                            accent: Colors.greenAccent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatPill(
                            label: 'Yanlış',
                            value: '${provider.wrongCount}',
                            accent: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatPill(
                            label: 'Seri',
                            value: '${provider.streak}',
                            accent: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                provider.isLoading ? null : provider.resetGame,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textDark,
                              side: const BorderSide(
                                color: AppColors.borderLight,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Sıfırla',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: provider.isGameActive
                              ? ElevatedButton(
                                  onPressed: provider.stopGame,
                                  child: const Text(
                                    'Bitir',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: provider.isLoading
                                      ? null
                                      : provider.startGame,
                                  child: const Text(
                                    'Başla',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _ConquestPracticeMapSection(
                state: state,
                provider: provider,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

