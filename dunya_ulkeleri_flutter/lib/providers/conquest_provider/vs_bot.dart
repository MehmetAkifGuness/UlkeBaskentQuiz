part of '../conquest_provider.dart';

extension ConquestProviderVsBot on ConquestProvider {
  // -----------------------------
  // ADIM 4: Botlara karşı VS modu
  // -----------------------------

  void configureBotMatch({
    required Color playerColor,
    required Color botColor,
    required BotDifficulty difficulty,
    required String playerName,
  }) {
    // Oyun açıksa önce güvenli şekilde durdur.
    stopBotMatch();

    _setMode(ConquestGameMode.vsBot);
    this.playerColor = playerColor;
    selectedBotDifficulty = difficulty;

    final effectiveName = playerName.trim().isEmpty ? 'Sen' : playerName.trim();
    humanPlayer = ConquestPlayer.human(
      id: 'human',
      name: effectiveName,
      color: playerColor,
    );
    botPlayer = ConquestPlayer.bot(
      id: 'bot',
      name: difficulty.displayName,
      color: botColor,
      difficulty: difficulty,
    );

    // Yeni maç konfigürasyonu: skorları ve fetihleri sıfırla.
    resetGame();
  }

  void startBotMatch() {
    _setMode(ConquestGameMode.vsBot);

    if (humanPlayer == null || botPlayer == null) {
      errorMessage = 'Bot maçı başlatılamadı. Ayarları kontrol edin.';
      _emit();
      return;
    }

    if (playableCountries.isEmpty) {
      errorMessage = 'Oynanabilir ülke bulunamadı.';
      _emit();
      return;
    }

    errorMessage = null;
    lastRoundMessage = null;
    isGameActive = true;
    _cancelRoundTransitionTimer();
    pickNextTargetCountry();
    _emit();
  }

  void stopBotMatch() {
    cancelBotTimer();
    _cancelRoundTransitionTimer();
    isGameActive = false;
    isWaitingForAnswer = false;
    isRoundLocked = false;
    targetCountry = null;
    roundWinner = null;
    _emit();
  }

  void cancelBotTimer() {
    botTimer?.cancel();
    botTimer = null;
  }

  bool _areBothVsBotPlayersOutOfLives() {
    final humanLives = humanPlayer?.remainingLives ?? 0;
    final botLives = botPlayer?.remainingLives ?? 0;
    return humanLives <= 0 && botLives <= 0;
  }

  void _skipVsBotTargetBecauseNoLives() {
    final skipped = targetCountry;
    cancelBotTimer();
    isWaitingForAnswer = false;
    roundWinner = null;

    lastRoundMessage = skipped == null
        ? 'İki tarafın da canı bitti. Ülke atlandı.'
        : 'İki tarafın da canı bitti. ${skipped.name} atlandı.';

    _scheduleNextTargetCountry();
  }

  void scheduleBotAnswer({required int roundToken, required bool isRetry}) {
    if (!isGameActive || !isVsBotMode) return;
    if (roundToken != _activeRoundToken) return;

    cancelBotTimer();

    final diff = botPlayer?.difficulty ?? selectedBotDifficulty;
    final minMs = isRetry ? diff.minRetryDelayMs : diff.minAnswerDelayMs;
    final maxMs = isRetry ? diff.maxRetryDelayMs : diff.maxAnswerDelayMs;
    final span = (maxMs - minMs).clamp(0, 9999999);
    final delayMs = minMs + (span == 0 ? 0 : _random.nextInt(span + 1));

    botTimer = Timer(
      Duration(milliseconds: delayMs),
      () => handleBotAnswer(roundToken: roundToken),
    );
  }

