// lib/services/duel_api_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/duel_session_dto.dart';
import 'api_exception.dart';

class DuelApiService {
  final String baseUrl = "${dotenv.env['API_BASE_URL']}/duel";

  Map<String, String> _headers({required String token}) {
    final safeToken = token.trim();
    return <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $safeToken',
    };
  }

  Future<CreateDuelSessionResponse> createSession(
    CreateDuelSessionRequest request, {
    required String token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/sessions'),
            headers: _headers(token: token),
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return CreateDuelSessionResponse.fromJson(
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

  Future<CreateDuelSessionResponse> quickMatch(
    CreateDuelSessionRequest request, {
    required String token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/quick-match'),
            headers: _headers(token: token),
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return CreateDuelSessionResponse.fromJson(
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

  Future<JoinDuelSessionResponse> joinSession(
    String roomCode,
    JoinDuelSessionRequest request, {
    required String token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/sessions/$roomCode/join'),
            headers: _headers(token: token),
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return JoinDuelSessionResponse.fromJson(
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

  Future<DuelSessionState> getSessionState(
    String sessionId, {
    required String token,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/sessions/$sessionId'),
            headers: _headers(token: token),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return DuelSessionState.fromJson(
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

  Future<void> leaveSession({
    required String sessionId,
    required String playerId,
    required String token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/sessions/$sessionId/leave'),
            headers: _headers(token: token),
            body: jsonEncode(
              LeaveDuelSessionRequest(sessionId: sessionId, playerId: playerId)
                  .toJson(),
            ),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 204) return;
      throw ApiException.fromResponse(response);
    } on TimeoutException {
      throw Exception("Sunucu yanıt vermedi. İnternetinizi kontrol edin.");
    } on SocketException {
      throw Exception("İnternet bağlantınız koptu.");
    }
  }
}

