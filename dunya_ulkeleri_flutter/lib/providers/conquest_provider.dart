import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/navigation.dart';
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

part 'conquest_provider/core.dart';
part 'conquest_provider/practice.dart';
part 'conquest_provider/vs_bot.dart';

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
  Timer? _roundTransitionTimer;

  /// Bir round içinde "ilk doğru cevap" kuralını uygulamak için.
  bool isWaitingForAnswer = false;

  /// UI'da son durum/round mesajı.
  String? lastRoundMessage;

  int correctCount = 0;
  int wrongCount = 0;
  int streak = 0;
  int remainingLives = ConquestPlayer.initialLives;

  String selectedContinentFilter = 'ALL';

  /// Aynı anda birden fazla tıklamayı engellemek için.
  bool isRoundLocked = false;

  final Random _random = Random();
  final GameService _gameService = GameService();
  bool _disposed = false;
  int _activeRoundToken = 0;

  // Tüm ülkeler (kıta filtresi değişince tekrar filtrelemek için).
  List<MapCountryModel> _allCountries = <MapCountryModel>[];

  @override
  void dispose() {
    _disposed = true;
    botTimer?.cancel();
    botTimer = null;
    _roundTransitionTimer?.cancel();
    _roundTransitionTimer = null;
    super.dispose();
  }

  void _emit() {
    if (_disposed) return;
    notifyListeners();
  }
}
