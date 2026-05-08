import '../services/api_exception.dart';

String errorMessageFrom(Object error) {
  if (error is ApiException) {
    return error.message;
  }

  final text = error.toString().trim();
  if (text.isEmpty) {
    return "Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.";
  }

  return text.replaceFirst('Exception: ', '').trim();
}

