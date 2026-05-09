// lib/services/conquest_api_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/conquest_session_dto.dart';
import 'api_exception.dart';

class ConquestApiService {
  final String baseUrl = "${dotenv.env['API_BASE_URL']}/conquest";

  Future<CreateConquestSessionResponse> createSession(
    CreateConquestSessionRequest request,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/sessions'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return CreateConquestSessionResponse.fromJson(
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

  Future<JoinConquestSessionResponse> joinSession(
    String roomCode,
    JoinConquestSessionRequest request,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/sessions/$roomCode/join'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return JoinConquestSessionResponse.fromJson(
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

  Future<ConquestSessionState> getSessionState(String sessionId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/sessions/$sessionId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return ConquestSessionState.fromJson(
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

  Future<CreateConquestSessionResponse> quickMatch(
    CreateConquestSessionRequest request,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/quick-match'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return CreateConquestSessionResponse.fromJson(
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
}
