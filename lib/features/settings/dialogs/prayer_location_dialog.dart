import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salawat_app/core/l10n/app_localizations.dart';
import 'package:salawat_app/data/notifications/notification_service.dart';
import 'package:salawat_app/features/counting/counters_provider.dart';
import 'package:salawat_app/features/settings/settings_provider.dart';

Future<void> showPrayerLocationDialog(BuildContext context) async {
  final s = S.of(context);
  final settings = context.read<SettingsProvider>();
  final counters = context.read<CountersProvider>();
  final notifications = context.read<NotificationService>();

  final latController =
      TextEditingController(text: settings.settings.latitude?.toString() ?? '');
  final lngController = TextEditingController(
      text: settings.settings.longitude?.toString() ?? '');
  var method = settings.settings.calculationMethod;

  final methods = [
    ('muslim_world_league', 'Muslim World League'),
    ('umm_al_qura', 'Umm al-Qura'),
    ('egyptian', 'Egyptian'),
    ('karachi', 'Karachi'),
    ('dubai', 'Dubai'),
    ('qatar', 'Qatar'),
    ('kuwait', 'Kuwait'),
    ('moonsighting_committee', 'Moonsighting Committee'),
    ('north_america', 'ISNA'),
  ];

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(s.prayerLocationSection),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: s.latitudeLabel),
            ),
            TextField(
              controller: lngController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: s.longitudeLabel),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: method,
              decoration: InputDecoration(labelText: s.methodLabel),
              items: [
                for (final m in methods)
                  DropdownMenuItem(value: m.$1, child: Text(m.$2)),
              ],
              onChanged: (value) =>
                  setDialogState(() => method = value ?? method),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(s.save),
          ),
        ],
      ),
    ),
  );

  if (saved != true) return;
  final lat = double.tryParse(latController.text.trim());
  final lng = double.tryParse(lngController.text.trim());
  if (lat == null || lng == null) return;

  await settings.setPrayerLocation(lat, lng);
  await settings.setCalculationMethod(method);
  // Refresh the rolling prayer window with the new location.
  try {
    await notifications.rescheduleAll(counters.counters,
        settings: settings.settings);
  } catch (_) {}
}
