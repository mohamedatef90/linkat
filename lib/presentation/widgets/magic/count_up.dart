import 'package:flutter/material.dart';
import 'magic.dart';

/// Counts an integer up from zero on first build (magic_black stat numbers).
/// Respects reduced-motion by showing the final value immediately.
class CountUp extends StatefulWidget {
  final int to;
  final Duration duration;
  final TextStyle? style;
  final String prefix;
  final String suffix;

  const CountUp(
    this.to, {
    super.key,
    this.duration = const Duration(milliseconds: 1100),
    this.style,
    this.prefix = '',
    this.suffix = '',
  });

  @override
  State<CountUp> createState() => _CountUpState();
}

class _CountUpState extends State<CountUp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _a =
      CurvedAnimation(parent: _c, curve: kMagicEasing);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (magicReducedMotion(context)) {
      _c.value = 1;
    } else if (!_c.isAnimating && _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void didUpdateWidget(covariant CountUp old) {
    super.didUpdateWidget(old);
    if (old.to != widget.to && !magicReducedMotion(context)) {
      _c
        ..reset()
        ..forward();
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
      animation: _a,
      builder: (context, _) {
        final value = (widget.to * _a.value).round();
        return Text(
          '${widget.prefix}$value${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}
