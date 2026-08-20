import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_app/utils/app_text_styles.dart';
import 'package:salawat_app/utils/breakpoints.dart';

void main() {
  group('Breakpoints', () {
    test('classifies widths into the four buckets', () {
      expect(Breakpoints.isCompact(320), isTrue);
      expect(Breakpoints.isCompact(400), isTrue);
      expect(Breakpoints.isMedium(500), isTrue);
      expect(Breakpoints.isMedium(600), isTrue);
      expect(Breakpoints.isExpanded(700), isTrue);
      expect(Breakpoints.isExpanded(840), isTrue);
      expect(Breakpoints.isWide(841), isTrue);
    });

    test('useTwoPane is true at and above 840', () {
      expect(Breakpoints.useTwoPane(839), isFalse);
      expect(Breakpoints.useTwoPane(840), isTrue);
      expect(Breakpoints.useTwoPane(1200), isTrue);
    });
  });

  testWidgets('MaxWidthBox caps and centers child on wide screens',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MaxWidthBox(
            maxWidth: 200,
            child: const SizedBox(width: double.infinity, height: 50),
          ),
        ),
      ),
    );
    await tester.pump();

    final box = tester.widget<ConstrainedBox>(
        find.descendant(of: find.byType(MaxWidthBox), matching: find.byType(ConstrainedBox)));
    expect(box.constraints.maxWidth, 200);
    expect(find.byType(Center), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('AppTextStyles width scaling', () {
    /// Pumps a MaterialApp whose body captures the kufiNumber style for the
    /// current view size, returns its fontSize.
    Future<double> kufiFontSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      double? fontSize;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              fontSize = AppTextStyles.kufiNumber(context).fontSize;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();
      return fontSize!;
    }

    testWidgets('kufiNumber scales up from compact to wide', (tester) async {
      final compact = await kufiFontSize(tester, const Size(360, 640));
      final wide = await kufiFontSize(tester, const Size(1200, 800));

      expect(compact, lessThan(wide));
      // compact factor 0.82 of 88 ≈ 72.16; wide factor 1.18 of 88 ≈ 103.84
      expect(compact, closeTo(72.16, 0.5));
      expect(wide, closeTo(103.84, 0.5));
    });
  });
}
