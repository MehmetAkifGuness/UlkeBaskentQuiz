import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // Misafir olarak giriş yapma fonksiyonu
  Future<bool> loginAsGuest() async {
    _isLoading = true;
    notifyListeners();

    try {
      final authData = await _authService.guestLogin();
      _token = authData.token;
      _username = authData.username;

      // Token'ı cihaza kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('username', _username!);

      return true;
    } catch (e) {
      print("Misafir giriş hatası: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // giriş yapma
  Future<AuthModel> login(String username, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      AuthModel result = await _authService.login(username, password);

      if (result.token != null) {
        _token = result.token;
        _username = result.username;

        // 🚨 Normal girişte de token'ı cihaza kaydediyoruz
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('username', _username!);
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

  // --- 🚨 YENİ EKLENEN ÇIKIŞ YAP (LOGOUT) FONKSİYONU ---
  Future<void> logout() async {
    _token = null;
    _username = null;

    // Cihaz hafızasındaki kayıtlı oturum bilgilerini tamamen temizle
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('username');

    notifyListeners();
  }

  // Şifre sıfırlama e-postası gönder
  Future<AuthModel> sendPasswordResetEmail(String email) async {
    try {
      _isLoading = true;
      notifyListeners();
      return await _authService.forgotPassword(email);
    } catch (e) {
      print("Şifre sıfırlama hatası: $e");
      return AuthModel(message: "Bağlantı hatası veya geçersiz e-posta: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Yeni şifreyi ayarla
  Future<AuthModel> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();
      return await _authService.resetPassword(email, code, newPassword);
    } catch (e) {
      print("Şifre yenileme hatası: $e");
      return AuthModel(message: "Geçersiz kod veya bağlantı hatası: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey('token')) {
      return false;
    }

    _token = prefs.getString('token');
    _username = prefs.getString('username');

    notifyListeners();
    return true;
  }
}