  void handleBotAnswer({required int roundToken}) {
    if (!isGameActive || !isVsBotMode) return;
    if (roundToken != _activeRoundToken) return;
    if (!isWaitingForAnswer) return;

    final bot = botPlayer;
    final target = targetCountry;
    if (bot == null || target == null) return;
    if (bot.remainingLives <= 0) return;

    // Bot cevap verdi (timer tek seferlik).
    cancelBotTimer();

    final diff = bot.difficulty ?? selectedBotDifficulty;
    final willBeCorrect = _random.nextDouble() <= diff.correctAnswerChance;

    if (!willBeCorrect) {
      bot.remainingLives = max(0, bot.remainingLives - 1);
      lastRoundMessage = bot.remainingLives <= 0
          ? 'Bot bu tur için canlarını tüketti.'
          : 'Bot yanlış cevap verdi (-1 can). Şansın devam ediyor.';

      if (_areBothVsBotPlayersOutOfLives()) {
        _skipVsBotTargetBecauseNoLives();
        _emit();
        return;
      }

      // Bot, canı bitene kadar bu round'da denemeye devam edebilir.
      if (bot.remainingLives > 0) {
        scheduleBotAnswer(roundToken: roundToken, isRetry: true);
      }

      _emit();
      return;
    }

    // Bot doğru bildi: bu round bitti.
    isWaitingForAnswer = false;
    roundWinner = bot;

    _conquerCountry(isoCode: target.isoCode, color: bot.color);
    bot.score += 1;
    bot.conqueredCount += 1;

    lastRoundMessage = 'Bot daha hızlı bildi: ${target.name}';

    _scheduleNextTargetCountry();
    _emit();
  }

  Future<void> handleHumanCountryTap(Map<String, dynamic> mapProperties) async {
    if (!isGameActive || !isVsBotMode || isRoundLocked) return;

    final target = targetCountry;
    final human = humanPlayer;
    if (target == null || human == null) return;
    if (human.remainingLives <= 0) return;

    if (!isWaitingForAnswer) return;

    isRoundLocked = true;
    errorMessage = null;
    _emit();

    try {
      final matcher = CountryMatchService(availableCountries: _allCountries);
      final tapped = matcher.matchFromMapProperties(mapProperties);

      if (tapped == null) {
        wrongCount += 1;
        streak = 0;
        errorMessage = 'Bu bölge oyun verilerinde yok.';
        lastRoundMessage = errorMessage;
        return;
      }

      // Kıta filtresi seçiliyse: filtre dışına dokunmayı engelle.
      if (selectedContinentFilter != 'ALL') {
        final continent = (tapped.continent ?? '').trim();
        if (continent.isEmpty) {
          errorMessage =
              'Kıta filtresi için ülke verilerinde kıta bilgisi bulunmalı.';
          lastRoundMessage = errorMessage;
          return;
        }
        if (continent != selectedContinentFilter) {
          errorMessage = 'Bu ülke seçili kıta filtresinin dışında.';
          lastRoundMessage = errorMessage;
          return;
        }
      }

      if (isCountryConquered(tapped.isoCode)) {
        errorMessage = 'Bu ülke zaten fethedildi.';
        lastRoundMessage = errorMessage;
        return;
      }

      if (tapped.isoCode == target.isoCode) {
        // İnsan daha hızlı bildi: bot timer'ını iptal et ve round'u kapat.
        cancelBotTimer();
        isWaitingForAnswer = false;
        roundWinner = human;

        _conquerCountry(isoCode: tapped.isoCode, color: human.color);
        human.score += 1;
        human.conqueredCount += 1;

        correctCount += 1;
        streak += 1;

        lastRoundMessage = 'Sen daha hızlı bildin!';

        _scheduleNextTargetCountry();
      } else {
        wrongCount += 1;
        streak = 0;
        errorMessage = 'Yanlış ülke, tekrar dene.';
        lastRoundMessage = errorMessage;

        human.remainingLives = max(0, human.remainingLives - 1);
        if (human.remainingLives <= 0) {
          lastRoundMessage = 'Sen bu tur için canlarını tükettin.';
          if (_areBothVsBotPlayersOutOfLives()) {
            _skipVsBotTargetBecauseNoLives();
          }
        } else {
          wrongFlashIsoCode = tapped.isoCode;
          _clearWrongFlashLater();
        }
      }
    } catch (e) {
      errorMessage = errorMessageFrom(e);
      lastRoundMessage = errorMessage;
    } finally {
      isRoundLocked = false;
    _emit();
    }
  }
}
