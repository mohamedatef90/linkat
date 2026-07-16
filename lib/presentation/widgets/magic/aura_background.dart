import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/notion_theme.dart';
import 'magic.dart';

/// Full-bleed magic_black backdrop: a radial ink2 -> ink aura with a subtle
/// drifting field of green/lime motes (the ambient "starfield" set-piece,
/// tuned for a phone). Put it at the base of a screen's Stack, or pass a
/// [child] to have it stack for you. Static under reduced-motion.
class AuraBackground extends StatefulWidget {
  final Widget? child;
  final bool particles;

  const AuraBackground({super.key, this.child, this.particles = true});

  @override
  State<AuraBackground> createState() => _AuraBackgroundState();
}

class _AuraBackgroundState extends State<AuraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 26),
  );
  late final List<_Mote> _motes;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(7);
    _motes = List.generate(
      26,
      (_) => _Mote(
        x: rnd.nextDouble(),
        y: rnd.nextDouble(),
        r: 0.7 + rnd.nextDouble() * 1.9,
        speed: 0.2 + rnd.nextDouble() * 0.6,
        lime: rnd.nextBool(),
        phase: rnd.nextDouble(),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = magicReducedMotion(context);
    if (!reduce && widget.particles && !_c.isAnimating) _c.repeat();

    const bg = DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.85),
          radius: 1.35,
          colors: [NotionTheme.ink2, NotionTheme.ink],
        ),
      ),
    );

    final Widget paint = (reduce || !widget.particles)
        ? CustomPaint(
            painter: _AuraPainter(_motes, 0, reduce: true),
            size: Size.infinite,
          )
        : AnimatedBuilder(
            animation: _c,
            builder: (_, _) => CustomPaint(
              painter: _AuraPainter(_motes, _c.value),
              size: Size.infinite,
            ),
          );

    return Stack(
      children: [
        const Positioned.fill(child: bg),
        Positioned.fill(child: IgnorePointer(child: RepaintBoundary(child: paint))),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _Mote {
  final double x, y, r, speed, phase;
  final bool lime;
  const _Mote({
    required this.x,
    required this.y,
    required this.r,
    required this.speed,
    required this.lime,
    required this.phase,
  });
}

class _AuraPainter extends CustomPainter {
  final List<_Mote> motes;
  final double t;
  final bool reduce;

  _AuraPainter(this.motes, this.t, {this.reduce = false});

  @override
  void paint(Canvas canvas, Size size) {
    for (final m in motes) {
      final prog = reduce ? m.y : ((m.y - t * m.speed) % 1.0 + 1.0) % 1.0;
      final y = prog * size.height;
      final x = m.x * size.width +
          (reduce ? 0 : math.sin((t + m.phase) * 2 * math.pi) * 8);
      final base = m.lime ? NotionTheme.lime : NotionTheme.green;
      final paint = Paint()
        ..color = base.withValues(alpha: 0.10 + 0.12 * m.phase)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawCircle(Offset(x, y), m.r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuraPainter old) => old.t != t;
}
