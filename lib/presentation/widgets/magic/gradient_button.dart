import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/notion_theme.dart';
import 'magic.dart';

/// Primary call-to-action in the green->lime gradient. Text/icon render in
/// [NotionTheme.ink] for contrast against the light accent.
class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expand;
  final bool loading;
  final EdgeInsetsGeometry padding;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.expand = false,
    this.loading = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(NotionTheme.ink),
            ),
          )
        else if (icon != null) ...[
          Icon(icon, size: 18, color: NotionTheme.ink),
          const SizedBox(width: 10),
        ],
        if (!loading)
          Text(
            label,
            style: GoogleFonts.inter(
              color: NotionTheme.ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );

    return Pressable(
      onTap: enabled ? onPressed : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: NotionTheme.grad,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: NotionTheme.lime.withValues(alpha: 0.28),
                blurRadius: 22,
                spreadRadius: -6,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: content,
        ),
      ),
    );
  }
}
