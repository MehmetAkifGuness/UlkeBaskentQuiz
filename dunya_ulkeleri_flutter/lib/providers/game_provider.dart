// lib/providers/game_provider.dart
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

  GameStatusModel? get status => _status;
  bool get isLoading => _isLoading;
  bool get showResult => _showResult;
  String? get selectedAnswer => _selectedAnswer;
  String? get correctAnswer => _correctAnswer;

  // --- DEĞİŞİKLİK BURADA: category parametresi eklendi ---
  Future<void> startNewGame(String token, String category) async {
    _isLoading = true;
    _showResult = false;
    notifyListeners();
    try {
      // Seçilen kategoriyi servise gönderiyoruz
      _status = await _gameService.startGame(token, category);
    } catch (e) {
      print("Oyun başlatma hatası: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendGuess(String token, String capital) async {
    // Zaten bir sonuç gösteriliyorsa çift tıklamayı engelle
    if (_status?.sessionId == null || _showResult) return;

    // 1. Kullanıcının seçtiği cevabı kaydet ve bekleme moduna geç
    _selectedAnswer = capital;
    _showResult = true;
    notifyListeners();

    // 2. Backend'e isteği at
    var nextStatus = await _gameService.makeGuess(
      token,
      _status!.sessionId!,
      capital,
    );

    // 3. Backend'den dönen doğru cevabı al ve ekrana yeşil/kırmızı yanması için haber ver
    _correctAnswer = nextStatus.lastCorrectAnswer;
    notifyListeners();

    // 4. Kullanıcının renkleri algılayabilmesi için 1.5 saniye bekle
    await Future.delayed(Duration(milliseconds: 1500));

    // 5. Yeni soruya geç ve ekranı sıfırla
    _status = nextStatus;
    _showResult = false;
    _selectedAnswer = null;
    _correctAnswer = null;
    notifyListeners();
  }

  // Yeni oyun öncesi eski verileri temizlemek için
  void resetGame() {
    _status = null;
    _isLoading = false;
    notifyListeners();
  }
}
