import 'package:flutter/material.dart';

/// Single source of truth for width-based responsive breakpoints and
/// content max-widths. Thresholds (dp):
///   compact  <= 400   (very small phone)
///   medium   401–600   (typical phone)
///   expanded 601–840   (small tablet / large phone landscape)
///   wide     >= 841    (tablet)
class Breakpoints {
  Breakpoints._();

  static const double compactMax = 400;
  static const double mediumMax = 600;
  static const double expandedMax = 840;

  /// Two-pane layouts kick in at this width.
  static const double twoPaneMin = 840;

  /// Content max-widths so columns don't stretch on tablets.
  static const double homeMaxWidth = 520;
  static const double settingsMaxWidth = 560;

  static bool isCompact(double width) => width <= compactMax;
  static bool isMedium(double width) =>
      width > compactMax && width <= mediumMax;
  static bool isExpanded(double width) =>
      width > mediumMax && width <= expandedMax;
  static bool isWide(double width) => width > expandedMax;
  static bool useTwoPane(double width) => width >= twoPaneMin;
}

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
