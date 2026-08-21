import 'package:flutter/material.dart';

/// Lightweight app-UI localization: two const string maps, resolved from the
/// ambient locale. Dhikr scripture text intentionally stays Arabic.
class S {
  S._(this._map);

  final Map<String, String> _map;

  String _(String key) => _map[key] ?? key;

  /// Public key lookup for dynamic keys (e.g. tab labels from constants).
  String t(String key) => _(key);

  static final S _ar = S._(_arStrings);
  static final S _en = S._(_enStrings);

  /// Resolves from the ambient locale (set by the language preference).
  static S of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'en' ? _en : _ar;
  }

  // ── Tabs ──
  String get homeTab => _('homeTab');
  String get libraryTab => _('libraryTab');
  String get statsTab => _('statsTab');
  String get settingsTab => _('settingsTab');

  // ── Home ──
  String get bismillah => _('bismillah');
  String get today => _('today');
  String totalLabel(int total) => '${_('totalPrefix')}$total';
  String get targetDone => _('targetDone');
  String streakDays(int days) => _('streakTemplate').replaceAll('{n}', '$days');
  String get tapToCount => _('tapToCount');
  String get tapAnywhereToCount => _('tapAnywhereToCount');
  String get undo => _('undo');
  String get reset => _('reset');
  String get fullscreen => _('fullscreen');
  String get exitFullscreen => _('exitFullscreen');
  String lastUsed(String formatted) =>
      '${_('lastUsedPrefix')}$formatted';

  // ── Dialogs ──
  String get cancel => _('cancel');
  String get confirm => _('confirm');
  String get save => _('save');
  String get add => _('add');
  String get deleteAction => _('deleteAction');
  String get restoreAction => _('restoreAction');

  String get addCounterTitle => _('addCounterTitle');
  String get dhikrNameLabel => _('dhikrNameLabel');
  String get resetCounterTitle => _('resetCounterTitle');
  String get resetConfirmBody => _('resetConfirmBody');
  String get resetAlsoTotal => _('resetAlsoTotal');

  // ── Library ──
  String get morningSection => _('morningSection');
  String get eveningSection => _('eveningSection');
  String get generalSection => _('generalSection');

  // ── Stats ──
  String get seg7 => _('seg7');
  String get seg30 => _('seg30');
  String get seg90 => _('seg90');
  String windowLabel(int days) => _('window${days}d');
  String get totalAllTime => _('totalAllTime');
  String get bestDay => _('bestDay');
  String get currentStreakLabel => _('currentStreakLabel');
  String get longestStreakLabel => _('longestStreakLabel');

  // ── Settings ──
  String get activeCounterSection => _('activeCounterSection');
  String get nameLabel => _('nameLabel');
  String get dailyTargetLabel => _('dailyTargetLabel');
  String timesUnit(int n) => _('timesTemplate').replaceAll('{n}', '$n');
  String get notSet => _('notSet');
  String get remindersLabel => _('remindersLabel');
  String get remindersSubtitle => _('remindersSubtitle');
  String get notifPermissionDenied => _('notifPermissionDenied');
  String get reminderTypeLabel => _('reminderTypeLabel');
  String get intervalTypeDesc => _('intervalTypeDesc');
  String get dailyTypeDesc => _('dailyTypeDesc');
  String get intervalLabel => _('intervalLabel');
  String get dailyTimesLabel => _('dailyTimesLabel');
  String get noTimesSet => _('noTimesSet');
  String timesSetCount(int n) =>
      _('timesSetTemplate').replaceAll('{n}', '$n');
  String get deleteCounterLabel => _('deleteCounterLabel');
  String get feedbackSection => _('feedbackSection');
  String get vibrationLabel => _('vibrationLabel');
  String get vibrationSubtitle => _('vibrationSubtitle');
  String get soundLabel => _('soundLabel');
  String get soundSubtitle => _('soundSubtitle');
  String get appearanceSection => _('appearanceSection');
  String get darkModeLabel => _('darkModeLabel');
  String get darkModeSubtitle => _('darkModeSubtitle');
  String get languageSection => _('languageSection');
  String get langSystem => _('langSystem');
  String get langArabic => _('langArabic');
  String get langEnglish => _('langEnglish');
  String get aboutApp => _('aboutApp');
  String get renameTitle => _('renameTitle');
  String deleteConfirmBody(String name) =>
      _('deleteConfirmTemplate').replaceAll('{name}', name);
  String get repeatTypeOption => _('repeatTypeOption');
  String get repeatTypeSub => _('repeatTypeSub');
  String get dailyTypeOption => _('dailyTypeOption');
  String get dailyTypeSub => _('dailyTypeSub');
  String get prayerTypeOption => _('prayerTypeOption');
  String get prayerTypeSub => _('prayerTypeSub');
  String get prayerOffsetLabel => _('prayerOffsetLabel');
  String prayerOffsetSubtitle(int minutes) =>
      _('prayerOffsetTemplate').replaceAll('{n}', '$minutes');
  String get prayerLocationSection => _('prayerLocationSection');
  String get prayerLocationNotSet => _('prayerLocationNotSet');
  String get latitudeLabel => _('latitudeLabel');
  String get longitudeLabel => _('longitudeLabel');
  String get methodLabel => _('methodLabel');
  String get addTime => _('addTime');
  String get timesCountLabel => _('timesCountLabel');
  String everyMinutes(int n) =>
      _('everyMinutesTemplate').replaceAll('{n}', '$n');
  String get everyHour => _('everyHour');
  String everyHours(int n) =>
      _('everyHoursTemplate').replaceAll('{n}', '$n');

  // ── Backup ──
  String get backupSectionTitle => _('backupSectionTitle');
  String get exportData => _('exportData');
  String get exportJsonOption => _('exportJsonOption');
  String get exportCsvOption => _('exportCsvOption');
  String get restoreBackup => _('restoreBackup');
  String get restoreConfirmBody => _('restoreConfirmBody');
  String get restoreSuccess => _('restoreSuccess');
  String get errorExportFailed => _('errorExportFailed');
  String get errorRestoreFailed => _('errorRestoreFailed');
  String get errorReadFileFailed => _('errorReadFileFailed');
  String backupError(String code) => _('backupError_$code');
}

