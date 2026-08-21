import 'package:flutter/material.dart';

/// A 1px gold hairline with a small centered 8-point-star node.
/// Used as an ornamental section divider.
class GoldHairlineDivider extends StatelessWidget {
  const GoldHairlineDivider({super.key, this.color, this.indent = 0});

  final Color? color;
  final double indent;

  @override
  Widget build(BuildContext context) {
    final gold = color ?? Theme.of(context).colorScheme.secondary;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: indent, vertical: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Divider(height: 1, thickness: 1, color: gold),
          // Small 8-point-star node centered on the line.
          Container(
            width: 12,
            height: 12,
            color: Theme.of(context).colorScheme.surface,
            alignment: Alignment.center,
            child: CustomPaint(
              size: const Size(10, 10),
              painter: _StarNodePainter(color: gold),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarNodePainter extends CustomPainter {
  _StarNodePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    // Two overlapping squares → 8-point star.
    canvas.drawRect(Rect.fromCircle(center: Offset(cx, cy), radius: r), paint);
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(0.785398); // 45°
    canvas.drawRect(Rect.fromCircle(center: Offset.zero, radius: r), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StarNodePainter old) => old.color != color;
}

