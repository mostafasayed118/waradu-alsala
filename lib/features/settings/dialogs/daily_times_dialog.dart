import 'package:flutter/material.dart';
import 'package:salawat_app/core/l10n/app_localizations.dart';
import 'package:salawat_app/features/counting/counters_provider.dart';

void showDailyTimesDialog(
  BuildContext context,
  CountersProvider counters,
) {
  final s = S.of(context);
  final counter = counters.activeCounter;
  final times = List<int>.from(counter.dailyReminderTimes);

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(s.dailyTimesLabel),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: times.length,
                  itemBuilder: (context, index) {
                    final time = times[index];
                    final hour = time ~/ 60;
                    final minute = time % 60;
                    return ListTile(
                      title: Text(
                          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            times.removeAt(index);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              ElevatedButton.icon(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      times.add(picked.hour * 60 + picked.minute);
                      times.sort();
                    });
                  }
                },
                icon: const Icon(Icons.add),
                label: Text(s.addTime),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.cancel),
            ),
            TextButton(
              onPressed: () async {
                await counters.setDailyReminderTimes(counter.id, times);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: Text(s.save),
            ),
          ],
        );
      },
    ),
  );
}
