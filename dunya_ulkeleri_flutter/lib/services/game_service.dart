import 'dart:convert';
import 'package:dunya_ulkeleri_flutter/models/dictionary_model.dart';
import 'package:http/http.dart' as http;
import '../models/game_status_model.dart';

class GameService {
  final String baseUrl = "http://10.0.2.2:8080/api/game";

  Future<GameStatusModel> startGame(String token, String category) async {
    // 📡 Kategori bilgisini URL'ye parametre olarak ekledik
    final response = await http.post(
      Uri.parse('$baseUrl/start?category=$category'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    // 📡 BURASI ÇOK KRİTİK: Terminale bakacağız
    print("--- OYUN BAŞLATMA İSTEĞİ ---");
    print("Seçilen Kategori: $category");
    print("Durum Kodu: ${response.statusCode}");
    print("Gelen Cevap: '${response.body}'");

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      return GameStatusModel.fromJson(jsonDecode(response.body));
    } else {
      // Eğer boş gelirse veya hata kodu dönerse uygulamayı patlatmak yerine hata fırlatıyoruz
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
      // Türkçe karakterlerin (ş, ç, ö vb.) bozuk gelmemesi için utf8.decode kullanıyoruz
      List jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      return jsonResponse
          .map((item) => DictionaryModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Sözlük verisi alınamadı!');
    }
  }

  Future<GameStatusModel> makeGuess(
    String token,
    int sessionId,
    String capital,
  ) async {
    // 🚨 ADRES DEĞİŞTİ: /guess yerine /submit oldu
    final response = await http.post(
      Uri.parse('$baseUrl/submit'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      // 🚨 DİKKAT: JSON anahtarları GameAnswerRequest sınıfındakiyle aynı olmalı!
      body: jsonEncode({'sessionId': sessionId, 'capitalGuess': capital}),
    );

    print("--- TAHMİN İSTEĞİ ---");
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
