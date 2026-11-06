import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_session.dart';

class CertificateCompletionDates {
  static const String _modulesPrefix = 'certificate_progress_modules_';
  static const String _practicePrefix = 'certificate_progress_practice_';

  static String _languageKey(String language) {
    final normalized = language.trim().toLowerCase();
    return normalized == 'c#' ? 'csharp' : normalized;
  }

  static String _key(String prefix, String language, int userId) =>
      '$prefix${userId > 0 ? '${userId}_' : ''}${_languageKey(language)}';

  static Future<void> recordModulesCompleted(String language) =>
      _record(_modulesPrefix, language);

  static Future<void> recordPracticeCompleted(String language) =>
      _record(_practicePrefix, language);

  static Future<void> _record(String prefix, String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(prefix, language, UserSession().dbId),
      DateTime.now().toIso8601String(),
    );
  }

  static Future<DateTime?> languageCompletedOn(String language) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = UserSession().dbId;
    final modules = DateTime.tryParse(
      prefs.getString(_key(_modulesPrefix, language, userId)) ?? '',
    );
    final practice = DateTime.tryParse(
      prefs.getString(_key(_practicePrefix, language, userId)) ?? '',
    );
    if (modules == null) return practice;
    if (practice == null) return modules;
    return modules.isAfter(practice) ? modules : practice;
  }

  static Future<DateTime?> overallCompletedOn(
    Iterable<String> languages,
  ) async {
    DateTime? latest;
    for (final language in languages) {
      final completedOn = await languageCompletedOn(language);
      if (completedOn != null &&
          (latest == null || completedOn.isAfter(latest))) {
        latest = completedOn;
      }
    }
    return latest;
  }

  static bool isProgressDateKey(String key, int userId) {
    if (userId <= 0) {
      return key.startsWith(_modulesPrefix) || key.startsWith(_practicePrefix);
    }
    return key.startsWith('$_modulesPrefix${userId}_') ||
        key.startsWith('$_practicePrefix${userId}_');
  }
}
