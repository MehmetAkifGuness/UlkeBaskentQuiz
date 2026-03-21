// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  // Ana Renkler (Mavi)
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color primaryBlueHover = Color(0xFF2563EB);
  static const Color lightBlueHover = Color(0xFFDBEAFE);

  // Destekleyici Renkler
  static const Color brown = Color(0xFF92400E);
  static const Color yellow = Color(0xFFF59E0B);

  // Nötr ve Arka Plan
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF1F5F9);
  static const Color textDark = Color(0xFF0F172A);

  // Feedback (Geribildirim) Renkleri
  static const Color successGreen = Color(0xFF22C55E);
  static const Color errorRed = Color(0xFFEF4444);

  // Çizgiler ve Kenarlıklar
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderBlueish = Color(0xFFCBD5F5);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryBlue,
      fontFamily: 'Roboto', // Varsa özel fontunu buraya yazabilirsin
      // Üst Bar (Navbar) Teması
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white, // Yazı ve ikon rengi
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.white),
      ),

      // Standart Buton Teması (Ana Butonlar için)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
