part of '../country_detail_screen.dart';

extension _CountryDetailScreenFlagCardImpl on CountryDetailScreenState {
  Widget _buildFlagCardImpl() {
    final borderRadius = BorderRadius.circular(18);

    Widget content;
    if (flagAlpha2.isNotEmpty) {
      content = LayoutBuilder(
        builder: (context, constraints) {
          return Flag.fromString(
            flagAlpha2,
            fit: BoxFit.cover,
            height: constraints.maxHeight.isFinite ? constraints.maxHeight : 200,
            width: constraints.maxWidth.isFinite ? constraints.maxWidth : null,
          );
        },
      );
    } else if (flagEmoji.isNotEmpty) {
      content = Center(
        child: Text(
          flagEmoji,
          style: const TextStyle(fontSize: 68),
        ),
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
