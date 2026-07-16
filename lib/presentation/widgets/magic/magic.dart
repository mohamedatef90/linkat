/// magic_black motion + surface vocabulary (Flutter port of the web app's
/// `components/magic.tsx`). Import this one file to get every helper.
library;

import 'package:flutter/material.dart';

export 'aura_background.dart';
export 'glass_card.dart';
export 'gradient_button.dart';
export 'eyebrow.dart';
export 'reveal.dart';
export 'count_up.dart';

/// The single shared easing used across the whole design language.
const Curve kMagicEasing = Cubic(0.2, 0.7, 0.2, 1);

/// Default entrance/transition duration.
const Duration kMagicDuration = Duration(milliseconds: 550);

/// Accessibility floor: honour the OS "reduce motion" setting everywhere.
bool magicReducedMotion(BuildContext context) =>
    MediaQuery.of(context).disableAnimations;

/// Wraps a tappable surface with a subtle press-scale, the tactile feedback
/// that replaces the web's magnetic-button / hover states on touch.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final BorderRadius? borderRadius;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
    this.borderRadius,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = magicReducedMotion(context);
    final scale = (_down && !reduce) ? widget.pressedScale : 1.0;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 120),
        curve: kMagicEasing,
        child: widget.child,
      ),
    );
  }
}
