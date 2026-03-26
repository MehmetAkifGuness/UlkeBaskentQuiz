// lib/services/game_service.dart
import 'dart:async'; // 🚨 YENİ: Timeout (Zaman Aşımı) için eklendi
import 'dart:io'; // 🚨 YENİ: İnternet kopması (SocketException) için eklendi
import 'dart:convert';
import 'package:dunya_ulkeleri_flutter/models/dictionary_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/game_status_model.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../main.dart'; // navigatorKey için
import '../screens/login_screen.dart';

class GameService {
  final String baseUrl = "${dotenv.env['API_BASE_URL']}/game";

  void _handleUnauthorized() {
    if (navigatorKey.currentContext != null) {
      Provider.of<AuthProvider>(
        navigatorKey.currentContext!,
        listen: false,
      ).logout();

      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text("Oturum süresi doldu. Lütfen tekrar giriş yapın."),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );
    }

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  Future<GameStatusModel> startGame(
    String token,
    String category,
    String mode,
  ) async {
    try {
      // 🚨 YENİ: .timeout(Duration) eklendi! 5 saniyede cevap gelmezse iptal olur.
      final response = await http
          .post(
            Uri.parse('$baseUrl/start?category=$category&mode=$mode'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 401 || response.statusCode == 403) {
        _handleUnauthorized();
        throw Exception("Yetkisiz erişim veya oturum süresi doldu.");
      }

      print("--- OYUN BAŞLATMA İSTEĞİ ---");
      print("Seçilen Kategori: $category, Seçilen Mod: $mode");
      print("Durum Kodu: ${response.statusCode}");
      print("Gelen Cevap: '${response.body}'");

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return GameStatusModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
          "Backend hatası: ${response.statusCode} / İçerik: ${response.body}",
        );
      }
      // 🚨 YENİ EKLENDİ: İNTERNET KOPMASI VE ZAMAN AŞIMI YAKALAYICILARI
    } on TimeoutException {
      throw Exception("Sunucu yanıt vermedi. İnternetinizi kontrol edin.");
    } on SocketException {
      throw Exception("İnternet bağlantınız koptu.");
    }
  }

  Future<List<DictionaryModel>> getDictionary(String token) async {
    try {
      // 🚨 YENİ: .timeout(Duration) eklendi!
      final response = await http
          .get(
            Uri.parse('$baseUrl/dictionary'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 401 || response.statusCode == 403) {
        _handleUnauthorized();
        throw Exception("Yetkisiz erişim veya oturum süresi doldu.");
      }

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        return jsonResponse
            .map((item) => DictionaryModel.fromJson(item))
            .toList();
      } else {
        throw Exception('Sözlük verisi alınamadı!');
      }
    } on TimeoutException {
      throw Exception("Sunucu yanıt vermedi. İnternetinizi kontrol edin.");
    } on SocketException {
      throw Exception("İnternet bağlantınız koptu.");
    }
  }

  Future<GameStatusModel> makeGuess(
    String token,
    int sessionId,
    String capital,
    double timeTaken,
  ) async {
    try {
      // 🚨 YENİ: .timeout(Duration) eklendi!
      final response = await http
          .post(
            Uri.parse('$baseUrl/submit'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'sessionId': sessionId,
              'capitalGuess': capital,
              'timeTaken': timeTaken,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 401 || response.statusCode == 403) {
        _handleUnauthorized();
        throw Exception("Yetkisiz erişim veya oturum süresi doldu.");
      }

      print("--- TAHMİN İSTEĞİ ---");
      print("Geçen Süre: $timeTaken saniye");
      print("Durum Kodu: ${response.statusCode}");
      print("Gelen Cevap: ${response.body}");

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return GameStatusModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
          "Tahmin hatası: ${response.statusCode} - ${response.body}",
        );
      }
    } on TimeoutException {
      throw Exception("Sunucu yanıt vermedi. İnternetinizi kontrol edin.");
    } on SocketException {
      throw Exception("İnternet bağlantınız koptu.");
    }
  }

  // 🚨 YENİ EKLENDİ: Backend'e "Yarım kalan oyunum var mı?" diye soran metod
  Future<GameStatusModel?> checkActiveGame(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/resume'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 204 || response.statusCode == 404) {
        return null; // Aktif/yarım oyun yok
      } else if (response.statusCode == 200 && response.body.isNotEmpty) {
        return GameStatusModel.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _handleUnauthorized();
        throw Exception("Yetkisiz erişim veya oturum süresi doldu.");
      } else {
        return null;
      }
    } catch (e) {
      print("Aktif oyun kontrol hatası: $e");
      return null; // Çökmeyi önlemek için null dönüyoruz
    }
  }
}
