import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppAvatar extends StatelessWidget {
  final int avatarId;
  final double size;
  final bool showDot;
  final VoidCallback? onTap;

  const AppAvatar({
    super.key,
    required this.avatarId,
    this.size = 40,
    this.showDot = false,
    this.onTap,
  });

  static int stableAvatarIdFromText(String text, {int max = 15}) {
    var hash = 0;
    for (final code in text.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return (hash % max) + 1;
  }

  @override
  Widget build(BuildContext context) {
    final avatar = SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppGradients.primary,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.25),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(2.2),
          child: ClipOval(
            child: Image.asset(
              'assets/avatars/avatar_$avatarId.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.surface2,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person,
                      color: AppColors.textMuted,
                      size: size * 0.55,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    final content = showDot
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              avatar,
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: size * 0.26,
                  height: size * 0.26,
                  decoration: BoxDecoration(
                    color: AppColors.successGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                ),
              ),
            ],
          )
        : avatar;

    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}
