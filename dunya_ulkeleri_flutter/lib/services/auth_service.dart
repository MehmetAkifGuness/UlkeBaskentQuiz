import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_model.dart';

class AuthService {
  final String baseUrl = "http://10.0.2.2:8080/api/auth";

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
  Future<AuthModel> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    // YENİ GÜVENLİK KONTROLÜ
    if (response.statusCode == 200) {
      return AuthModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body);
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
}
