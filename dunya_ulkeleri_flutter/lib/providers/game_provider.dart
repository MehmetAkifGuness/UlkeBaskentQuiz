import 'dart:async'; // ⏱️ Timer için gerekli
import 'package:flutter/material.dart';
import '../models/game_status_model.dart';
import '../services/game_service.dart';

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
    super.dispose();
  }
}
