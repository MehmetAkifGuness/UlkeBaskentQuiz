part of '../conquest_provider.dart';

extension ConquestProviderPractice on ConquestProvider {
  Future<void> initializePracticeMode() async {
    if (isLoading) return;

    // ADIM 3: Bu ekran tek oyunculu pratik içindir.
    _setMode(ConquestGameMode.practice);
    cancelBotTimer(); // Güvenlik: VS Bot ekranından kalan timer varsa iptal et.
    _cancelRoundTransitionTimer();
    isWaitingForAnswer = false;
    roundWinner = null;
    lastRoundMessage = null;

    isLoading = true;
    errorMessage = null;
    _emit();

    try {
      final token = _readAuthToken();

      if (token == null) {
        // Token yoksa minimum demo veriyle çalışsın.
        _allCountries = _fallbackCountries();
        _applyContinentFilter(selectedContinentFilter);
        errorMessage =
            'Ülke verileri alınamadı (token yok). Geçici örnek liste kullanılıyor.';
        return;
      }

      final List<DictionaryModel> dictionary = await _gameService.getDictionary(
        token,
      );

      // ISO çeviri tablosunu hazırla (asset'ten okur). Hata olursa isim bazlı devam eder.
      try {
        await IsoCountryService.ensureLoaded();
      } catch (_) {}

      _allCountries = dictionary
          .map(
            (item) => MapCountryModel(
              // Backend tarafı şimdilik ISO vermiyor; harita ile eşleşme için TR ülke adından ISO3 üretmeye çalışıyoruz.
              // Üretilemezse fallback olarak ülke adını anahtar yapıyoruz.
              isoCode:
                  IsoCountryService.iso3FromTurkishName(item.countryName) ??
                      item.countryName.trim(),
              name: item.countryName.trim(),
              capital: item.capitalName.trim(),
              continent: _toEnglishContinent(item.continent),
              extra: const <String, dynamic>{'source': 'dictionary'},
            ),
          )
          .toList(growable: false);

      _applyContinentFilter(selectedContinentFilter);
      errorMessage = null;
    } catch (e) {
      // Backend erişilemezse uygulama crash etmesin.
      _allCountries = _fallbackCountries();
      _applyContinentFilter(selectedContinentFilter);
      errorMessage = errorMessageFrom(e);
    } finally {
      isLoading = false;
      _emit();
    }

    // TODO: Bot oyuncular aynı handleCountryTap benzeri cevap mantığıyla entegre edilecek.
    // TODO: Multiplayer için bu local state ileride backend GameSession state’i ile senkronize edilecek.
    // TODO: Round winner backend tarafından authoritative olarak belirlenecek.
    // TODO: Ülke fetih renkleri WebSocket üzerinden tüm oyunculara yayınlanacak.
    // TODO: Skorlar backend’e kaydedilecek.
  }

  void startGame() {
    if (playableCountries.isEmpty) {
      errorMessage = 'Oynanabilir ülke bulunamadı.';
      _emit();
      return;
    }

    errorMessage = null;
    isGameActive = true;
    _cancelRoundTransitionTimer();
    pickNextTargetCountry();
    _emit();
  }

  void stopGame() {
    cancelBotTimer(); // Güvenlik: bot timer'ı varsa durdur.
    _cancelRoundTransitionTimer();
    isGameActive = false;
    isWaitingForAnswer = false;
    isRoundLocked = false;
    targetCountry = null;
    roundWinner = null;
    _emit();
  }

  void resetGame() {
    cancelBotTimer();
    _cancelRoundTransitionTimer();
    isRoundLocked = false;
    targetCountry = null;
    conqueredIsoCodes.clear();
    conqueredCountryColors.clear();
    correctCount = 0;
    wrongCount = 0;
    streak = 0;
    remainingLives = ConquestPlayer.initialLives;
    wrongFlashIsoCode = null;
    isWaitingForAnswer = false;
    roundWinner = null;
    errorMessage = null;
    lastRoundMessage = null;

    // VS Bot maçında oyuncu skorlarını da sıfırla (konfigürasyon kalsın).
    humanPlayer?.score = 0;
    humanPlayer?.conqueredCount = 0;
    humanPlayer?.remainingLives = ConquestPlayer.initialLives;
    botPlayer?.score = 0;
    botPlayer?.conqueredCount = 0;
    botPlayer?.remainingLives = ConquestPlayer.initialLives;

    // Oyun aktifse yeni hedef seç.
    if (isGameActive) {
      pickNextTargetCountry();
    }

    _emit();
  }

  void setPlayerColor(Color color) {
    playerColor = color;
    _emit();
  }
}
