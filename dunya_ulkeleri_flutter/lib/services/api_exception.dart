import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? code;
  final String? path;
  final Map<String, dynamic>? details;
  final String? rawBody;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.code,
    this.path,
    this.details,
    this.rawBody,
  });

  factory ApiException.fromResponse(http.Response response) {
    final bodyText = utf8.decode(response.bodyBytes).trim();
    String? message;
    String? code;
    String? path;
    Map<String, dynamic>? details;

    try {
      final decoded = jsonDecode(bodyText);
      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);
        final rawMessage = map['message'];
        if (rawMessage != null) {
          message = rawMessage.toString();
        }
        final rawCode = map['code'];
        if (rawCode != null) {
          code = rawCode.toString();
        }
        final rawPath = map['path'];
        if (rawPath != null) {
          path = rawPath.toString();
        }
        final rawDetails = map['details'];
        if (rawDetails is Map) {
          details = Map<String, dynamic>.from(rawDetails);
        }
      }
    } catch (_) {
      // ignore parse errors; we'll fall back below
    }

    message ??= _fallbackMessage(response.statusCode, bodyText);

    return ApiException(
      statusCode: response.statusCode,
      message: message,
      code: code,
      path: path,
      details: details,
      rawBody: bodyText.isEmpty ? null : bodyText,
    );
  }

  static String _fallbackMessage(int statusCode, String bodyText) {
    if (bodyText.isNotEmpty && bodyText.length < 300) {
      return bodyText;
    }
    switch (statusCode) {
      case 400:
        return "Gönderilen bilgiler geçersiz.";
      case 401:
        return "Oturum süresi doldu veya yetkisiz erişim.";
      case 403:
        return "Bu işlem için yetkiniz yok.";
      case 404:
        return "İstenen kaynak bulunamadı.";
      case 409:
        return "Bu işlem şu anda gerçekleştirilemiyor.";
      case 429:
        return "Çok fazla istek gönderildi. Lütfen biraz sonra tekrar deneyin.";
      default:
        return "Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.";
    }
  }

  @override
  String toString() => message;
}

