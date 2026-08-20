import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_app/widgets/decorative_app_shell.dart';

void main() {
  testWidgets('shell switches tabs and preserves state', (tester) async {
    int homeBuilds = 0;
    int statsBuilds = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: DecorativeAppShell(
          screens: [
            StatefulBuilder(
              builder: (context, _) {
                homeBuilds++;
                return const _StateMarker(label: 'home-content');
              },
            ),
            StatefulBuilder(
              builder: (context, _) {
                statsBuilds++;
                return const _StateMarker(label: 'stats-content');
              },
            ),
            const _StateMarker(label: 'settings-content'),
          ],
        ),
      ),
    );

    // Home is shown first; stats/settings built but kept offstage by stack.
    expect(find.text('الرئيسية'), findsWidgets);
    expect(find.text('home-content'), findsOneWidget);

    // Switch to Stats tab by its label.
    await tester.tap(find.text('الإحصائيات'));
    await tester.pumpAndSettle();
    expect(find.text('stats-content'), findsOneWidget);

    // Switch to Settings.
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    expect(find.text('settings-content'), findsOneWidget);

    // Back to Home — IndexedStack preserved it, so home-content is still there.
    await tester.tap(find.text('الرئيسية'));
    await tester.pumpAndSettle();
    expect(find.text('home-content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _StateMarker extends StatelessWidget {
  const _StateMarker({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Center(child: Text(label));
}
