import 'dart:math';

import 'package:flutter/material.dart';
import 'package:salawat_app/shared/widgets/islamic_pattern.dart' show khatamStarPath;

/// A transient burst of gold Khatam stars celebrating a reached target.
/// Fires once, animates for ~1.8s, then reports [onDone] so the parent can
/// remove it from the tree. Taps pass straight through.
class CelebrationBurst extends StatefulWidget {
  const CelebrationBurst({super.key, this.onDone});

  final VoidCallback? onDone;

  @override
  State<CelebrationBurst> createState() => _CelebrationBurstState();
}

class _CelebrationBurstState extends State<CelebrationBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  static const Duration _duration = Duration(milliseconds: 1800);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    final rng = Random(7);
    _particles = List.generate(42, (i) => _Particle.spawn(rng, i));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDone?.call();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _BurstPainter(
            particles: _particles,
            t: _controller.value,
            color: Theme.of(context).colorScheme.secondary,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Particle {
  _Particle.spawn(Random rng, int index) {
    // Launch from around the upper-center of the surface.
    origin = Offset(0.5 + (rng.nextDouble() - 0.5) * 0.3, 0.28);
    final angle =
        -pi / 2 + (rng.nextDouble() - 0.5) * pi * 1.1; // mostly upward fan
    final speed = 0.35 + rng.nextDouble() * 0.45;
    velocity = Offset(cos(angle) * speed, sin(angle) * speed);
    size = 6 + rng.nextDouble() * 10;
    spin = (rng.nextDouble() - 0.5) * 4 * pi;
    delay = (index % 8) * 0.03;
  }

  late final Offset origin; // fractional coordinates
  late final Offset velocity; // fractional per-second
  late final double size;
  late final double spin;
  late final double delay;

  /// Position at progress [t] in [0,1], gravity pulling downward.
  Offset at(double t) {
    final tt = max(0.0, t - delay);
    return Offset(
      origin.dx + velocity.dx * tt,
      origin.dy +
          velocity.dy * tt +
          0.9 * tt * tt, // gravity
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.particles,
    required this.t,
    required this.color,
  });

  final List<_Particle> particles;
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final fadeOut = t < 0.65 ? 1.0 : 1.0 - (t - 0.65) / 0.35;
    if (fadeOut <= 0) return;

    for (final p in particles) {
      final pos = p.at(t);
      if (pos.dy > 1.15) continue;
      final paint = Paint()
        ..color = color.withValues(alpha: fadeOut.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(pos.dx * size.width, pos.dy * size.height);
      canvas.rotate(p.spin * t);
      final scale = 1.0 - t * 0.4;
      canvas.scale(scale);
      canvas.drawPath(
          khatamStarPath(Offset.zero, p.size), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.t != t;
}

