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
}
