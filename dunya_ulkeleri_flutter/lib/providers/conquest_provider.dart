import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/bot_difficulty.dart';
import '../models/conquest_game_mode.dart';
import '../models/conquest_player.dart';
import '../models/dictionary_model.dart';
import '../models/map_country_model.dart';
import '../providers/auth_provider.dart';
import '../services/country_match_service.dart';
import '../services/game_service.dart';
import '../services/iso_country_service.dart';
import '../utils/error_message_utils.dart';

class ConquestProvider with ChangeNotifier {
  // ADIM 3-4: Fetih modları local state'i.
  // - practice: Tek oyunculu pratik
  // - vsBot: Botlara karşı local simülasyon (Timer tabanlı)
  //
  // Not: Bu adımda backend GameSession / WebSocket / gerçek zamanlı multiplayer yok.

  ConquestGameMode currentMode = ConquestGameMode.practice;

  /// Eski implementasyonla uyumluluk için ayrıca flag tutuyoruz.
  /// (Authoritative olan değer currentMode’dur.)
  bool isVsBotMode = false;

  bool isGameActive = false;
  bool isLoading = false;
  String? errorMessage;

  /// Bu turda hedef ülke (oyuncuya gösterilen gerçek model).
  MapCountryModel? targetCountry;

  /// Kıta filtresine göre oynanabilir ülke listesi.
  List<MapCountryModel> playableCountries = <MapCountryModel>[];

  /// Fethedilen ülke anahtarları (tercihen ISO3; bulunamazsa ülke adı fallback).
  final Set<String> conqueredIsoCodes = <String>{};

  /// Haritada ülke boyama altyapısı (fetih oyununda da kullanılacak).
  final Map<String, Color> conqueredCountryColors = <String, Color>{};

  /// Oyuncu rengi.
  Color playerColor = Colors.blue;

  // -----------------------------
  // ADIM 4: VS Bot state alanları
  // -----------------------------

  BotDifficulty selectedBotDifficulty = BotDifficulty.medium;
  ConquestPlayer? humanPlayer;
  ConquestPlayer? botPlayer;

  /// Round'u ilk kim kazandı? (İlk doğru cevap)
  ConquestPlayer? roundWinner;

  /// Bot cevap simülasyonu için timer.
  Timer? botTimer;

  /// Bir round içinde "ilk doğru cevap" kuralını uygulamak için.
  bool isWaitingForAnswer = false;

  /// UI'da son durum/round mesajı.
  String? lastRoundMessage;

  int correctCount = 0;
  int wrongCount = 0;
  int streak = 0;

  String selectedContinentFilter = 'ALL';

  /// Aynı anda birden fazla tıklamayı engellemek için.
  bool isRoundLocked = false;

  /// Yanlış seçilen ülkeyi kısa süreli vurgulamak için (UI isterse kullanır).
  String? wrongFlashIsoCode;

  final Random _random = Random();
  final GameService _gameService = GameService();
  bool _disposed = false;

  // Tüm ülkeler (kıta filtresi değişince tekrar filtrelemek için).
  List<MapCountryModel> _allCountries = <MapCountryModel>[];

  Future<void> initializePracticeMode() async {
    if (isLoading) return;

    // ADIM 3: Bu ekran tek oyunculu pratik içindir.
    _setMode(ConquestGameMode.practice);
    cancelBotTimer(); // Güvenlik: VS Bot ekranından kalan timer varsa iptal et.
    isWaitingForAnswer = false;
    roundWinner = null;
    lastRoundMessage = null;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

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
      notifyListeners();
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
      notifyListeners();
      return;
    }

