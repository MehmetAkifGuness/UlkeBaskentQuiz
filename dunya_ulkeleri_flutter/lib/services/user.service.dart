import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile_model.dart';

class UserService {
  final String baseUrl =
      "http://10.0.2.2:8080/api/user"; // Kendi IP/Portuna göre ayarla

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
  Future<List<Map<String, dynamic>>> getCategoryLeaderboard(
    String token,
    String category,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/leaderboard/$category'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      return jsonResponse.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Liderlik tablosu alınamadı!');
    }
  }
}
