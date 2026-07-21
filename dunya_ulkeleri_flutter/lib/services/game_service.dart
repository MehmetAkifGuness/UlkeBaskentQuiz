import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dunya_ulkeleri_flutter/models/dictionary_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../app/navigation.dart';
import '../models/game_status_model.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import 'country_catalog_service.dart';
import 'api_exception.dart';

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

  Future<List<DictionaryModel>> getDictionary(String token) async {
    return CountryCatalogService().loadDictionaryModels();
  }

  Future<GameStatusModel> makeGuess(
    String token,
    int sessionId,
    String capital,
    double timeTaken,
  ) async {
    try {
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

  Future<GameStatusModel?> checkActiveGame(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/resume'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 204 || response.statusCode == 404) {
        return null;
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
