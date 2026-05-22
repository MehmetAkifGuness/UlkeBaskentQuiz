// lib/services/game_service.dart
import 'dart:async'; // 🚨 YENİ: Timeout (Zaman Aşımı) için eklendi
import 'dart:io'; // 🚨 YENİ: İnternet kopması (SocketException) için eklendi
import 'dart:convert';
import 'package:dunya_ulkeleri_flutter/models/dictionary_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../models/game_status_model.dart';
import 'api_exception.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../app/navigation.dart'; // navigatorKey için
import '../screens/login_screen.dart';

class GameService {
  final String baseUrl = "${dotenv.env['API_BASE_URL']}/game";

  static List<DictionaryModel>? _cachedLocalDictionary;

  Future<List<DictionaryModel>> _loadDictionaryFromAsset() async {
    final cached = _cachedLocalDictionary;
    if (cached != null && cached.isNotEmpty) return cached;

    final raw = await rootBundle.loadString(
      'assets/dictionary/dictionary_tr.json',
    );

    final decoded = jsonDecode(raw);
    if (decoded is! List) return const <DictionaryModel>[];

    final items = decoded
        .whereType<Map>()
        .map((e) => DictionaryModel.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);

    _cachedLocalDictionary = items;
    return items;
  }

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
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401 || response.statusCode == 403) {
        _handleUnauthorized();
        throw ApiException.fromResponse(response);
      }

      debugPrint("--- OYUN BAŞLATMA İSTEĞİ ---");
      debugPrint("Seçilen Kategori: $category, Seçilen Mod: $mode");
      debugPrint("Durum Kodu: ${response.statusCode}");
      debugPrint("Gelen Cevap: '${utf8.decode(response.bodyBytes)}'");

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return GameStatusModel.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)),
        );
      }

      throw ApiException.fromResponse(response);
      // 🚨 YENİ EKLENDİ: İNTERNET KOPMASI VE ZAMAN AŞIMI YAKALAYICILARI
    } on TimeoutException {
      throw Exception("Sunucu yanıt vermedi. İnternetinizi kontrol edin.");
    } on SocketException {
      throw Exception("İnternet bağlantınız koptu.");
    }
  }

  Future<List<DictionaryModel>> getDictionary(String token) async {
    final safeToken = token.trim();
    if (safeToken.isEmpty) {
      return _loadDictionaryFromAsset();
    }

    try {
      // 🚨 YENİ: .timeout(Duration) eklendi!
      final response = await http
          .get(
            Uri.parse('$baseUrl/dictionary'),
            headers: {'Authorization': 'Bearer $safeToken'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401 || response.statusCode == 403) {
        _handleUnauthorized();
        throw ApiException.fromResponse(response);
      }

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        return jsonResponse
            .map((item) => DictionaryModel.fromJson(item))
            .toList();
      }

      throw ApiException.fromResponse(response);
    } on TimeoutException {
      // Sunucuya ulaşılamadıysa sözlük için offline (asset) fallback kullan.
      try {
        return await _loadDictionaryFromAsset();
      } catch (_) {
        throw Exception(
          "Sunucu yanıt vermedi. API_BASE_URL ve backend'i kontrol edin: $baseUrl",
        );
      }
    } on SocketException {
      // İnternet yoksa sözlük için offline (asset) fallback kullan.
      try {
        return await _loadDictionaryFromAsset();
      } catch (_) {
        throw Exception(
          "Sunucuya ulaşılamadı. API_BASE_URL ve ağ bağlantını kontrol et: $baseUrl",
        );
      }
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
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401 || response.statusCode == 403) {
        _handleUnauthorized();
        throw ApiException.fromResponse(response);
      }

      debugPrint("--- TAHMİN İSTEĞİ ---");
      debugPrint("Geçen Süre: $timeTaken saniye");
      debugPrint("Durum Kodu: ${response.statusCode}");
      debugPrint("Gelen Cevap: ${utf8.decode(response.bodyBytes)}");

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return GameStatusModel.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)),
        );
      }

      throw ApiException.fromResponse(response);
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
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 204 || response.statusCode == 404) {
        return null; // Aktif/yarım oyun yok
      } else if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return GameStatusModel.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)),
        );
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _handleUnauthorized();
        throw ApiException.fromResponse(response);
      }

      throw ApiException.fromResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      // Timeout olursa "oyun yok" gibi davranmayalım; Provider bunu hata olarak ele alabilsin.
      throw Exception(
        "Aktif oyun kontrolü zaman aşımına uğradı. API_BASE_URL ve backend'i kontrol et: $baseUrl",
      );
    } on SocketException {
      throw Exception(
        "Aktif oyun kontrolü başarısız (sunucuya ulaşılamadı). API_BASE_URL ve ağ bağlantını kontrol et: $baseUrl",
      );
    } catch (e) {
      throw Exception("Aktif oyun kontrolü sırasında beklenmeyen bir hata oluştu: $e");
    }
  }
}
