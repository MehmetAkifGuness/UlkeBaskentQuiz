// lib/services/game_service.dart
import 'dart:convert';
import 'package:dunya_ulkeleri_flutter/models/dictionary_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/game_status_model.dart';

// 🚨 YENİ İMPORTLAR: Yönlendirme ve yetki temizliği için gerekli
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../main.dart'; // navigatorKey için
import '../screens/login_screen.dart';

class GameService {
  final String baseUrl = "${dotenv.env['API_BASE_URL']}/game";

  // 🚨 YENİ EKLENDİ: Token süresi dolduğunda tüm sistemi temizleyip Login'e atan fonksiyon
  void _handleUnauthorized() {
    if (navigatorKey.currentContext != null) {
      // AuthProvider üzerinden çıkış yap ve cihaz hafızasını sil
      Provider.of<AuthProvider>(
        navigatorKey.currentContext!,
        listen: false,
      ).logout();

      // Kullanıcıya şık bir uyarı göster
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text("Oturum süresi doldu. Lütfen tekrar giriş yapın."),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );
    }

    // Tüm oyun/profil sayfalarını kapatıp zorla Login ekranına yönlendir
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
    // 🚨 YENİ: mode eklendi
    // 📡 Kategori ve Mode bilgisini URL'ye parametre olarak ekledik
    final response = await http.post(
      Uri.parse('$baseUrl/start?category=$category&mode=$mode'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    // 🚨 YENİ EKLENDİ: Yetki Kontrolü
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
  }

  // backend'den sözlük listesini çeker
  Future<List<DictionaryModel>> getDictionary(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/dictionary'),
      headers: {'Authorization': 'Bearer $token'},
    );

    // 🚨 YENİ EKLENDİ: Yetki Kontrolü
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
  }

  // YENİ: timeTaken eklendi
  Future<GameStatusModel> makeGuess(
    String token,
    int sessionId,
    String capital,
    double timeTaken, // ⏱️ Backend'e gidecek süre (saniye cinsinden)
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/submit'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'sessionId': sessionId,
        'capitalGuess': capital,
        'timeTaken': timeTaken, // ⏱️ Süreyi JSON'a ekledik
      }),
    );

    // 🚨 YENİ EKLENDİ: Yetki Kontrolü
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
  }
}
