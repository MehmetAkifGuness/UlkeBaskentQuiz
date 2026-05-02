import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_avatar.dart';
import 'glass_card.dart';

class GeoTopBar extends StatelessWidget {
  final String title;
  final int? avatarId;
  final VoidCallback? onAvatarTap;

  const GeoTopBar({
    super.key,
    this.title = '',
    this.avatarId,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasTitle = title.trim().isNotEmpty;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(18),
        bottomRight: Radius.circular(18),
      ),
      blurSigma: 22,
      tint: AppColors.surface,
      child: Row(
        children: [
          const Icon(Icons.public, color: AppColors.primaryBlue),
          if (hasTitle) ...[
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
          const Spacer(),
          if (avatarId != null)
            AppAvatar(avatarId: avatarId!, size: 40, onTap: onAvatarTap),
        ],
      ),
    );
  }
}
