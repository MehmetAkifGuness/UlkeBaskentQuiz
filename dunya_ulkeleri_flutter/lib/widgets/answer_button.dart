// lib/widgets/answer_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';

// 🚨 YENİ EKLENDİ: 'selected' durumu eklendi
enum AnswerState { normal, correct, wrong, disabled, selected }

class AnswerButton extends StatelessWidget {
  final String text;
  final AnswerState state;
  final VoidCallback onPressed;

  const AnswerButton({
    super.key,
    required this.text,
    required this.state,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Varsayılan (Normal) Görünüm Ayarları
    Color bgColor = AppColors.white;
    Color borderColor = AppColors.borderBlueish;
    Color textColor = AppColors.textDark;

    // Duruma göre renkleri değiştiriyoruz
    if (state == AnswerState.correct) {
      bgColor = AppColors.successGreen;
      borderColor = AppColors.successGreen;
      textColor = AppColors.white;
    } else if (state == AnswerState.wrong) {
      bgColor = AppColors.errorRed;
      borderColor = AppColors.errorRed;
      textColor = AppColors.white;
    } else if (state == AnswerState.disabled) {
      // Tıklanma bittikten sonra diğer şıkların soluk görünmesi için
      bgColor = AppColors.white.withOpacity(0.7);
      borderColor = AppColors.borderLight;
      textColor = AppColors.textDark.withOpacity(0.5);
    } else if (state == AnswerState.selected) {
      // 🚨 YENİ: Tıklanan şık, backend'den cevap beklerken bu rengi alacak
      bgColor = Colors.amber;
      borderColor = Colors.amber;
      textColor = Colors.black; // Sarı üzerinde siyah daha şık durur
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: InkWell(
        onTap: (state == AnswerState.normal)
            ? () {
                Provider.of<SettingsProvider>(
                  context,
                  listen: false,
                ).triggerButtonVibration();
                onPressed();
              }
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              if (state == AnswerState.normal)
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
