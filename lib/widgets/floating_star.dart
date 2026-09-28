import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

/// A sticker-style star that bobs, twinkles, and spins when tapped.
class FloatingStar extends StatefulWidget {
  final double size;
  final double tilt;      // resting rotation in radians
  final int seed;         // makes each star move slightly differently
  final VoidCallback? onTap;

  const FloatingStar({
    super.key,
    this.size = 40,
    this.tilt = 0,
    this.seed = 0,
    this.onTap,
  });

  @override
  State<FloatingStar> createState() => _FloatingStarState();
}

class _FloatingStarState extends State<FloatingStar>
    with TickerProviderStateMixin {
  late final AnimationController _idle;   // endless bob + twinkle
  late final AnimationController _pop;    // one-shot spin on tap

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2200 + widget.seed * 350),
    )..repeat(reverse: true);

    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _idle.dispose();
    _pop.dispose();
    super.dispose();
  }

  void _handleTap() {
    _pop.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_idle, _pop]),
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_idle.value);
          final bob = reduceMotion ? 0.0 : (t - 0.5) * 8;       // up/down px
          final twinkle = reduceMotion ? 1.0 : 0.94 + 0.12 * t; // tiny pulse

          // Tap: full spin + elastic squash-and-stretch
          final p = Curves.easeOutBack.transform(_pop.value);
          final spin = _pop.value * math.pi * 2;
          final popScale = 1 + math.sin(_pop.value * math.pi) * 0.45 * p.clamp(0.0, 1.0);

          return Transform.translate(
            offset: Offset(0, bob),
            child: Transform.rotate(
              angle: widget.tilt + spin,
              child: Transform.scale(
                scale: twinkle * popScale,
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CustomPaint(painter: _StarPainter()),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = size.width / 2 - 2;
    final inner = outer * 0.5;

    Path star(double o, double i) {
      final path = Path();
      for (var k = 0; k < 10; k++) {
        final r = k.isEven ? o : i;
        final a = -math.pi / 2 + k * math.pi / 5;
        final pt = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
        k == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      return path..close();
    }

    final body = star(outer, inner);

    // Yellow body
    canvas.drawPath(body, Paint()..color = Cute.star);

    // Pink core, like the sticker in the image
    canvas.drawPath(star(outer * 0.42, outer * 0.2), Paint()..color = Cute.starCore);

    // Chunky outline with rounded joins
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..color = Cute.ink,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}