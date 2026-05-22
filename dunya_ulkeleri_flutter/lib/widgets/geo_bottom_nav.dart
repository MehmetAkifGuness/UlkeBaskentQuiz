import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glass_card.dart';

class GeoNavItem {
  final IconData icon;
  final String label;

  const GeoNavItem({required this.icon, required this.label});
}

class GeoBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final List<GeoNavItem> items;

  const GeoBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    required this.items,
  }) : assert(items.length >= 2);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        borderRadius: BorderRadius.circular(26),
        blurSigma: 22,
        tint: AppColors.surface,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _GeoNavButton(
                  item: items[i],
                  selected: i == currentIndex,
                  onTap: () => onChanged(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GeoNavButton extends StatelessWidget {
  final GeoNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _GeoNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.primaryBlue : AppColors.textMuted;
    final bg = selected
        ? AppColors.primaryBlue.withValues(alpha: 0.18)
        : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, color: fg, size: 22),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(
                  color: fg,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