const Map<String, String> _arStrings = {
  'homeTab': 'الرئيسية',
  'libraryTab': 'الأذكار',
  'statsTab': 'الإحصائيات',
  'settingsTab': 'الإعدادات',

  'bismillah': 'بسم الله الرحمن الرحيم',
  'today': 'اليوم',
  'totalPrefix': 'الإجمالي: ',
  'targetDone': 'تم الهدف',
  'streakTemplate': '{n} يوم متتالي',
  'tapToCount': 'اضغط للعد',
  'tapAnywhereToCount': 'اضغط في أي مكان للعد',
  'undo': 'تراجع',
  'reset': 'إعادة تعيين',
  'fullscreen': 'ملء الشاشة',
  'exitFullscreen': 'إنهاء ملء الشاشة',
  'lastUsedPrefix': 'آخر استخدام: ',

  'cancel': 'إلغاء',
  'confirm': 'تأكيد',
  'save': 'حفظ',
  'add': 'إضافة',
  'deleteAction': 'حذف',
  'restoreAction': 'استعادة',

  'addCounterTitle': 'إضافة عداد',
  'dhikrNameLabel': 'اسم الذكر',
  'resetCounterTitle': 'إعادة تعيين العداد',
  'resetConfirmBody': 'هل أنت متأكد من إعادة تعيين العداد؟',
  'resetAlsoTotal': 'إعادة تعيين العدد التراكمي أيضاً',

  'morningSection': 'أذكار الصباح',
  'eveningSection': 'أذكار المساء',
  'generalSection': 'أذكار عامة',

  'seg7': '٧ أيام',
  'seg30': '٣٠ يومًا',
  'seg90': '٩٠ يومًا',
  'window7d': 'آخر ٧ أيام',
  'window30d': 'آخر ٣٠ يومًا',
  'window90d': 'آخر ٩٠ يومًا',
  'totalAllTime': 'الإجمالي الكلي',
  'bestDay': 'أفضل يوم',
  'currentStreakLabel': 'السلسلة الحالية',
  'longestStreakLabel': 'أطول سلسلة',

  'activeCounterSection': 'العداد الحالي',
  'nameLabel': 'الاسم',
  'dailyTargetLabel': 'الهدف اليومي',
  'timesTemplate': '{n} مرة',
  'notSet': 'غير محدد',
  'remindersLabel': 'التذكيرات',
  'remindersSubtitle': 'استلام تذكيرات لهذا الذكر',
  'notifPermissionDenied': 'لم يتم منح إذن الإشعارات',
  'reminderTypeLabel': 'نوع التذكير',
  'intervalTypeDesc': 'تذكير متكرر كل مدة محددة',
  'dailyTypeDesc': 'تذكير في أوقات يومية',
  'intervalLabel': 'فاصل التذكير',
  'dailyTimesLabel': 'أوقات التذكير اليومية',
  'noTimesSet': 'لم يتم تحديد أوقات',
  'timesSetTemplate': '{n} أوقات محددة',
  'deleteCounterLabel': 'حذف العداد',
  'feedbackSection': 'الاستجابة',
  'vibrationLabel': 'الاهتزاز',
  'vibrationSubtitle': 'اهتزاز خفيف عند الضغط على زر العدد',
  'soundLabel': 'الصوت',
  'soundSubtitle': 'نقرة خفيفة عند الضغط على زر العدد',
  'appearanceSection': 'المظهر',
  'darkModeLabel': 'الوضع الداكن',
  'darkModeSubtitle': 'استخدام ألوان داكنة للتطبيق',
  'languageSection': 'اللغة',
  'langSystem': 'تلقائي',
  'langArabic': 'العربية',
  'langEnglish': 'English',
  'aboutApp': 'حول التطبيق',
  'renameTitle': 'تعديل الاسم',
  'deleteConfirmTemplate': 'هل أنت متأكد من حذف "{name}"؟',
  'repeatTypeOption': 'تذكير متكرر',
  'repeatTypeSub': 'كل مدة محددة',
  'dailyTypeOption': 'تذكير يومي',
  'prayerTypeOption': 'تذكير بعد الصلاة',
  'dailyTypeSub': 'في أوقات محددة يومياً',
  'prayerTypeSub': 'بعد كل صلاة بمقدار محدد',
  'prayerOffsetLabel': 'بعد كل صلاة',
  'prayerOffsetTemplate': 'بعد {n} دقيقة من الأذان',
  'addTime': 'إضافة وقت',
  'timesCountLabel': 'عدد المرات',
  'everyMinutesTemplate': 'كل {n} دقيقة',
  'everyHour': 'كل ساعة',
  'everyHoursTemplate': 'كل {n} ساعة',
  'prayerLocationSection': 'موقع الصلاة',
  'prayerLocationNotSet': 'غير محددة — مطلوبة لتذكيرات الصلاة',
  'latitudeLabel': 'خط العرض',
  'longitudeLabel': 'خط الطول',
  'methodLabel': 'طريقة الحساب',

  'backupSectionTitle': 'النسخ الاحتياطي',
  'exportData': 'تصدير البيانات',
  'exportJsonOption': 'نسخة احتياطية كاملة (JSON)',
  'exportCsvOption': 'ملف CSV (لبرامج الجداول)',
  'restoreBackup': 'استعادة نسخة احتياطية',
  'restoreConfirmBody': 'سيتم استبدال جميع البيانات الحالية. هل أنت متأكد؟',
  'restoreSuccess': 'تمت الاستعادة بنجاح',
  'errorExportFailed': 'تعذر تصدير البيانات',
  'errorRestoreFailed': 'تعذرت الاستعادة',
  'errorReadFileFailed': 'تعذر قراءة الملف',
  'backupError_invalidFormat': 'ملف النسخة الاحتياطية غير صالح',
  'backupError_versionMismatch': 'إصدار النسخة الاحتياطية غير مدعوم',
  'backupError_emptyBackup': 'لا توجد بيانات في النسخة الاحتياطية',
};

