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

