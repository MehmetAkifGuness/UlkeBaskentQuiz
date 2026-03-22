import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_model.dart';

class AuthService {
  // Eski hali: "http://10.0.2.2:8080/api/game"
  final String baseUrl = "http://10.229.146.163:8080/api/auth";

  // KAYIT
  Future<AuthModel> register(
    String username,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    // YENİ GÜVENLİK KONTROLÜ
    if (response.statusCode == 200) {
      return AuthModel.fromJson(jsonDecode(response.body));
    } else {
      // Hata varsa uygulamayı çökertme, Exception fırlat ki ekranda Toast mesajı vs. basabilelim
      throw Exception(response.body);
    }
  }

  // GİRİŞ
  // GİRİŞ
  Future<AuthModel> login(String username, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 10)); // 10 saniye sonra durdur

      if (response.statusCode == 200) {
        return AuthModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      throw Exception("Bağlantı zaman aşımına uğradı veya sunucu kapalı!");
    }
  }

  // Misafir Girişi İsteği
  Future<AuthModel> guestLogin() async {
    final response = await http.post(
      Uri.parse('$baseUrl/guest'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return AuthModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Misafir girişi başarısız oldu!');
    }
  }

  // MAİL DOĞRULAMA
  Future<AuthModel> verify(String email, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );

    // YENİ GÜVENLİK KONTROLÜ
    if (response.statusCode == 200) {
      return AuthModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body);
    }
  }

  // 1. AŞAMA: Şifre sıfırlama kodu gönder
  Future<AuthModel> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode == 200) {
      return AuthModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body);
    }
  }

  // 2. AŞAMA: Kodu doğrula ve yeni şifreyi kaydet
  Future<AuthModel> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'resetCode': code,
        'newPassword': newPassword,
      }),
    );
    if (response.statusCode == 200) {
      return AuthModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body);
    }
  }
}
