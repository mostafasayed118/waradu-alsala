import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salawat_app/core/l10n/app_localizations.dart';
import 'package:salawat_app/data/backup_service.dart';
import 'package:salawat_app/data/notifications/notification_service.dart';
import 'package:salawat_app/features/counting/counters_provider.dart';
import 'package:salawat_app/features/settings/settings_provider.dart';

Future<void> showRestoreFlow(BuildContext context) async {
  final s = S.of(context);
  final backup = context.read<BackupService>();
  final counters = context.read<CountersProvider>();
  final settings = context.read<SettingsProvider>();
  final notifications = context.read<NotificationService>();
  final messenger = ScaffoldMessenger.of(context);

  final picked = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  if (picked.isEmpty) return;

  final BackupData data;
  try {
    final bytes = await picked.single.readAsBytes();
    data = backup.parseJsonBackup(utf8.decode(bytes));
  } on BackupException catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(s.backupError(e.code.name))),
    );
    return;
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(content: Text(s.errorReadFileFailed)),
    );
    return;
  }

  if (!context.mounted) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(s.restoreBackup),
      content: Text(s.restoreConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(s.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(
            s.restoreAction,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  try {
    await backup.applyBackup(data);
    await counters.load();
    await settings.load();
    messenger.showSnackBar(
      SnackBar(content: Text(s.restoreSuccess)),
    );
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(content: Text(s.errorRestoreFailed)),
    );
  }
  try {
    await notifications.rescheduleAll(counters.counters,
        settings: settings.settings);
  } catch (_) {}
}
