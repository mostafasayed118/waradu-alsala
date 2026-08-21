import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salawat_app/domain/entities/adhkar_counter.dart';
import 'package:salawat_app/features/counting/counters_provider.dart';
import 'package:salawat_app/features/settings/settings_provider.dart';
import 'package:salawat_app/features/settings/dialogs/daily_target_dialog.dart';
import 'package:salawat_app/features/settings/dialogs/daily_times_dialog.dart';
import 'package:salawat_app/features/settings/dialogs/delete_counter_dialog.dart';
import 'package:salawat_app/features/settings/dialogs/export_sheet.dart';
import 'package:salawat_app/features/settings/dialogs/prayer_location_dialog.dart';
import 'package:salawat_app/features/settings/dialogs/prayer_offset_dialog.dart';
import 'package:salawat_app/features/settings/dialogs/rename_dialog.dart';
import 'package:salawat_app/features/settings/dialogs/reminder_interval_dialog.dart';
import 'package:salawat_app/features/settings/dialogs/reminder_type_dialog.dart';
import 'package:salawat_app/features/settings/dialogs/restore_flow.dart';
import 'package:salawat_app/core/l10n/app_localizations.dart';
import 'package:salawat_app/core/theme/app_text_styles.dart';
import 'package:salawat_app/core/utils/breakpoints.dart';
import 'package:salawat_app/shared/widgets/max_width_box.dart';
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
              onTap: () => showRenameDialog(context, counters),
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
              onTap: () => showDailyTargetDialog(context, counters),
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
                onTap: () => showReminderTypeDialog(context, counters),
              ),
              if (counter.reminderType == ReminderType.interval)
                ListTile(
                  title: Text(s.intervalLabel),
                  subtitle:
                      Text(reminderIntervalLabel(s, counter.reminderIntervalMinutes)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showReminderIntervalDialog(context, counters),
                ),
              if (counter.reminderType == ReminderType.prayer)
                ListTile(
                  title: Text(s.prayerOffsetLabel),
                  subtitle: Text(s.prayerOffsetSubtitle(
                      counter.prayerOffsetMinutes)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showPrayerOffsetDialog(context, counters),
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
                  onTap: () => showDailyTimesDialog(context, counters),
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
                onTap: () => showDeleteCounterDialog(context, counters),
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
              onTap: () => showPrayerLocationDialog(context),
            ),

            // Backup section
            _buildSectionTitle(context, s.backupSectionTitle),
            ListTile(
              leading: _medallionIcon(context, Icons.ios_share),
              title: Text(s.exportData),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showExportSheet(context),
            ),
            ListTile(
              leading: _medallionIcon(context, Icons.restore),
              title: Text(s.restoreBackup),
              onTap: () => showRestoreFlow(context),
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

  String _prayerLocationSubtitle(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    if (settings.latitude == null || settings.longitude == null) {
      return S.of(context).prayerLocationNotSet;
    }
    return '${settings.latitude!.toStringAsFixed(3)}, '
        '${settings.longitude!.toStringAsFixed(3)}';
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
}
