import 'package:flutter/material.dart';
import 'package:salawat_app/core/l10n/app_localizations.dart';
import 'package:salawat_app/features/counting/counters_provider.dart';

String reminderIntervalLabel(S s, int minutes) {
  if (minutes < 60) {
    return s.everyMinutes(minutes);
  } else if (minutes == 60) {
    return s.everyHour;
  } else {
    final hours = minutes ~/ 60;
    return s.everyHours(hours);
  }
}

void showReminderIntervalDialog(BuildContext context, CountersProvider counters) {
  final s = S.of(context);
  final counter = counters.activeCounter;
  final intervals = [15, 30, 60, 120, 180, 360, 720];

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(s.intervalLabel),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: intervals.length,
          itemBuilder: (context, index) {
            final minutes = intervals[index];
            return ListTile(
              title: Text(reminderIntervalLabel(s, minutes)),
              selected: counter.reminderIntervalMinutes == minutes,
              onTap: () async {
                await counters.setReminderInterval(counter.id, minutes);
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
