import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:salawat_app/core/l10n/app_localizations.dart';
import 'package:salawat_app/data/backup_service.dart';
import 'package:salawat_app/domain/services/stats_calculator.dart';

void showExportSheet(BuildContext context) {
  final s = S.of(context);
  showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.description),
            title: Text(s.exportJsonOption),
            onTap: () {
              Navigator.pop(sheetContext);
              _exportData(context, isCsv: false);
            },
          ),
          ListTile(
            leading: const Icon(Icons.table_chart),
            title: Text(s.exportCsvOption),
            onTap: () {
              Navigator.pop(sheetContext);
              _exportData(context, isCsv: true);
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> _exportData(BuildContext context, {required bool isCsv}) async {
  final backup = context.read<BackupService>();
  final messenger = ScaffoldMessenger.of(context);
  final s = S.of(context);
  try {
    final content =
        isCsv ? await backup.buildCsv() : await backup.buildJsonBackup();
    final dir = await getTemporaryDirectory();
    final name = 'zikr-backup-${dailyKey(DateTime.now())}.${isCsv ? 'csv' : 'json'}';
    final file = File('${dir.path}/$name')..writeAsStringSync(content);
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(file.path, mimeType: isCsv ? 'text/csv' : 'application/json'),
        ],
      ),
    );
    unawaited(file.delete());
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(content: Text(s.errorExportFailed)),
    );
  }
}
