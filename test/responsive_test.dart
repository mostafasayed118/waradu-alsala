import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
