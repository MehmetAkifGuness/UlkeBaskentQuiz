// lib/providers/game_provider.dart
import 'dart:async';
import 'dart:convert'; // 🚨 JSON işlemleri için
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🚨 Hafıza için
import '../models/game_status_model.dart';
import '../services/game_service.dart';
import 'package:audioplayers/audioplayers.dart'; // 🚨 Ses için eklendi
import 'package:vibration/vibration.dart'; // 🚨 YENİ EKLENDİ (Gerçek titreşim motoru için)

class GameProvider with ChangeNotifier {
  final GameService _gameService = GameService();
  GameStatusModel? _status;
  bool _isLoading = false;

  bool _showResult = false;
  String? _selectedAnswer;
  String? _correctAnswer;

  // ⏱️ --- KRONOMETRE DEĞİŞKENLERİ ---
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _uiTimer;
  String _formattedTime = "00.00";
  String get formattedTime => _formattedTime;
  // ----------------------------------

  GameStatusModel? get status => _status;
  bool get isLoading => _isLoading;
  bool get showResult => _showResult;
  String? get selectedAnswer => _selectedAnswer;
  String? get correctAnswer => _correctAnswer;

  // 🚨 YENİ EKLENDİ: Uygulama açıldığında kayıtlı oyunu otomatik bul!
  GameProvider() {
    _loadSavedGame();
  }

  // 🚨 YENİ EKLENDİ: Cihaz hafızasındaki yarım kalan oyunu yükler
  Future<void> _loadSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGame = prefs.getString('saved_game_status');
    if (savedGame != null) {
      try {
        _status = GameStatusModel.fromJson(jsonDecode(savedGame));
        notifyListeners(); // Arayüze "Devam Et butonunu göster" der
      } catch (e) {
        print("Kayıtlı oyun yüklenirken hata: $e");
      }
    }
  }

  // 🚨 YENİ EKLENDİ: O anki durumu telefona kaydeder (Oyun bittiyse siler)
  Future<void> _saveGameLocally() async {
    final prefs = await SharedPreferences.getInstance();
    if (_status == null || _status?.finished == true) {
      await prefs.remove('saved_game_status'); // Oyun bitmişse hafızadan sil
    } else {
      await prefs.setString(
        'saved_game_status',
        jsonEncode(_status!.toJson()),
      ); // Devam ediyorsa kaydet
    }
  }

  // ⏱️ Kronometreyi Başlatır (Salise hesaplamalı)
  void _startStopwatch() {
    _stopwatch.reset();
    _stopwatch.start();
    _uiTimer?.cancel();

    // Ekranda saliselerin aktığını göstermek için 30 milisaniyede bir UI güncellenir
    _uiTimer = Timer.periodic(Duration(milliseconds: 30), (timer) {
      final elapsed = _stopwatch.elapsedMilliseconds;
      int seconds = (elapsed / 1000).truncate();
      int ms = (elapsed % 1000 ~/ 10); // 2 haneli salise (00-99)

      _formattedTime =
          '${seconds.toString().padLeft(2, '0')}.${ms.toString().padLeft(2, '0')}';
      notifyListeners();
    });
  }

  // ⏱️ Kronometreyi Durdurur
  void _stopStopwatch() {
    _stopwatch.stop();
    _uiTimer?.cancel();
  }

  Future<void> startNewGame(String token, String category, String mode) async {
    _isLoading = true;
    _showResult = false;
    notifyListeners();
    try {
      _status = await _gameService.startGame(token, category, mode);
      await _saveGameLocally(); // 🚨 YENİ OYUN BAŞLADI, HAFIZAYA YAZ!
      _startStopwatch();
    } catch (e) {
      print("Oyun başlatma hatası: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🚨 Parametrelere playSound ve vibrate eklendi
  Future<void> sendGuess(
    String token,
    String capital, {
    bool playSound = true,
    bool vibrate = true,
  }) async {
    if (_status?.sessionId == null || _showResult) return;

    _stopStopwatch();
    double timeTakenInSeconds = _stopwatch.elapsedMilliseconds / 1000.0;

    _selectedAnswer = capital;
    _showResult = true;
    notifyListeners();

    try {
      var nextStatus = await _gameService.makeGuess(
        token,
        _status!.sessionId!,
        capital,
        timeTakenInSeconds,
      );

      _correctAnswer = nextStatus.lastCorrectAnswer;
      notifyListeners();

      // 🚨 SES VE TİTREŞİM TETİKLEME ALANI BAŞLANGICI 🚨
      bool isCorrect = (_selectedAnswer == _correctAnswer);

      if (playSound) {
        final player = AudioPlayer();
        if (isCorrect) {
          // Doğru bilirse correct.mp3 çal
          player.play(AssetSource('sounds/correct.mp3'));
        } else {
          // Yanlış bilirse wrong.mp3 çal
          player.play(AssetSource('sounds/wrong.mp3'));
        }
      }

      // 🚨 YENİ TİTREŞİM MANTIĞI: VIBRATION PAKETİ KULLANILDI 🚨
      if (vibrate) {
        // Cihazda gerçekten titreşim motoru var mı kontrol et
        bool? hasVibrator = await Vibration.hasVibrator();

        if (hasVibrator == true) {
          if (isCorrect) {
            // Doğru cevapta 100 milisaniyelik kısa, tatlı titreşim
            Vibration.vibrate(duration: 100);
          } else {
            // Yanlış cevapta 400 milisaniyelik belirgin, uyarıcı titreşim
            Vibration.vibrate(duration: 400);
          }
        }
      }
      // 🚨 SES VE TİTREŞİM TETİKLEME ALANI BİTİŞİ 🚨

      await Future.delayed(Duration(milliseconds: 1500));

      _status = nextStatus;
      _showResult = false;
      _selectedAnswer = null;
      _correctAnswer = null;

      await _saveGameLocally();

      if (_status?.finished == false) {
        _startStopwatch();
      }

      notifyListeners();
    } catch (e) {
      print("💥 FLUTTER HATASI (sendGuess): $e");
      _showResult = false;
      notifyListeners();
    }
  }

  void resetGame() {
    _status = null;
    _isLoading = false;
    _stopStopwatch();
    _formattedTime = "00.00";
    _saveGameLocally(); // 🚨 HAFIZADAN DA TEMİZLE!
    notifyListeners();
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }
}
