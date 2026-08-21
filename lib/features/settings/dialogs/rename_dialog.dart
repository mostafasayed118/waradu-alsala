import 'package:flutter/material.dart';
import 'package:salawat_app/core/l10n/app_localizations.dart';
import 'package:salawat_app/features/counting/counters_provider.dart';

void showRenameDialog(BuildContext context, CountersProvider counters) {
  final s = S.of(context);
  final counter = counters.activeCounter;
  final controller = TextEditingController(text: counter.name);
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(s.renameTitle),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(labelText: s.dhikrNameLabel),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(s.cancel),
        ),
        TextButton(
          onPressed: () async {
            final name = controller.text.trim();
            if (name.isNotEmpty) {
              await counters.renameCounter(counter.id, name);
            }
            if (dialogContext.mounted) {
              Navigator.pop(dialogContext);
            }
          },
          child: Text(s.save),
        ),
      ],
    ),
  );
}
