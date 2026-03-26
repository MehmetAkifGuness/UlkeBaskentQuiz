// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 🚨 YENİ ŞİFRELİ DEPO PAKETİ EKLENDİ
import '../models/auth_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  // 🚨 GÜVENLİK YAMASI: Token'ı çalınmalara karşı AES ile şifreleyen depo
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

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

      // 🚨 GÜVENLİK YAMASI: Token'ı cihaza ŞİFRELİ olarak kaydet
      await _secureStorage.write(key: 'token', value: _token!);
      await _secureStorage.write(key: 'username', value: _username!);

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

        // 🚨 GÜVENLİK YAMASI: Normal girişte de token'ı ŞİFRELİ olarak kaydediyoruz
        await _secureStorage.write(key: 'token', value: _token!);
        await _secureStorage.write(key: 'username', value: _username!);
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

    // 🚨 GÜVENLİK YAMASI: Cihaz hafızasındaki şifreli kayıtları tamamen temizle
    await _secureStorage.delete(key: 'token');
    await _secureStorage.delete(key: 'username');

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

  // 🚨 GÜVENLİK YAMASI: Otomatik giriş işlemini ŞİFRELİ depodan okuyarak yapar
  Future<bool> tryAutoLogin() async {
    // Şifreli depodan verileri okumaya çalış
    String? storedToken = await _secureStorage.read(key: 'token');
    String? storedUsername = await _secureStorage.read(key: 'username');

    if (storedToken == null || storedUsername == null) {
      return false; // Token yoksa false dön (Giriş ekranında kalır)
    }

    _token = storedToken;
    _username = storedUsername;

    notifyListeners();
    return true; // Token varsa true dön (Ana ekrana geçer)
  }
}
