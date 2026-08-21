import 'package:flutter/material.dart';
import 'package:salawat_app/core/l10n/app_localizations.dart';
import 'package:salawat_app/features/counting/counters_provider.dart';

void showDeleteCounterDialog(BuildContext context, CountersProvider counters) {
  final s = S.of(context);
  final counter = counters.activeCounter;
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(s.deleteCounterLabel),
      content: Text(s.deleteConfirmBody(counter.name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(s.cancel),
        ),
        TextButton(
          onPressed: () async {
            await counters.deleteCounter(counter.id);
            if (dialogContext.mounted) {
              Navigator.pop(dialogContext);
            }
          },
          child:
              Text(s.deleteAction, style: const TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
