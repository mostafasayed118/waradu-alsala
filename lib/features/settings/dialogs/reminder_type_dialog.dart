import 'package:flutter/material.dart';
import 'package:salawat_app/core/l10n/app_localizations.dart';
import 'package:salawat_app/domain/entities/adhkar_counter.dart';
import 'package:salawat_app/features/counting/counters_provider.dart';

void showReminderTypeDialog(
  BuildContext context,
  CountersProvider counters,
) {
  final s = S.of(context);
  final counter = counters.activeCounter;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(s.reminderTypeLabel),
      content: RadioGroup<ReminderType>(
        groupValue: counter.reminderType,
        onChanged: (value) async {
          await counters.setReminderType(counter.id, value!);
          if (context.mounted) {
            Navigator.pop(context);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ReminderType>(
              title: Text(s.repeatTypeOption),
              subtitle: Text(s.repeatTypeSub),
              value: ReminderType.interval,
            ),
            RadioListTile<ReminderType>(
              title: Text(s.dailyTypeOption),
              subtitle: Text(s.dailyTypeSub),
              value: ReminderType.daily,
            ),
            RadioListTile<ReminderType>(
              title: Text(s.prayerTypeOption),
              subtitle: Text(s.prayerTypeSub),
              value: ReminderType.prayer,
            ),
          ],
        ),
      ),
    ),
  );
}
