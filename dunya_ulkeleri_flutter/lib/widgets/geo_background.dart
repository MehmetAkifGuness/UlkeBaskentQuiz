import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GeoBackground extends StatelessWidget {
  final Widget child;
  final bool safeArea;

  const GeoBackground({super.key, required this.child, this.safeArea = true});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.background),
      child: Stack(
        children: [
          Positioned(
            left: -140,
            top: -160,
            child: _GlowBlob(
              color: AppColors.primaryBlue.withValues(alpha: 0.25),
              size: 360,
            ),
          ),
          Positioned(
            right: -130,
            top: -180,
            child: _GlowBlob(
              color: AppColors.successGreen.withValues(alpha: 0.12),
              size: 340,
            ),
          ),
          Positioned(
            left: -80,
            bottom: -140,
            child: _GlowBlob(
              color: AppColors.primaryBlueHover.withValues(alpha: 0.12),
              size: 280,
            ),
          ),
          if (safeArea) SafeArea(child: child) else child,
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