    errorMessage = null;
    isGameActive = true;
    pickNextTargetCountry();
    notifyListeners();
  }

  void stopGame() {
    cancelBotTimer(); // Güvenlik: bot timer'ı varsa durdur.
    isGameActive = false;
    isWaitingForAnswer = false;
    isRoundLocked = false;
    targetCountry = null;
    roundWinner = null;
    notifyListeners();
  }

  void resetGame() {
    cancelBotTimer();
    isRoundLocked = false;
    targetCountry = null;
    conqueredIsoCodes.clear();
    conqueredCountryColors.clear();
    correctCount = 0;
    wrongCount = 0;
    streak = 0;
    wrongFlashIsoCode = null;
    isWaitingForAnswer = false;
    roundWinner = null;
    errorMessage = null;
    lastRoundMessage = null;

    // VS Bot maçında oyuncu skorlarını da sıfırla (konfigürasyon kalsın).
    humanPlayer?.score = 0;
    humanPlayer?.conqueredCount = 0;
    botPlayer?.score = 0;
    botPlayer?.conqueredCount = 0;

    // Oyun aktifse yeni hedef seç.
    if (isGameActive) {
      pickNextTargetCountry();
    }

    notifyListeners();
  }

  void setPlayerColor(Color color) {
    playerColor = color;
    notifyListeners();
  }

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
      notifyListeners();
      return;
    }

    if (playableCountries.isEmpty) {
      errorMessage = 'Oynanabilir ülke bulunamadı.';
      notifyListeners();
      return;
    }

    errorMessage = null;
    lastRoundMessage = null;
    isGameActive = true;
    pickNextTargetCountry();
    notifyListeners();
  }

  void stopBotMatch() {
    cancelBotTimer();
    isGameActive = false;
    isWaitingForAnswer = false;
    isRoundLocked = false;
    targetCountry = null;
    roundWinner = null;
    notifyListeners();
  }

  void cancelBotTimer() {
    botTimer?.cancel();
    botTimer = null;
  }

  void scheduleBotAnswer() {
    if (!isGameActive || !isVsBotMode) return;

    cancelBotTimer();

    final diff = botPlayer?.difficulty ?? selectedBotDifficulty;
    final minMs = diff.minAnswerDelayMs;
    final maxMs = diff.maxAnswerDelayMs;
    final span = (maxMs - minMs).clamp(0, 9999999);
    final delayMs = minMs + (span == 0 ? 0 : _random.nextInt(span + 1));

    botTimer = Timer(
      Duration(milliseconds: delayMs),
      () => handleBotAnswer(),
    );
  }

  void handleBotAnswer() {
    if (!isGameActive || !isVsBotMode) return;
    if (!isWaitingForAnswer) return;

    final bot = botPlayer;
    final target = targetCountry;
    if (bot == null || target == null) return;

    // Bot cevap verdi (timer tek seferlik).
    cancelBotTimer();

    final diff = bot.difficulty ?? selectedBotDifficulty;
    final willBeCorrect = _random.nextDouble() <= diff.correctAnswerChance;

    if (!willBeCorrect) {
      // Basit kural: bot aynı round'da tekrar denemez.
      lastRoundMessage = 'Bot yanlış cevap verdi, şansın devam ediyor.';
      notifyListeners();
      return;
    }

    // Bot doğru bildi: bu round bitti.
    isWaitingForAnswer = false;
    roundWinner = bot;

    _conquerCountry(isoCode: target.isoCode, color: bot.color);
    bot.score += 1;
    bot.conqueredCount += 1;

    lastRoundMessage = 'Bot daha hızlı bildi: ${target.name}';

    pickNextTargetCountry();
    notifyListeners();
  }

  Future<void> handleHumanCountryTap(Map<String, dynamic> mapProperties) async {
    if (!isGameActive || !isVsBotMode || isRoundLocked) return;

    final target = targetCountry;
    final human = humanPlayer;
    if (target == null || human == null) return;

    if (!isWaitingForAnswer) return;

    isRoundLocked = true;
    errorMessage = null;
    notifyListeners();

    try {
      final matcher = CountryMatchService(availableCountries: _allCountries);
      final tapped = matcher.matchFromMapProperties(mapProperties);

      if (tapped == null) {
        wrongCount += 1;
        streak = 0;
        errorMessage = 'Bu ülke uygulama verileriyle eşleştirilemedi.';
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

        pickNextTargetCountry();
      } else {
        wrongCount += 1;
        streak = 0;
        errorMessage = 'Yanlış ülke, tekrar dene.';
        lastRoundMessage = errorMessage;

        wrongFlashIsoCode = tapped.isoCode;
        _clearWrongFlashLater();
      }
    } finally {
      isRoundLocked = false;
      notifyListeners();
    }
  }

  void setContinentFilter(String continent) {
    if (selectedContinentFilter == continent) return;

    final hasContinent = _allCountries.any(
      (c) => (c.continent ?? '').trim().isNotEmpty,
    );
    if (!hasContinent && continent != 'ALL') {
      errorMessage = 'Kıta filtresi için ülke verilerinde kıta bilgisi bulunmalı.';
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

    // ADIM 4: VS Bot modunda yeni round açılınca bot cevabını planla.
    if (isVsBotMode) {
      isWaitingForAnswer = true;
      roundWinner = null;
      scheduleBotAnswer();
    } else {
      isWaitingForAnswer = false;
    }
  }

  Future<void> handleCountryTap(Map<String, dynamic> mapProperties) async {
    if (!isGameActive || isRoundLocked) return;

    final target = targetCountry;
    if (target == null) return;

    isRoundLocked = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Haritadan gelen seçimi her zaman tüm ülke havuzunda eşleştiriyoruz.
      // Böylece kıta filtresi dışına dokununca "dışında" mesajını verebiliriz.
      final matcher = CountryMatchService(availableCountries: _allCountries);
      final tapped = matcher.matchFromMapProperties(mapProperties);

      if (tapped == null) {
        wrongCount += 1;
        streak = 0;
        errorMessage = 'Bu ülke uygulama verileriyle eşleştirilemedi.';
        return;
      }

      // Kıta filtresi seçiliyse: filtre dışına dokunmayı engelle.
      if (selectedContinentFilter != 'ALL') {
        final continent = (tapped.continent ?? '').trim();
        if (continent.isEmpty) {
          errorMessage = 'Kıta filtresi için ülke verilerinde kıta bilgisi bulunmalı.';
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

        pickNextTargetCountry();

        // Oyun bitti mesajı pickNextTargetCountry içinde ayarlanır.
      } else {
        wrongCount += 1;
        streak = 0;
        errorMessage = 'Yanlış ülke, tekrar dene.';

        // Kısa süreli görsel uyarı (UI isterse kullanır).
        wrongFlashIsoCode = tapped.isoCode;
        _clearWrongFlashLater();
      }
    } finally {
      isRoundLocked = false;
      notifyListeners();
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
      notifyListeners();
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

  static String? _toEnglishContinent(String? value) {
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

  static List<MapCountryModel> _fallbackCountries() {
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

  @override
  void dispose() {
    _disposed = true;
    cancelBotTimer();
    super.dispose();
  }
}
