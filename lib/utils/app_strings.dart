import '../services/backup_service.dart';

class AppStrings {
  AppStrings._();

  static const String appName = 'ورد الصلاة';
  static const String salawat = 'اللهم صلِّ على سيدنا محمد وعلى آل سيدنا محمد';
  static const String salawatHome = 'اللهم صلِّ على سيدنا محمد\nوعلى آل سيدنا محمد';
  static const String reminderBody = 'حان وقت الذكر';
  static const String targetReachedTitle = 'أكملت وردك اليومي';
  static const String targetReachedBody = 'لقد وصلت إلى هدفك اليومي';
  static const String backupSectionTitle = 'النسخ الاحتياطي';
  static const String exportData = 'تصدير البيانات';
  static const String exportJsonOption = 'نسخة احتياطية كاملة (JSON)';
  static const String exportCsvOption = 'ملف CSV (لبرامج الجداول)';
  static const String restoreBackup = 'استعادة نسخة احتياطية';
  static const String restoreConfirmBody =
      'سيتم استبدال جميع البيانات الحالية. هل أنت متأكد؟';
  static const String restoreSuccess = 'تمت الاستعادة بنجاح';
  static const String errorInvalidFormat = 'ملف النسخة الاحتياطية غير صالح';
  static const String errorVersionMismatch =
      'إصدار النسخة الاحتياطية غير مدعوم';
  static const String errorEmptyBackup = 'لا توجد بيانات في النسخة الاحتياطية';
  static const String errorExportFailed = 'تعذر تصدير البيانات';
  static const String errorRestoreFailed = 'تعذرت الاستعادة';
  static const String errorReadFileFailed = 'تعذر قراءة الملف';

  static String backupErrorMessage(BackupErrorCode code) {
    switch (code) {
      case BackupErrorCode.invalidFormat:
        return errorInvalidFormat;
      case BackupErrorCode.versionMismatch:
        return errorVersionMismatch;
      case BackupErrorCode.emptyBackup:
        return errorEmptyBackup;
    }
  }
}
