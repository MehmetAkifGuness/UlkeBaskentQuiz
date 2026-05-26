part of '../conquest_provider.dart';

extension ConquestProviderCore on ConquestProvider {
  void _cancelRoundTransitionTimer() {
    _roundTransitionTimer?.cancel();
    _roundTransitionTimer = null;
  }

  void _scheduleNextTargetCountry() {
    if (!isGameActive) return;

    _cancelRoundTransitionTimer();
    isRoundLocked = true;
    _roundTransitionTimer = Timer(const Duration(milliseconds: 900), () {
      if (_disposed) return;
      _roundTransitionTimer = null;
      if (!isGameActive) return;
      isRoundLocked = false;
      pickNextTargetCountry();
      _emit();
    });
  }

  void setContinentFilter(String continent) {
    if (selectedContinentFilter == continent) return;

    final hasContinent = _allCountries.any(
      (c) => (c.continent ?? '').trim().isNotEmpty,
    );
    if (!hasContinent && continent != 'ALL') {
      errorMessage =
          'Kıta filtresi için ülke verilerinde kıta bilgisi bulunmalı.';
      selectedContinentFilter = 'ALL';
      _applyContinentFilter('ALL');
      resetGame();
      return;
    }

    selectedContinentFilter = continent;
    _applyContinentFilter(continent);
    resetGame();
  }

  void pickNextTargetCountry() {
    if (!isGameActive) return;
    _cancelRoundTransitionTimer();

    final remaining = playableCountries
        .where((c) => !conqueredIsoCodes.contains(c.isoCode))
        .toList(growable: false);

    if (remaining.isEmpty) {
      // Tüm ülkeler fethedildi.
      isGameActive = false;
      targetCountry = null;
      isWaitingForAnswer = false;
      cancelBotTimer();
      final endMessage = isVsBotMode
          ? 'Maç bitti! Tüm ülkeler fethedildi.'
          : 'Tebrikler! Tüm ülkeleri fethettin.';
      errorMessage = endMessage;
      lastRoundMessage = endMessage;
      return;
    }

    // Aynı ülke tekrar hedef olmasın: fethedilenleri zaten dışarıda tutuyoruz.
    targetCountry = remaining[_random.nextInt(remaining.length)];
    _activeRoundToken += 1;

    // Her yeni hedef ülke/soru başladığında canları yenile.
    remainingLives = ConquestPlayer.initialLives;
    humanPlayer?.remainingLives = ConquestPlayer.initialLives;
    botPlayer?.remainingLives = ConquestPlayer.initialLives;

    // ADIM 4: VS Bot modunda yeni round açılınca bot cevabını planla.
    if (isVsBotMode) {
      isWaitingForAnswer = true;
      roundWinner = null;
      scheduleBotAnswer(roundToken: _activeRoundToken, isRetry: false);
    } else {
      isWaitingForAnswer = false;
    }
  }

