import 'package:flutter/material.dart';

/// A faint 8-pointed-star (Khatam) tessellation painted with CustomPaint.
///
/// Used as a decorative low-opacity background layer behind cards/headers.
/// Drawn entirely in code — zero external image assets.
class IslamicPattern extends StatelessWidget {
  const IslamicPattern({super.key, this.color, this.opacity = 0.04});

  /// Star color. Defaults to the theme gold (colorScheme.secondary) when null.
  final Color? color;

  /// Opacity applied to the star paint. Typical values 0.03–0.08.
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? Theme.of(context).colorScheme.secondary;
    return CustomPaint(
      painter: _KhatamTessellationPainter(
        color: starColor.withOpacity(opacity.clamp(0.0, 1.0)),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _KhatamTessellationPainter extends CustomPainter {
  _KhatamTessellationPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Tile the plane with a square cell; in each cell draw an 8-pointed star
    // formed by two overlapping squares (one axis-aligned, one rotated 45°).
    const cell = 40.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final half = cell / 2;
    final r = half * 0.82;

    for (var y = 0; y * cell < size.height; y++) {
      for (var x = 0; x * cell < size.width; x++) {
        final cx = x * cell + half;
        final cy = y * cell + half;
        // Axis-aligned square.
        final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
        canvas.drawRect(rect, paint);
        // Rotated square (together they form an 8-pointed star / Khatam).
        canvas.save();
        canvas.translate(cx, cy);
        canvas.rotate(0.785398); // 45° in radians
        canvas.drawRect(
          Rect.fromCircle(center: Offset.zero, radius: r),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KhatamTessellationPainter old) =>
      old.color != color;
}
