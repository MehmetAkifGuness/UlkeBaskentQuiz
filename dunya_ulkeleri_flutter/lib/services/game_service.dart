import 'dart:convert';
import 'package:dunya_ulkeleri_flutter/models/dictionary_model.dart';
import 'package:http/http.dart' as http;
import '../models/game_status_model.dart';

class GameService {
  final String baseUrl = "http://10.204.181.163:8080/api/game";

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
