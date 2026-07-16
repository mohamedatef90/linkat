import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/notion_theme.dart';

/// The magic_black section label: a lime dot + uppercase mono text.
/// Used for "PLATFORMS", "BROWSE", "FOLDERS" style headers.
class Eyebrow extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;

  const Eyebrow(
    this.text, {
    super.key,
    this.padding = const EdgeInsets.symmetric(vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              gradient: NotionTheme.grad,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              color: NotionTheme.fog2,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