  Future<void> handleCountryTap(Map<String, dynamic> mapProperties) async {
    if (!isGameActive || isRoundLocked) return;
    if (remainingLives <= 0) return;

    final target = targetCountry;
    if (target == null) return;

    isRoundLocked = true;
    errorMessage = null;
    _emit();

    try {
      // Haritadan gelen seçimi her zaman tüm ülke havuzunda eşleştiriyoruz.
      // Böylece kıta filtresi dışına dokununca "dışında" mesajını verebiliriz.
      final matcher = CountryMatchService(availableCountries: _allCountries);
      final tapped = matcher.matchFromMapProperties(mapProperties);

      if (tapped == null) {
        wrongCount += 1;
        streak = 0;
        errorMessage = 'Bu bölge oyun verilerinde yok.';
        return;
      }

      // Kıta filtresi seçiliyse: filtre dışına dokunmayı engelle.
      if (selectedContinentFilter != 'ALL') {
        final continent = (tapped.continent ?? '').trim();
        if (continent.isEmpty) {
          errorMessage =
              'Kıta filtresi için ülke verilerinde kıta bilgisi bulunmalı.';
          return;
        }
        if (continent != selectedContinentFilter) {
          errorMessage = 'Bu ülke seçili kıta filtresinin dışında.';
          return;
        }
      }

      if (isCountryConquered(tapped.isoCode)) {
        errorMessage = 'Bu ülkeyi zaten fethettin.';
        return;
      }

      if (isCorrectCountry(tapped)) {
        conqueredIsoCodes.add(tapped.isoCode);
        conqueredCountryColors[tapped.isoCode] = playerColor;
        correctCount += 1;
        streak += 1;

        _scheduleNextTargetCountry();

        // Oyun bitti mesajı pickNextTargetCountry içinde ayarlanır.
      } else {
        wrongCount += 1;
        streak = 0;
        errorMessage = 'Yanlış ülke, tekrar dene.';

        remainingLives = max(0, remainingLives - 1);
        if (remainingLives <= 0) {
          errorMessage = 'Canların bitti. Bu tur atlandı: ${target.name}';
          _scheduleNextTargetCountry();
          return;
        }

        // Kısa süreli görsel uyarı (UI isterse kullanır).
        wrongFlashIsoCode = tapped.isoCode;
        _clearWrongFlashLater();
      }
    } finally {
      isRoundLocked = _roundTransitionTimer != null;
      _emit();
    }
  }

  bool isCorrectCountry(MapCountryModel tappedCountry) {
    final target = targetCountry;
    if (target == null) return false;
    return tappedCountry.isoCode == target.isoCode;
  }

  bool isCountryConquered(String isoCode) => conqueredIsoCodes.contains(isoCode);

  double get progressRatio {
    if (playableCountries.isEmpty) return 0;
    return conqueredIsoCodes.length / playableCountries.length;
  }

  void _applyContinentFilter(String continent) {
    if (continent == 'ALL') {
      playableCountries = List<MapCountryModel>.from(_allCountries);
      return;
    }

    playableCountries = _allCountries
        .where((c) => (c.continent ?? '').trim() == continent)
        .toList(growable: false);
  }

  void _conquerCountry({required String isoCode, required Color color}) {
    final key = isoCode.trim();
    if (key.isEmpty) return;
    conqueredIsoCodes.add(key);
    conqueredCountryColors[key] = color;
  }

  void _setMode(ConquestGameMode mode) {
    currentMode = mode;
    isVsBotMode = mode == ConquestGameMode.vsBot;
  }

  void _clearWrongFlashLater() {
    Future<void>.delayed(const Duration(milliseconds: 650)).then((_) {
      if (_disposed) return;
      wrongFlashIsoCode = null;
      _emit();
    });
  }

  String? _readAuthToken() {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return null;

    try {
      return Provider.of<AuthProvider>(ctx, listen: false).token;
    } catch (_) {
      return null;
    }
  }

  String? _toEnglishContinent(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;

    return switch (v) {
      'Avrupa' => 'Europe',
      'Asya' => 'Asia',
      'Afrika' => 'Africa',
      'Kuzey Amerika' => 'North America',
      'Güney Amerika' => 'South America',
      'Okyanusya' => 'Oceania',
      _ => v,
    };
  }

  List<MapCountryModel> _fallbackCountries() {
    // ADIM 3: Endpoint/veri hazır değilse minimum örnek veri ile pratik modu çalışsın.
    // TODO: Backend'den ISO + kıta + başkent ile tam liste getirilecek.
    return const <MapCountryModel>[
      MapCountryModel(
        isoCode: 'TUR',
        name: 'Türkiye',
        continent: 'Asia',
        capital: 'Ankara',
      ),
      MapCountryModel(
        isoCode: 'USA',
        name: 'United States',
        continent: 'North America',
        capital: 'Washington, D.C.',
      ),
      MapCountryModel(
        isoCode: 'DEU',
        name: 'Germany',
        continent: 'Europe',
        capital: 'Berlin',
      ),
      MapCountryModel(
        isoCode: 'FRA',
        name: 'France',
        continent: 'Europe',
        capital: 'Paris',
      ),
    ];
  }
}
