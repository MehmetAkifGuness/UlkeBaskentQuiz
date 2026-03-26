// lib/providers/game_provider.dart
import 'dart:async';
import 'dart:convert'; // 🚨 JSON işlemleri için
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🚨 Hafıza için
import '../models/game_status_model.dart';
import '../services/game_service.dart';
import 'package:audioplayers/audioplayers.dart'; // 🚨 Ses için eklendi
import 'package:vibration/vibration.dart'; // 🚨 YENİ EKLENDİ (Gerçek titreşim motoru için)
import '../main.dart'; // 🚨 YENİ: navigatorKey için eklendi

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

  GameProvider() {
    _loadSavedGame();
  }

  Future<void> _loadSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGame = prefs.getString('saved_game_status');
    if (savedGame != null) {
      try {
        _status = GameStatusModel.fromJson(jsonDecode(savedGame));
        notifyListeners();
      } catch (e) {
        print("Kayıtlı oyun yüklenirken hata: $e");
      }
    }
  }

  Future<void> _saveGameLocally() async {
    final prefs = await SharedPreferences.getInstance();
    if (_status == null || _status?.finished == true) {
      await prefs.remove('saved_game_status');
    } else {
      await prefs.setString('saved_game_status', jsonEncode(_status!.toJson()));
    }
  }

  void _startStopwatch() {
    _stopwatch.reset();
    _stopwatch.start();
    _uiTimer?.cancel();

    _uiTimer = Timer.periodic(Duration(milliseconds: 30), (timer) {
      final elapsed = _stopwatch.elapsedMilliseconds;
      int seconds = (elapsed / 1000).truncate();
      int ms = (elapsed % 1000 ~/ 10);

      _formattedTime =
          '${seconds.toString().padLeft(2, '0')}.${ms.toString().padLeft(2, '0')}';
      notifyListeners();
    });
  }

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
      await _saveGameLocally();
      _startStopwatch();
    } catch (e) {
      print("Oyun başlatma hatası: $e");
      // 🚨 İNTERNET KOPARSA BİLDİRİM GÖSTER
      if (navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: Text("Oyun başlatılamadı. İnternetinizi kontrol edin."),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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

      bool isCorrect = (_selectedAnswer == _correctAnswer);

      if (playSound) {
        final player = AudioPlayer();
        if (isCorrect) {
          player.play(AssetSource('sounds/correct.mp3'));
        } else {
          player.play(AssetSource('sounds/wrong.mp3'));
        }
      }

      if (vibrate) {
        bool? hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          if (isCorrect) {
            Vibration.vibrate(duration: 100);
          } else {
            Vibration.vibrate(duration: 400);
          }
        }
      }

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

      // 🚨 ÇÖZÜM 1: İnternet koptuğunda SARI BEKLEME BUTONUNU SIFIRLA
      _showResult = false;
      _selectedAnswer = null;
      _correctAnswer = null;

      // 🚨 ÇÖZÜM 2: Ekranda kırmızı bir hata mesajı göster
      if (navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          const SnackBar(
            content: Text("Bağlantı koptu, lütfen internetinizi kontrol edin."),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // 🚨 ÇÖZÜM 3: KRONOMETREYİ KALDIĞI YERDEN (SIFIRLAMADAN) DEVAM ETTİR
      if (_status?.finished == false) {
        _stopwatch.start(); // Sadece devam et komutu ver
        _uiTimer = Timer.periodic(Duration(milliseconds: 30), (timer) {
          final elapsed = _stopwatch.elapsedMilliseconds;
          int seconds = (elapsed / 1000).truncate();
          int ms = (elapsed % 1000 ~/ 10);
          _formattedTime =
              '${seconds.toString().padLeft(2, '0')}.${ms.toString().padLeft(2, '0')}';
          notifyListeners();
        });
      }

      notifyListeners();
    }
  }

  void resetGame() {
    _status = null;
    _isLoading = false;
    _stopStopwatch();
    _formattedTime = "00.00";
    _saveGameLocally();
    notifyListeners();
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  // 🚨 YENİ EKLENDİ: Ana sayfada çağrılacak olan senkronizasyon metodu
  Future<void> checkAndLoadActiveGame(String token) async {
    try {
      final activeGame = await _gameService.checkActiveGame(token);

      if (activeGame != null) {
        // Backend'de yarım kalan oyun varsa, hemen ekrana yükle!
        _status = activeGame;
        await _saveGameLocally();
      } else {
        // Backend'de oyun yoksa (bitmiş veya temizlenmişse), ve telefonda "Kaldığın yerden devam et" görünüyorsa onu SİL!
        if (_status != null) {
          _status = null;
          await _saveGameLocally();
        }
      }
      notifyListeners();
    } catch (e) {
      print("Senkronizasyon başarısız: $e");
    }
  }
}
