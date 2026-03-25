// lib/utils/page_transitions.dart
import 'package:flutter/material.dart';

class FadePageRoute extends PageRouteBuilder {
  final Widget page;

  FadePageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(
          milliseconds: 300,
        ), // 300ms ideal yumuşaklıktır
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Şık bir saydamlaşarak gelme (Fade) efekti
          return FadeTransition(
            opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
            child: child,
          );
        },
      );
}
