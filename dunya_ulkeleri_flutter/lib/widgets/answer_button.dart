// lib/widgets/answer_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';

// 🚨 YENİ EKLENDİ: 'selected' durumu eklendi
enum AnswerState { normal, correct, wrong, disabled, selected }

class AnswerButton extends StatelessWidget {
  final String? prefix;
  final String text;
  final AnswerState state;
  final VoidCallback onPressed;

  const AnswerButton({
    super.key,
    this.prefix,
    required this.text,
    required this.state,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColors.surface2.withOpacity(0.55);
    Color borderColor = AppColors.borderLight;
    Color textColor = AppColors.textDark;

    Color badgeBg = AppColors.surface.withOpacity(0.7);
    Color badgeFg = AppColors.textMuted;

    IconData? trailingIcon;
    Color trailingColor = AppColors.textMuted;

    if (state == AnswerState.correct) {
      bgColor = AppColors.successGreen.withOpacity(0.18);
      borderColor = AppColors.successGreen;
      textColor = AppColors.textDark;
      badgeBg = AppColors.successGreen;
      badgeFg = Colors.black;
      trailingIcon = Icons.check_circle;
      trailingColor = AppColors.successGreen;
    } else if (state == AnswerState.wrong) {
      bgColor = AppColors.errorRed.withOpacity(0.16);
      borderColor = AppColors.errorRed;
      textColor = AppColors.textDark;
      badgeBg = AppColors.errorRed;
      badgeFg = Colors.black;
      trailingIcon = Icons.cancel;
      trailingColor = AppColors.errorRed;
    } else if (state == AnswerState.disabled) {
      bgColor = AppColors.surface2.withOpacity(0.28);
      borderColor = AppColors.borderLight.withOpacity(0.6);
      textColor = AppColors.textMuted.withOpacity(0.65);
      badgeBg = AppColors.surface2.withOpacity(0.35);
      badgeFg = AppColors.textMuted.withOpacity(0.65);
    } else if (state == AnswerState.selected) {
      bgColor = AppColors.yellow.withOpacity(0.18);
      borderColor = AppColors.yellow;
      textColor = AppColors.textDark;
      badgeBg = AppColors.yellow;
      badgeFg = Colors.black;
      trailingIcon = Icons.hourglass_bottom;
      trailingColor = AppColors.yellow;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              if (state == AnswerState.normal)
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: Row(
            children: [
              if (prefix != null) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor.withOpacity(0.7)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    prefix!,
                    style: TextStyle(
                      color: badgeFg,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 12),
                Icon(trailingIcon, color: trailingColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
