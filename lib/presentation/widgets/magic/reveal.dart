import 'package:flutter/material.dart';
import 'magic.dart';

/// Entrance animation: fade + slide up (the magic_black scroll-reveal, adapted
/// to a mount-time reveal). Stagger list items by passing increasing [delay].
/// Reduced-motion shows the child immediately.
class Reveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double offset;
  final Duration duration;

  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 22,
    this.duration = kMagicDuration,
  });

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  // The stagger delay is baked into the controller as an Interval instead of a
  // Future.delayed: a plain timer would linger and fail widget tests with
  // "pending timers" (and can't be canceled once scheduled).
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _c,
    curve: Interval(_delayFraction, 1, curve: kMagicEasing),
  );
  bool _scheduled = false;

  double get _delayFraction {
    final total = widget.delay + widget.duration;
    if (total <= Duration.zero) return 0;
    return widget.delay.inMicroseconds / total.inMicroseconds;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    if (magicReducedMotion(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fade,
      builder: (context, child) => Opacity(
        opacity: _fade.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _fade.value) * widget.offset),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
