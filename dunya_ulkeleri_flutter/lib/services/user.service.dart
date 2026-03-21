import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile_model.dart';

class UserService {
  final String baseUrl = "http://10.204.181.163:8080/api/user";

  Future<UserProfileModel?> getUserProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return UserProfileModel.fromJson(json.decode(response.body));
    } else {
      return null;
    }
  }

  // 1. Profil için Kendi Kategori Skorlarımı Getir
  Future<Map<String, int>> getMyCategoryScores(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/my-category-scores'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(
        utf8.decode(response.bodyBytes),
      );
      return jsonResponse.map((key, value) => MapEntry(key, value as int));
    } else {
      throw Exception('Kategori skorları alınamadı!');
    }
  }

  // 2. Seçilen Kategoriye Göre Liderlik Tablosunu Getir
  // --- LİDERLİK TABLOSUNU ÇEK ---
  // 🚨 YENİ: mode parametresini ekledik
  Future<List<Map<String, dynamic>>> getCategoryLeaderboard(
    String token,
    String category,
    String mode,
  ) async {
    try {
      // 📡 URL'ye mode parametresini koyduk
      final response = await http.get(
        Uri.parse('$baseUrl/leaderboard/$category?mode=$mode'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        return List<Map<String, dynamic>>.from(jsonResponse);
      }
    } catch (e) {
      print("Liderlik tablosu çekilemedi: $e");
    }
    return [];
  }

  // Hata Defterini Getir
  // Hata Defterini Getir
  // Hata Defterini Getir
  Future<List<dynamic>> getMistakes(String token) async {
    try {
      final response = await http.get(
        // 🚨 DÜZELTİLDİ: Sadece $baseUrl/mistakes yazıyoruz
        Uri.parse('$baseUrl/mistakes'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print("🎯 API Cevap Kodu: ${response.statusCode}");

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      print("🚨 Hata defteri çekilemedi: $e");
    }
    return [];
  }

  // Öğrenilen Hatayı Sil
  Future<bool> removeMistake(String token, int questionId) async {
    try {
      final response = await http.delete(
        // 🚨 DÜZELTİLDİ: Sadece $baseUrl/mistakes/$questionId yazıyoruz
        Uri.parse('$baseUrl/mistakes/$questionId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- 🚨 AVATAR GÜNCELLEME SERVİSİ ---
  Future<bool> updateAvatar(String token, int avatarId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/avatar/$avatarId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print("Avatar güncellenemedi: $e");
    }
    return false;
  }
}
