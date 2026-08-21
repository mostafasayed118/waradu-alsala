import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_app/shared/widgets/islamic_pattern.dart';

void main() {
  testWidgets('IslamicPattern renders without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 200,
            child: IslamicPattern(opacity: 0.1),
          ),
        ),
      ),
    );
    expect(find.byType(IslamicPattern), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