const Map<String, String> _enStrings = {
  'homeTab': 'Home',
  'libraryTab': 'Adhkar',
  'statsTab': 'Stats',
  'settingsTab': 'Settings',

  'bismillah': 'In the name of Allah, the Most Gracious, the Most Merciful',
  'today': 'Today',
  'totalPrefix': 'Total: ',
  'targetDone': 'Target reached',
  'streakTemplate': '{n} days in a row',
  'tapToCount': 'Tap to count',
  'tapAnywhereToCount': 'Tap anywhere to count',
  'undo': 'Undo',
  'reset': 'Reset',
  'fullscreen': 'Full screen',
  'exitFullscreen': 'Exit full screen',
  'lastUsedPrefix': 'Last used: ',

  'cancel': 'Cancel',
  'confirm': 'Confirm',
  'save': 'Save',
  'add': 'Add',
  'deleteAction': 'Delete',
  'restoreAction': 'Restore',

  'addCounterTitle': 'Add counter',
  'dhikrNameLabel': 'Dhikr name',
  'resetCounterTitle': 'Reset counter',
  'resetConfirmBody': 'Are you sure you want to reset this counter?',
  'resetAlsoTotal': 'Also reset the lifetime total',

  'morningSection': 'Morning adhkar',
  'eveningSection': 'Evening adhkar',
  'generalSection': 'General adhkar',

  'seg7': '7 days',
  'seg30': '30 days',
  'seg90': '90 days',
  'window7d': 'Last 7 days',
  'window30d': 'Last 30 days',
  'window90d': 'Last 90 days',
  'totalAllTime': 'Lifetime total',
  'bestDay': 'Best day',
  'currentStreakLabel': 'Current streak',
  'longestStreakLabel': 'Longest streak',

  'activeCounterSection': 'Active counter',
  'nameLabel': 'Name',
  'dailyTargetLabel': 'Daily target',
  'timesTemplate': '{n} times',
  'notSet': 'Not set',
  'remindersLabel': 'Reminders',
  'remindersSubtitle': 'Receive reminders for this dhikr',
  'notifPermissionDenied': 'Notification permission was not granted',
  'reminderTypeLabel': 'Reminder type',
  'intervalTypeDesc': 'Repeat every set interval',
  'dailyTypeDesc': 'Remind at fixed daily times',
  'intervalLabel': 'Reminder interval',
  'dailyTimesLabel': 'Daily reminder times',
  'noTimesSet': 'No times set',
  'timesSetTemplate': '{n} times set',
  'deleteCounterLabel': 'Delete counter',
  'feedbackSection': 'Feedback',
  'vibrationLabel': 'Vibration',
  'vibrationSubtitle': 'Light haptic on each count',
  'soundLabel': 'Sound',
  'soundSubtitle': 'Soft click on each count',
  'appearanceSection': 'Appearance',
  'darkModeLabel': 'Dark mode',
  'darkModeSubtitle': 'Use darker colors for the app',
  'languageSection': 'Language',
  'langSystem': 'System',
  'langArabic': 'العربية',
  'langEnglish': 'English',
  'aboutApp': 'About',
  'renameTitle': 'Rename',
  'deleteConfirmTemplate': 'Delete "{name}"?',
  'repeatTypeOption': 'Repeating reminder',
  'repeatTypeSub': 'Every set interval',
  'dailyTypeOption': 'Daily reminder',
  'prayerTypeOption': 'After-prayer reminder',
  'dailyTypeSub': 'At fixed times every day',
  'prayerTypeSub': 'A set time after each prayer',
  'prayerOffsetLabel': 'After each prayer',
  'prayerOffsetTemplate': '{n} minutes after the adhan',
  'addTime': 'Add time',
  'timesCountLabel': 'Number of repetitions',
  'everyMinutesTemplate': 'Every {n} minutes',
  'everyHour': 'Every hour',
  'everyHoursTemplate': 'Every {n} hours',
  'prayerLocationSection': 'Prayer location',
  'prayerLocationNotSet': 'Not set — required for prayer reminders',
  'latitudeLabel': 'Latitude',
  'longitudeLabel': 'Longitude',
  'methodLabel': 'Calculation method',

  'backupSectionTitle': 'Backup',
  'exportData': 'Export data',
  'exportJsonOption': 'Full backup (JSON)',
  'exportCsvOption': 'CSV file (for spreadsheets)',
  'restoreBackup': 'Restore backup',
  'restoreConfirmBody':
      'All current data will be replaced. Are you sure?',
  'restoreSuccess': 'Restored successfully',
  'errorExportFailed': 'Could not export data',
  'errorRestoreFailed': 'Restore failed',
  'errorReadFileFailed': 'Could not read the file',
  'backupError_invalidFormat': 'Invalid backup file',
  'backupError_versionMismatch': 'Unsupported backup version',
  'backupError_emptyBackup': 'Backup contains no data',
};




