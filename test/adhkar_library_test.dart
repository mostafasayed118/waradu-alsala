import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_app/data/adhkar_library.dart';

void main() {
  test('every dhikr entry has a unique id and non-empty text', () {
    final ids = adhkarLibrary.map((d) => d.id).toSet();

    expect(ids.length, adhkarLibrary.length);
    for (final dhikr in adhkarLibrary) {
      expect(dhikr.name, isNotEmpty, reason: '${dhikr.id} name');
      expect(dhikr.text, isNotEmpty, reason: '${dhikr.id} text');
    }
  });

  test('each category has at least one dhikr', () {
    final categories = adhkarLibrary.map((d) => d.category).toSet();

    expect(categories.length, 3);
  });

  test('recommended counts are positive when present', () {
    for (final dhikr in adhkarLibrary) {
      if (dhikr.recommendedCount != null) {
        expect(dhikr.recommendedCount!, greaterThan(0),
            reason: dhikr.id);
      }
    }
  });
}
