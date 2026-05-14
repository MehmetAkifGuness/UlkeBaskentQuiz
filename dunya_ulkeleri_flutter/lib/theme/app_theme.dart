// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  // GeoMaster benzeri koyu/fütüristik palet
  static const Color primaryBlue = Color(0xFF38BDF8); // Neon mavi
  static const Color primaryBlueHover = Color(0xFF0EA5E9);
  static const Color lightBlueHover = Color(0xFF7DD3FC);
  static const Color actionBlue = Color(0xFF1E40AF); // Koyu mavi aksiyon

  // Destekleyici renkler
  static const Color brown = Color(0xFFD97706); // Bronze / turuncu
  static const Color yellow = Color(0xFFFBBF24); // Altın

  // Nötr ve arka plan
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFF0B1220);
  static const Color background2 = Color(0xFF030712);
  static const Color surface = Color(0xFF111B2D);
  static const Color surface2 = Color(0xFF0F172A);
  static const Color textDark = Color(
    0xFFE6F1FF,
  ); // Ana yazı (koyu temada açık)
  static const Color textMuted = Color(0xFF94A3B8);

  // Feedback (geribildirim) renkleri
  static const Color successGreen = Color(0xFF34D399);
  static const Color errorRed = Color(0xFFF87171);

  // Çizgiler ve kenarlıklar
  static const Color borderLight = Color(0x26FFFFFF); // %15 beyaz
  static const Color borderBlueish = Color(0x3348D2FF);
}

class AppGradients {
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.background, AppColors.background2],
  );

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.lightBlueHover, AppColors.primaryBlueHover],
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final scheme = base.colorScheme.copyWith(
      primary: AppColors.primaryBlue,
      secondary: AppColors.successGreen,
      surface: AppColors.surface,
      background: AppColors.background,
      error: AppColors.errorRed,
      outline: AppColors.borderLight,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryBlue,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textDark),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface2,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surface2,
        selectedColor: AppColors.primaryBlue.withOpacity(0.20),
        side: const BorderSide(color: AppColors.borderLight),
        labelStyle: const TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primaryBlue,
            width: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primaryBlue),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surface2,
        contentTextStyle: TextStyle(color: AppColors.textDark),
      ),
    );
  }

  // Geriye dönük kullanım için (istersen ileride tamamen kaldırabiliriz)
  static ThemeData get lightTheme => darkTheme;
}
