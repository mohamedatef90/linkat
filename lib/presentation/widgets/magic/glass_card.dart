import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/notion_theme.dart';
import 'magic.dart';

/// The core magic_black surface: a frosted glass panel with a hairline border.
/// Pass [highlight] for the one lime-accented card per section.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool highlight;
  final double radius;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.highlight = false,
    this.radius = 20,
    this.blur = 18,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    final surface = ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: br,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: highlight
                  ? [
                      NotionTheme.lime.withValues(alpha: 0.14),
                      NotionTheme.panel.withValues(alpha: 0.55),
                    ]
                  : [
                      NotionTheme.panel.withValues(alpha: 0.55),
                      NotionTheme.ink2.withValues(alpha: 0.55),
                    ],
            ),
            border: Border.all(
              color: highlight
                  ? NotionTheme.lime.withValues(alpha: 0.45)
                  : NotionTheme.borderSoft,
              width: 1,
            ),
            boxShadow: highlight
                ? [
                    BoxShadow(
                      color: NotionTheme.lime.withValues(alpha: 0.12),
                      blurRadius: 24,
                      spreadRadius: -6,
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return surface;
    return Pressable(onTap: onTap, borderRadius: br, child: surface);
  }
}
