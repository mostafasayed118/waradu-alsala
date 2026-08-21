import 'package:flutter/material.dart';

/// Centers its child and caps content width on wide screens.
/// On screens narrower than [maxWidth] this is a no-op (the child fills
/// available width), so it is safe to wrap phone layouts unconditionally.
class MaxWidthBox extends StatelessWidget {
  const MaxWidthBox({
    super.key,
    required this.maxWidth,
    required this.child,
  });

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
