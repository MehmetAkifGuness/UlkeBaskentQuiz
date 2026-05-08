import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/auth_model.dart';
import 'api_exception.dart';

class AuthService {
  final String baseUrl = "${dotenv.env['API_BASE_URL']}/auth";

  Future<AuthModel> register(
    String username,
    String email,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return AuthModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
      throw ApiException.fromResponse(response);
    } on TimeoutException {
      throw Exception("Sunucu yanıt vermedi. Lütfen internetinizi kontrol edin.");
    } on SocketException {
      throw Exception("İnternet bağlantınız koptu.");
    }
  }

  Future<AuthModel> login(String username, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return AuthModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
      throw ApiException.fromResponse(response);
    } on TimeoutException {
      throw Exception("Sunucu yanıt vermedi. Lütfen internetinizi kontrol edin.");
    } on SocketException {
      throw Exception("İnternet bağlantınız koptu.");
    }
  }

  Future<AuthModel> guestLogin() async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/guest'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return AuthModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
      throw ApiException.fromResponse(response);
    } on TimeoutException {
      throw Exception("Sunucu yanıt vermedi. Lütfen internetinizi kontrol edin.");
    } on SocketException {
      throw Exception("İnternet bağlantınız koptu.");
    }
  }

  Future<AuthModel> verify(String email, String code) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/verify'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'code': code}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return AuthModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
      throw ApiException.fromResponse(response);
    } on TimeoutException {
      throw Exception("Sunucu yanıt vermedi. Lütfen internetinizi kontrol edin.");
    } on SocketException {
      throw Exception("İnternet bağlantınız koptu.");
    }
  }

  Future<AuthModel> forgotPassword(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return AuthModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
      throw ApiException.fromResponse(response);
    } on TimeoutException {
      throw Exception("Sunucu yanıt vermedi. Lütfen internetinizi kontrol edin.");
    } on SocketException {
      throw Exception("İnternet bağlantınız koptu.");
    }
  }

  Future<AuthModel> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/reset-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'resetCode': code,
              'newPassword': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return AuthModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
      throw ApiException.fromResponse(response);
    } on TimeoutException {
      throw Exception("Sunucu yanıt vermedi. Lütfen internetinizi kontrol edin.");
    } on SocketException {
      throw Exception("İnternet bağlantınız koptu.");
    }
  }

  Future<AuthModel> resendVerification(String email) async {
    try {
      final response = await http
          .post(Uri.parse('$baseUrl/resend-verification?email=$email'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return AuthModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
      throw ApiException.fromResponse(response);
    } on TimeoutException {
      throw Exception("Sunucu yanıt vermedi. Lütfen internetinizi kontrol edin.");
    } on SocketException {
      throw Exception("İnternet bağlantınız koptu.");
    }
  }
}

