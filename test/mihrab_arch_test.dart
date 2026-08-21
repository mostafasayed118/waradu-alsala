import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_app/shared/widgets/mihrab_arch.dart';

void main() {
  testWidgets('MihrabArch renders its child and outline', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 200,
            child: MihrabArch(child: Text('محتوى')),
          ),
        ),
      ),
    );
    expect(find.byType(MihrabArch), findsOneWidget);
    expect(find.text('محتوى'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
