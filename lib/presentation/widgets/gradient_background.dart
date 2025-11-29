import 'package:flutter/material.dart';
import '../theme/glass_theme.dart';

/// Animated gradient background for screens
class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: GlassTheme.backgroundGradient),
      child: child,
    );
  }
}
