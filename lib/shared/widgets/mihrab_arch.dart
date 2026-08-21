import 'package:flutter/material.dart';

/// A container whose top edge is a mihrab/arch curve, drawn with a gold
/// outline. Used to top the counter card and the about emblem.
class MihrabArch extends StatelessWidget {
  const MihrabArch({
    super.key,
    required this.child,
    this.outlineColor,
    this.outlineWidth = 1.5,
    this.archHeight = 28,
  });

  final Widget child;
  final Color? outlineColor;
  final double outlineWidth;
  final double archHeight;

  @override
  Widget build(BuildContext context) {
    final gold = outlineColor ?? Theme.of(context).colorScheme.secondary;
    return CustomPaint(
      painter: _MihrabOutlinePainter(
        color: gold,
        strokeWidth: outlineWidth,
        archHeight: archHeight,
      ),
      child: ClipPath(
        clipper: _MihrabArchClipper(archHeight: archHeight),
        child: child,
      ),
    );
  }
}

class _MihrabArchClipper extends CustomClipper<Path> {
  _MihrabArchClipper({required this.archHeight});
  final double archHeight;

  @override
  Path getClip(Size size) {
    final path = Path();
    // Start at top-left, arch up over the top, down the sides, square bottom.
    path.moveTo(0, archHeight);
    // Arch: a quadratic curve peaking at the top-center.
    path.quadraticBezierTo(size.width / 2, -archHeight, size.width, archHeight);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _MihrabArchClipper old) =>
      old.archHeight != archHeight;
}

class _MihrabOutlinePainter extends CustomPainter {
  _MihrabOutlinePainter({
    required this.color,
    required this.strokeWidth,
    required this.archHeight,
  });

  final Color color;
  final double strokeWidth;
  final double archHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final path = Path()
      ..moveTo(0, archHeight)
      ..quadraticBezierTo(size.width / 2, -archHeight, size.width, archHeight);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MihrabOutlinePainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.archHeight != archHeight;
}

