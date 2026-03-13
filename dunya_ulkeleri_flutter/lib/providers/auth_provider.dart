import 'package:flutter/material.dart';
import '../models/auth_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  String? _token;
  String? _username;
  bool _isLoading = false;

  // verilere erişmek için get metodu
  String? get token => _token;
  String? get username => _username;
  bool get isLoading => _isLoading;

  // giriş yapma
  // lib/providers/auth_provider.dart içindeki login fonksiyonu

  Future<AuthModel> login(String username, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      AuthModel result = await _authService.login(username, password);

      if (result.token != null) {
        _token = result.token;
        _username = result.username;
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      // 🚨 HATA OLSA BİLE yükleniyor simgesini kapat ki ekran donmasın!
      _isLoading = false;
      notifyListeners();
      print("GİRİŞ HATASI: $e"); // Hatayı terminale yazdır
      return AuthModel(message: "Sunucuya bağlanılamadı: $e");
    }
  }
}
