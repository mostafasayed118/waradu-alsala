# Data Export / Backup & Restore — Design Spec

> **Status:** approved design → this spec. Next: `writing-plans` skill.

**Goal:** Let the user export their data (counters, history, settings, active counter) to a file they can save or share, and restore it later — e.g., when moving to a new phone.

**Approach:** Manual-only, from the Settings screen. A dedicated `BackupService` handles serialization/deserialization in a pure, testable layer. Export produces both a full-fidelity JSON backup and a human-readable CSV. Restore reads JSON only and **replaces** all current data after explicit confirmation. No automatic/background backup.

---

## 1. Backup file formats

### JSON (full fidelity — the only restore source)

Envelope with a version field for future-proofing:

```json
{
  "version": 1,
  "exportedAt": "2026-08-20T10:00:00.000Z",
  "activeCounterId": "salawat",
  "settings": { "vibrationEnabled": true, "isDarkMode": false },
  "counters": [ /* existing AdhkarCounter.toJson() objects */ ]
}
```

- `version: 1` — backups with a different version are rejected.
- `exportedAt` — ISO-8601 timestamp, informational only.
- `counters` reuse the existing `AdhkarCounter.toJson()`/`fromJson` — no duplicated model logic.
- `settings` reuse existing `AppSettings.toJson()`/`fromJson`.

### CSV (export-only, human-readable)

UTF-8 **with BOM** (Excel renders Arabic correctly). Two blocks:

**Block 1 — `counters`**, header row:
`id, name, totalCount, dailyTarget, remindersEnabled, reminderType, reminderIntervalMinutes, dailyReminderTimes, lastUsedAt, lastResetAt`

- `reminderType` exported as `interval` / `daily` (readable, not enum index).
- `dailyReminderTimes` joined with `;` (e.g. `480;1020`).
- `lastUsedAt` / `lastResetAt` as ISO-8601 strings; empty when null.

**Block 2 — `history`**, header row:
`counterId, counterName, date, count`

- One row per counter per day with a non-zero count, using the existing `dailyKey()` format (`yyyy-MM-dd`).
- `counterName` repeated for readability.

Both blocks share the same columns rule; fields escaped per RFC 4180 (wrap in quotes, double inner quotes) — applied to every field unconditionally, so Arabic text, commas, and quotes are always safe. Blocks separated by a blank line.

**Restore accepts JSON only.** CSV is a readable export, never a restore source.

---

## 2. `BackupService` (new: `lib/services/backup_service.dart`)

Pure Dart, no Flutter UI imports — fully unit-testable.

```dart
class BackupService {
  BackupService({required StorageService storage});

  String buildJsonBackup();                // serialize counters+settings+activeId
  String buildCsv();                       // serialize counters + history blocks
  BackupData parseJsonBackup(String raw);  // validate; throws BackupException
  Future<void> applyBackup(BackupData data); // write to storage (replace-all)
}

class BackupData {
  final List<AdhkarCounter> counters;
  final AppSettings settings;
  final String activeCounterId;
}
```

Behavior:

- `buildJsonBackup` reads current state from `StorageService`, returns pretty-printed JSON.
- `buildCsv` reads current state, returns CSV with BOM (`\uFEFF` prefix).
- `parseJsonBackup` — strict: must decode as a JSON object with `version == 1`; `counters` must be a non-empty list of valid `AdhkarCounter` objects (missing/invalid fields → error, never silent defaults); `settings` required; `activeCounterId` required and must reference an existing counter (else falls back to first counter; empty list is invalid).
- `applyBackup` writes counters, settings, and active counter id via existing `StorageService` methods (`saveCounters`, `saveSettings`, `saveActiveCounterId`). Pure storage write — providers and notifications are handled by the caller.

### `BackupException`

`BackupException` carries a machine-readable `code`:

| code | meaning |
|------|---------|
| `invalidFormat` | not valid JSON / missing required fields / invalid counter data |
| `versionMismatch` | `version` != 1 |
| `emptyBackup` | no counters in backup |

Codes map to Arabic messages in `app_strings.dart` (new `AppStrings.backupError(code)` helper or equivalent).

---

## 3. UI flow (`lib/screens/settings_screen.dart`)

New section **"النسخ الاحتياطي"** placed after the "المظهر" section, before "حول التطبيق", using the existing `_buildSectionTitle` + `ListTile` pattern.

### Export

- ListTile **"تصدير البيانات"** (icon `Icons.ios_share`) → bottom sheet with two options:
  - **"نسخة احتياطية كاملة (JSON)"** — build JSON, write to temp file (`path_provider`), share via `share_plus` as `zikr-backup-YYYY-MM-DD.json`.
  - **"ملف CSV (لبرامج الجداول)"** — same flow, `zikr-backup-YYYY-MM-DD.csv`.
- Share sheet cancelled → silent no-op.

### Restore

- ListTile **"استعادة نسخة احتياطية"** (icon `Icons.restore`) → `file_picker` (JSON files only) →
  1. Read file, `parseJsonBackup` — **parse and validate before any dialog**; on error show Arabic error SnackBar, nothing touched.
  2. Confirmation `AlertDialog`: "سيتم استبدال جميع البيانات الحالية. هل أنت متأكد؟" with `إلغاء` / `استعادة` (red destructive button).
  3. On confirm: `applyBackup` → `counters.load()` + `settings.load()` → reschedule all reminders via existing `NotificationService` → success SnackBar "تمت الاستعادة بنجاح".
- File pick cancelled → silent no-op.

---

## 4. Error handling

| Case | Behavior |
|------|----------|
| Malformed/corrupt JSON | Error SnackBar (`invalidFormat`), no data touched — parse-before-write |
| Unsupported version | Error SnackBar (`versionMismatch`) |
| Empty backup (no counters) | Rejected (`emptyBackup`) |
| Share/picker cancelled | No-op |
| Restore success | Success SnackBar + reminders rescheduled |
| Temp-file write or share failure | Arabic error SnackBar, state unchanged |

All strings centralized in `app_strings.dart` — matches existing pattern.

---

## 5. Testing

### `test/backup_service_test.dart` (unit)

- JSON round-trip: `buildJsonBackup` → `parseJsonBackup` → `applyBackup` preserves counters, history maps, settings, active id exactly (including a custom counter with reminders).
- CSV output: BOM prefix present; correct headers for both blocks; RFC 4180 escaping (counter name containing comma and quotes); history rows one per counter-day; interval/daily reminder type words.
- `parseJsonBackup` failures: malformed JSON → `invalidFormat`; `version: 2` → `versionMismatch`; empty counters → `emptyBackup`; counter missing `name` → `invalidFormat`.
- Empty state (no counters) still exports valid JSON with empty counters list — but `parseJsonBackup` rejects it on restore.
- `applyBackup` with mocked `StorageService` calls the three save methods with the parsed values.

### `test/widget_test.dart` (extend)

- Export tile opens bottom sheet with both options.
- Restore flow: pick (mocked) → confirm dialog appears → confirm → success SnackBar; cancel → nothing changes.
- Invalid file picked → error SnackBar, no confirm dialog.

---

## 6. Dependencies

Add to `pubspec.yaml`:

- `share_plus` — share sheet for exported files (Android + iOS).
- `file_picker` — pick the JSON file for restore (Android + iOS).
- `path_provider` — temp directory for export files.

CSV escaping is hand-rolled (~15 lines, RFC 4180) to keep dependencies minimal; covered by unit tests.

---

## 7. Non-goals

- No automatic/scheduled backups.
- No CSV restore.
- No merge-on-restore (replace only).
- No cloud sync or export preview screen.
- No changes to `StorageService` or existing models (`AdhkarCounter`, `AppSettings` keep their current shape).