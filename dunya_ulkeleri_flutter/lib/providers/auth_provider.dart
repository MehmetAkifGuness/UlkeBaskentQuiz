// lib/providers/auth_provider.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 🚨 YENİ ŞİFRELİ DEPO PAKETİ EKLENDİ
import '../models/auth_model.dart';
import '../services/auth_service.dart';
import '../utils/error_message_utils.dart';

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

  Future<void> updateSession({required String token, required String username}) async {
    _token = token;
    _username = username;

    await _secureStorage.write(key: 'token', value: token);
    await _secureStorage.write(key: 'username', value: username);

    notifyListeners();
  }

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
      debugPrint("Misafir giriş hatası: $e");
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
      debugPrint("GİRİŞ HATASI: $e"); // Hatayı terminale yazdır
      return AuthModel(message: errorMessageFrom(e));
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
      debugPrint("Şifre sıfırlama hatası: $e");
      throw Exception(errorMessageFrom(e));
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
      debugPrint("Şifre yenileme hatası: $e");
      throw Exception(errorMessageFrom(e));
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

    if (_isJwtExpired(storedToken)) {
      await logout();
      return false;
    }

    _token = storedToken;
    _username = storedUsername;

    notifyListeners();
    return true; // Token varsa true dön (Ana ekrana geçer)
  }

  bool _isJwtExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = _decodeBase64Url(parts[1]);
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return true;

      final exp = decoded['exp'];
      if (exp is! num) return false;

      final expiry =
          DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true);
      return expiry.isBefore(DateTime.now().toUtc());
    } catch (_) {
      return true;
    }
  }

  String _decodeBase64Url(String input) {
    var output = input.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw const FormatException('Invalid base64url');
    }
    return utf8.decode(base64Decode(output));
  }
}
