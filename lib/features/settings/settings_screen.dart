import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:salawat_app/domain/entities/adhkar_counter.dart';
import 'package:salawat_app/features/counting/counters_provider.dart';
import 'package:salawat_app/features/settings/settings_provider.dart';
import 'package:salawat_app/data/backup_service.dart';
import 'package:salawat_app/data/notifications/notification_service.dart';
import 'package:salawat_app/core/l10n/app_localizations.dart';
import 'package:salawat_app/core/theme/app_text_styles.dart';
import 'package:salawat_app/core/utils/breakpoints.dart';
import 'package:salawat_app/shared/widgets/max_width_box.dart';
import 'package:salawat_app/domain/services/stats_calculator.dart';
import 'package:salawat_app/shared/widgets/gold_divider.dart';
import 'package:salawat_app/features/about/about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<CountersProvider, SettingsProvider>(
      builder: (context, counters, settings, child) {
        final counter = counters.activeCounter;
        final s = S.of(context);
        return MaxWidthBox(
          maxWidth: Breakpoints.settingsMaxWidth,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
            // Active counter section
            _buildSectionTitle(context, s.activeCounterSection),
            ListTile(
              leading: _medallionIcon(context, Icons.edit),
              title: Text(s.nameLabel),
              subtitle: Text(counter.name),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showRenameDialog(context, counters),
            ),
            ListTile(
              leading: _medallionIcon(context, Icons.flag),
              title: Text(s.dailyTargetLabel),
              subtitle: Text(
                counter.dailyTarget > 0
                    ? s.timesUnit(counter.dailyTarget)
                    : s.notSet,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showDailyTargetDialog(context, counters),
            ),
            SwitchListTile(
              secondary: _medallionIcon(context, Icons.notifications_active),
              title: Text(s.remindersLabel),
              subtitle: Text(s.remindersSubtitle),
              value: counter.remindersEnabled,
              activeThumbColor: Theme.of(context).colorScheme.primary,
              onChanged: (value) async {
                final enabled =
                    await counters.setRemindersEnabled(counter.id, value);
                if (value && !enabled && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(S.of(context).notifPermissionDenied)),
                  );
                }
              },
            ),

            if (counter.remindersEnabled) ...[
              ListTile(
                title: Text(s.reminderTypeLabel),
                subtitle: Text(
                  counter.reminderType == ReminderType.interval
                      ? s.intervalTypeDesc
                      : s.dailyTypeDesc,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showReminderTypeDialog(context, counters),
              ),
              if (counter.reminderType == ReminderType.interval)
                ListTile(
                  title: Text(s.intervalLabel),
                  subtitle:
                      Text(_getIntervalText(s, counter.reminderIntervalMinutes)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showIntervalDialog(context, counters),
                ),
              if (counter.reminderType == ReminderType.prayer)
                ListTile(
                  title: Text(s.prayerOffsetLabel),
                  subtitle: Text(s.prayerOffsetSubtitle(
                      counter.prayerOffsetMinutes)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showPrayerOffsetDialog(context, counters),
                ),
              if (counter.reminderType == ReminderType.daily)
                ListTile(
                  title: Text(s.dailyTimesLabel),
                  subtitle: Text(
                    counter.dailyReminderTimes.isEmpty
                        ? s.noTimesSet
                        : s.timesSetCount(counter.dailyReminderTimes.length),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDailyTimesDialog(context, counters),
                ),
            ],
            if (counters.counters.length > 1)
              ListTile(
                leading: _medallionIcon(context, Icons.delete,
                    iconColor: Colors.red),
                title: Text(
                  s.deleteCounterLabel,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () => _showDeleteDialog(context, counters),
              ),

            // Feedback section
            _buildSectionTitle(context, s.feedbackSection),
            SwitchListTile(
              secondary: _medallionIcon(context, Icons.vibration),
              title: Text(s.vibrationLabel),
              subtitle: Text(s.vibrationSubtitle),
              value: settings.settings.vibrationEnabled,
              activeThumbColor: Theme.of(context).colorScheme.primary,
              onChanged: (value) async {
                await settings.toggleVibration(value);
              },
            ),
            SwitchListTile(
              secondary: _medallionIcon(context, Icons.music_note),
              title: Text(s.soundLabel),
              subtitle: Text(s.soundSubtitle),
              value: settings.settings.soundEnabled,
              activeThumbColor: Theme.of(context).colorScheme.primary,
              onChanged: (value) async {
                await settings.toggleSound(value);
              },
            ),

            // Appearance section
            _buildSectionTitle(context, s.appearanceSection),
            SwitchListTile(
              secondary: _medallionIcon(context, Icons.dark_mode),
              title: Text(s.darkModeLabel),
              subtitle: Text(s.darkModeSubtitle),
              value: settings.settings.isDarkMode,
              activeThumbColor: Theme.of(context).colorScheme.primary,
              onChanged: (value) async {
                await settings.toggleDarkMode(value);
              },
            ),
            // Language section
            _buildSectionTitle(context, s.languageSection),
            RadioGroup<String>(
              groupValue: settings.settings.languageCode,
              onChanged: (value) => settings.setLanguage(value!),
              child: Column(
                children: [
                  RadioListTile<String>(
                    secondary: _medallionIcon(context, Icons.language),
                    title: Text(s.langSystem),
                    value: 'system',
                  ),
                  RadioListTile<String>(
                    secondary: _medallionIcon(context, Icons.language),
                    title: Text(s.langArabic),
                    value: 'ar',
                  ),
                  RadioListTile<String>(
                    secondary: _medallionIcon(context, Icons.language),
                    title: Text(s.langEnglish),
                    value: 'en',
                  ),
                ],
              ),
            ),

            // Prayer location section
            _buildSectionTitle(context, s.prayerLocationSection),
            ListTile(
              leading: _medallionIcon(context, Icons.location_on),
              title: Text(s.prayerLocationSection),
              subtitle: Text(_prayerLocationSubtitle(context)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showPrayerLocationDialog(context),
            ),

            // Backup section
            _buildSectionTitle(context, s.backupSectionTitle),
            ListTile(
              leading: _medallionIcon(context, Icons.ios_share),
              title: Text(s.exportData),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showExportSheet(context),
            ),
            ListTile(
              leading: _medallionIcon(context, Icons.restore),
              title: Text(s.restoreBackup),
              onTap: () => _showRestoreFlow(context),
            ),

            // About — pushed as a full screen, not a shell tab
            ListTile(
              leading: _medallionIcon(context, Icons.info),
              title: Text(s.aboutApp),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AboutScreen(),
                  ),
                );
              },
            ),
          ],
          ),
        );
      },
    );
  }

  void _showPrayerOffsetDialog(
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

  String _prayerLocationSubtitle(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    if (settings.latitude == null || settings.longitude == null) {
      return S.of(context).prayerLocationNotSet;
    }
    return '${settings.latitude!.toStringAsFixed(3)}, '
        '${settings.longitude!.toStringAsFixed(3)}';
  }

  Future<void> _showPrayerLocationDialog(BuildContext context) async {
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

  void _showExportSheet(BuildContext context) {
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

  Future<void> _showRestoreFlow(BuildContext context) async {
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(title, style: AppTextStyles.display(context)),
        const GoldHairlineDivider(indent: 0),
      ],
    );
  }

  Widget _medallionIcon(BuildContext context, IconData icon,
      {Color? iconColor}) {
    final gold = Theme.of(context).colorScheme.secondary;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: gold, width: 1.2),
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
      ),
      child: Icon(icon,
          color: iconColor ?? Theme.of(context).colorScheme.primary, size: 20),
    );
  }

  String _getIntervalText(S s, int minutes) {
    if (minutes < 60) {
      return s.everyMinutes(minutes);
    } else if (minutes == 60) {
      return s.everyHour;
    } else {
      final hours = minutes ~/ 60;
      return s.everyHours(hours);
    }
  }

  void _showRenameDialog(BuildContext context, CountersProvider counters) {
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

  void _showDeleteDialog(BuildContext context, CountersProvider counters) {
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

  void _showDailyTargetDialog(BuildContext context, CountersProvider counters) {
    final counter = counters.activeCounter;
    showDialog(
      context: context,
      builder: (dialogContext) => _DailyTargetDialog(
        counters: counters,
        counterId: counter.id,
        initialValue: counter.dailyTarget,
      ),
    );
  }

  void _showReminderTypeDialog(
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

  void _showIntervalDialog(BuildContext context, CountersProvider counters) {
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
                title: Text(_getIntervalText(s, minutes)),
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

  void _showDailyTimesDialog(
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
}

class _DailyTargetDialog extends StatefulWidget {
  const _DailyTargetDialog({
    required this.counters,
    required this.counterId,
    required this.initialValue,
  });

  final CountersProvider counters;
  final String counterId;
  final int initialValue;

  @override
  State<_DailyTargetDialog> createState() => _DailyTargetDialogState();
}

class _DailyTargetDialogState extends State<_DailyTargetDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue > 0 ? '${widget.initialValue}' : '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = int.tryParse(_controller.text.trim()) ?? 0;
    await widget.counters.setDailyTarget(widget.counterId, value < 0 ? 0 : value);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      title: Text(s.dailyTargetLabel),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: s.timesCountLabel,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [33, 100, 500, 1000]
                .map(
                  (value) => ActionChip(
                    label: Text('$value'),
                    onPressed: () => _controller.text = '$value',
                  ),
                )
                .toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(s.save),
        ),
      ],
    );
  }
}


