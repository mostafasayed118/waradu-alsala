import 'package:flutter/material.dart';
import 'package:salawat_app/core/l10n/app_localizations.dart';
import 'package:salawat_app/features/counting/counters_provider.dart';

void showPrayerOffsetDialog(
    BuildContext context, CountersProvider counters) {
  final s = S.of(context);
  final counter = counters.activeCounter;
  final options = [5, 10, 15, 20, 30];

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(s.prayerOffsetLabel),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: options.length,
          itemBuilder: (context, index) {
            final minutes = options[index];
            return ListTile(
              title: Text(s.prayerOffsetSubtitle(minutes)),
              selected: counter.prayerOffsetMinutes == minutes,
              onTap: () async {
                await counters.setPrayerOffset(counter.id, minutes);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            );
          },
        ),
      ),
    ),
  );
}
