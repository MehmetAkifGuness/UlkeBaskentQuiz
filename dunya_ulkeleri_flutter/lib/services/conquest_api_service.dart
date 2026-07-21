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

  Map<String, String> _headers({String? token}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final t = token?.trim();
    if (t != null && t.isNotEmpty) {
      headers['Authorization'] = 'Bearer $t';
    }
    return headers;
  }

  Future<CreateConquestSessionResponse> createSession(
    CreateConquestSessionRequest request,
    {required String token}
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/sessions'),
            headers: _headers(token: token),
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
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
    {required String token}
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/sessions/$roomCode/join'),
            headers: _headers(token: token),
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
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

  Future<ConquestSessionState> getSessionState(String sessionId,
      {required String token}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/sessions/$sessionId'),
            headers: _headers(token: token),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
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
    {required String token}
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/quick-match'),
            headers: _headers(token: token),
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
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
            body: jsonEncode({'sessionId': sessionId, 'playerId': playerId}),
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

  Future<ConquestSessionState> pauseSession({
    required String sessionId,
    required String playerId,
    required String token,
  }) => _changePauseState(
        action: 'pause',
        sessionId: sessionId,
        playerId: playerId,
        token: token,
      );

  Future<ConquestSessionState> resumeSession({
    required String sessionId,
    required String playerId,
    required String token,
  }) => _changePauseState(
        action: 'resume',
        sessionId: sessionId,
        playerId: playerId,
        token: token,
      );

  Future<ConquestSessionState> _changePauseState({
    required String action,
    required String sessionId,
    required String playerId,
    required String token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/sessions/$sessionId/$action'),
            headers: _headers(token: token),
            body: jsonEncode({'sessionId': sessionId, 'playerId': playerId}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
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
}
