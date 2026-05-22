part of '../country_detail_screen.dart';

extension _CountryDetailScreenFlagCardImpl on CountryDetailScreenState {
  Widget _buildFlagCardImpl() {
    final borderRadius = BorderRadius.circular(18);

    Widget content;
    if (flagUrl.isNotEmpty) {
      content = Image.network(
        flagUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: AppColors.textMuted, size: 40),
                SizedBox(height: 8),
                Text(
                  "Bayrak yüklenemedi",
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue),
          );
        },
      );
    } else {
      content = const Center(
        child: Icon(Icons.flag_rounded, size: 72, color: AppColors.textMuted),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.borderLight),
        color: AppColors.surface2.withValues(alpha: 0.40),
      ),
      child: ClipRRect(borderRadius: borderRadius, child: content),
    );
  }



}

