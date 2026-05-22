part of '../conquest_bot_screen.dart';

class _ConquestBotScreenView extends StatelessWidget {
  final _ConquestBotScreenState state;

  const _ConquestBotScreenView({required this.state});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConquestProvider>();
    final err = provider.errorMessage;
    if (err == null || err.trim().isEmpty) {
      state._lastSnackMessage = null;
    } else {
      state._showSnackOnce(err);
    }

    final isStarted = provider.isGameActive && provider.isVsBotMode;
    final targetName = provider.targetCountry?.name ?? '—';
    final total = provider.playableCountries.length;
    final conquered = provider.conqueredIsoCodes.length;

    final human = provider.humanPlayer;
    final bot = provider.botPlayer;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Botlara Karşı Dünya Fethi')),
      body: GeoBackground(
        safeArea: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            if (!isStarted) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Maç Ayarları',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: state._playerNameController,
                        decoration: InputDecoration(
                          labelText: 'Oyuncu Adı',
                          labelStyle: const TextStyle(
                            color: AppColors.textMuted,
                          ),
                          filled: true,
                          fillColor: AppColors.surface2.withValues(alpha: 0.55),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.borderLight,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.borderLight,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: AppColors.primaryBlue.withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Kıta Seçimi',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      state._continentPickerBar(
                        context,
                        enabled: !provider.isLoading,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: provider.isLoading
                              ? null
                              : () => state._startMatch(provider),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text(
                            'BAŞLA',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              state._difficultyPickerBar(context, enabled: !provider.isLoading),
              const SizedBox(height: 10),
              state._colorPickerBar(
                title: 'Oyuncu Rengi',
                options: _ConquestBotScreenState._playerColors,
                selected: state._selectedPlayerColor,
                enabled: !provider.isLoading,
                onChanged: state._setSelectedPlayerColor,
              ),
              const SizedBox(height: 10),
              state._colorPickerBar(
                title: 'Bot Rengi',
                options: _ConquestBotScreenState._botColors,
                selected: state._selectedBotColor,
                enabled: !provider.isLoading,
                onChanged: state._setSelectedBotColor,
              ),
              const SizedBox(height: 10),
            ] else ...[
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
                        'Haritada hedef ülkeyi bul ve botlardan önce dokun.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _ScorePill(
                              title: human?.name ?? 'Sen',
                              score: human?.score ?? provider.correctCount,
                              color: human?.color ?? state._selectedPlayerColor,
                              conquered: human?.conqueredCount ?? 0,
                              lives: human?.remainingLives ?? 3,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ScorePill(
                              title: bot?.name ?? 'Bot',
                              score: bot?.score ?? 0,
                              color: bot?.color ?? state._selectedBotColor,
                              conquered: bot?.conqueredCount ?? 0,
                              lives: bot?.remainingLives ?? 3,
                            ),
                          ),
                        ],
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
                            human?.color ?? state._selectedPlayerColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (provider.botTimer != null &&
                          provider.isWaitingForAnswer)
                        const Text(
                          'Bot düşünüyor...',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      if ((provider.lastRoundMessage ?? '').trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            provider.lastRoundMessage!,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: provider.resetGame,
                              child: const Text(
                                'Sıfırla',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: provider.stopBotMatch,
                              child: const Text(
                                'Bitir',
                                style: TextStyle(fontWeight: FontWeight.w900),
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
            ],
            Expanded(
              child: _ConquestBotMapSection(
                state: state,
                provider: provider,
                isStarted: isStarted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

