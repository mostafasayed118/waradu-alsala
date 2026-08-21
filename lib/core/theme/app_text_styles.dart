import 'package:flutter/material.dart';
import 'package:salawat_app/core/utils/breakpoints.dart';

class AppTextStyles {
  AppTextStyles._();

  /// Width-derived scale factor. Accessibility text scaling (textScaler) is
  /// applied automatically by Flutter at render time and is NOT included
  /// here — only the layout-driven width factor.
  static double _scaleFor(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w <= Breakpoints.compactMax) return 0.82;
    if (w <= Breakpoints.mediumMax) return 1.0;
    if (w <= Breakpoints.expandedMax) return 1.12;
    return 1.18;
  }

  static TextStyle bismillah(BuildContext context) => TextStyle(
        fontFamily: 'Amiri',
        fontSize: 22 * _scaleFor(context),
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.secondary,
      );

  static TextStyle display(BuildContext context) => TextStyle(
        fontFamily: 'Amiri',
        fontSize: 20 * _scaleFor(context),
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.secondary,
      );

  static TextStyle kufiNumber(BuildContext context) => TextStyle(
        fontFamily: 'ReemKufi',
        fontSize: 88 * _scaleFor(context),
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.primary,
      );

  static TextStyle bodyArabic(BuildContext context) => TextStyle(
        fontFamily: 'Amiri',
        fontSize: 16 * _scaleFor(context),
        color: Theme.of(context).textTheme.bodyMedium?.color,
      );

  static TextStyle uiLabel(BuildContext context) => TextStyle(
        fontFamily: 'ReemKufi',
        fontSize: 24 * _scaleFor(context),
        fontWeight: FontWeight.w500,
        color: Colors.white,
      );
}

