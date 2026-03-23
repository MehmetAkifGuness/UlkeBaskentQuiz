// lib/providers/game_provider.dart
import 'dart:async'; // ⏱️ Timer için gerekli
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🚨 YENİ EKLENDİ: Titreşim (HapticFeedback) için
import 'package:audioplayers/audioplayers.dart'; // 🚨 YENİ EKLENDİ: Ses efektleri için
import '../models/game_status_model.dart';
import '../services/game_service.dart';
import 'settings_provider.dart'; // 🚨 YENİ EKLENDİ: Ayarları okuyabilmek için
import '../main.dart'; // 🚨 YENİ EKLENDİ: navigatorKey üzerinden settingsProvider'a ulaşmak için
import 'package:provider/provider.dart';

class GameProvider with ChangeNotifier {
  final GameService _gameService = GameService();
  GameStatusModel? _status;
  bool _isLoading = false;

  bool _showResult = false;
  String? _selectedAnswer;
  String? _correctAnswer;

  // 🚨 YENİ EKLENDİ: Ses Oynatıcı Motoru
  final AudioPlayer _audioPlayer = AudioPlayer();

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

  // 🚨 YENİ EKLENDİ: Ses ve Titreşim Motoru (Ayarlara Bakarak Çalışır)
  // 🚨 YENİ EKLENDİ: Ses ve Titreşim Motoru (Ayarlara Bakarak Çalışır)
  Future<void> _playFeedback(bool isCorrect) async {
    try {
      // main.dart'taki navigatorKey sayesinde global ayarlara erişiyoruz
      final context = navigatorKey.currentContext;
      if (context == null) return;

      final settings = Provider.of<SettingsProvider>(context, listen: false);

      // Titreşim (Haptic Feedback) Açıksa
      if (settings.isVibrationEnabled) {
        if (isCorrect) {
          HapticFeedback.lightImpact(); // Doğruda hafif tıklama hissi
        } else {
          HapticFeedback.heavyImpact(); // Yanlışta güçlü ve tok bir hata titreşimi
        }
      }

      // Ses (Audio) Açıksa
      if (settings.isSoundEnabled) {
        // 🚨 DÜZELTME: Üst üste aynı sesin yutulmasını engellemek için önce oynatıcıyı sıfırlıyoruz.
        await _audioPlayer.stop();

        if (isCorrect) {
          await _audioPlayer.play(AssetSource('sounds/correct.mp3')); // Ting!
        } else {
          await _audioPlayer.play(AssetSource('sounds/wrong.mp3')); // Bzz!
        }
      }
    } catch (e) {
      print("Ses/Titreşim oynatılırken hata: $e");
    }
  }

  Future<void> startNewGame(String token, String category, String mode) async {
    // 🚨 YENİ: mode eklendi
    _isLoading = true;
    _showResult = false;
    notifyListeners();
    try {
      _status = await _gameService.startGame(token, category, mode); // 🚨 YENİ
      _startStopwatch(); // ⏱️ OYUN BAŞLADI, SÜREYİ BAŞLAT
    } catch (e) {
      print("Oyun başlatma hatası: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendGuess(String token, String capital) async {
    if (_status?.sessionId == null || _showResult) return;

    _stopStopwatch(); // ⏱️ KULLANICI CEVAPLADI, SÜREYİ DURDUR
    double timeTakenInSeconds = _stopwatch.elapsedMilliseconds / 1000.0;

    _selectedAnswer = capital;
    _showResult = true; // Butonları kilitliyoruz
    notifyListeners();

    try {
      // Backend'e isteği atıyoruz
      var nextStatus = await _gameService.makeGuess(
        token,
        _status!.sessionId!,
        capital,
        timeTakenInSeconds, // ⏱️ SÜREYİ BACKEND'E GÖNDER
      );

      _correctAnswer = nextStatus.lastCorrectAnswer;

      // 🚨 YENİ EKLENDİ: DOĞRU/YANLIŞ KONTROLÜ VE SES/TİTREŞİM TETİKLEME
      bool isGuessCorrect =
          (_selectedAnswer?.trim().toLowerCase() ==
          _correctAnswer?.trim().toLowerCase());
      _playFeedback(isGuessCorrect);

      notifyListeners();

      await Future.delayed(Duration(milliseconds: 1500));

      _status = nextStatus;
      _showResult = false;
      _selectedAnswer = null;
      _correctAnswer = null;

      // ⏱️ EĞER OYUN BİTMEDİYSE YENİ SORU İÇİN SÜREYİ BAŞTAN BAŞLAT
      if (_status?.finished == false) {
        _startStopwatch();
      }

      notifyListeners();
    } catch (e) {
      // 🚨 HATA OLURSA EKRANIN DONMASINI ENGELLEYEN GÜVENLİK AĞI
      print("💥 FLUTTER HATASI (sendGuess): $e");

      // Kilitleri aç ve ekranı eski haline getir ki donuk kalmasın
      _showResult = false;
      notifyListeners();
    }
  }

  void resetGame() {
    _status = null;
    _isLoading = false;
    _stopStopwatch(); // ⏱️ TEMİZLİK
    _formattedTime = "00.00";
    notifyListeners();
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _audioPlayer.dispose(); // 🚨 YENİ EKLENDİ: Ses motorunu hafızadan temizle
    super.dispose();
  }
}
