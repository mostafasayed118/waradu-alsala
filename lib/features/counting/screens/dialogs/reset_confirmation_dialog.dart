import 'package:flutter/material.dart';
import 'package:salawat_app/features/counting/counters_provider.dart';
import 'package:salawat_app/core/l10n/app_localizations.dart';

void showResetConfirmation(BuildContext context, CountersProvider counters) {
  final s = S.of(context);
  var includeTotal = false;
  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(s.resetCounterTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.resetConfirmBody),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: Text(s.resetAlsoTotal),
              value: includeTotal,
              onChanged: (value) {
                setDialogState(() {
                  includeTotal = value ?? false;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () async {
              await counters.reset(includeTotal: includeTotal);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: Text(s.confirm, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ),
  );
}
