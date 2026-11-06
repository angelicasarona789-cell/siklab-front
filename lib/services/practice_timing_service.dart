import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_data.dart';
import '../models/user_session.dart';

class PracticeTimingService {
  static const cooldownDuration = Duration(minutes: 5);

  static Duration questionDuration(QuizCategory category) {
    switch (category) {
      case QuizCategory.beginner:
        return const Duration(minutes: 3);
      case QuizCategory.intermediate:
        return const Duration(minutes: 6);
      case QuizCategory.upperIntermediate:
        return const Duration(minutes: 9);
    }
  }

  static Duration categoryDuration(QuizCategory category, int questionCount) =>
      Duration(
        seconds: questionDuration(category).inSeconds * questionCount,
      );

  static String formatDuration(Duration duration) {
    final totalMinutes = duration.inMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  static String _languageKey(String language) {
    final normalized = language.trim().toLowerCase();
    return normalized == 'c#' ? 'csharp' : normalized;
  }

  static String _accountPrefix() {
    final userId = UserSession().dbId;
    return userId > 0 ? '${userId}_' : '';
  }

  static String _questionDeadlineKey(
    String language,
    QuizCategory category,
    int questionNumber,
  ) =>
      'practice_deadline_${_accountPrefix()}${_languageKey(language)}_'
      '${category.name}_$questionNumber';

  static String _cooldownKey(String language, QuizCategory category) =>
      'practice_cooldown_${_accountPrefix()}${_languageKey(language)}_'
      '${category.name}';

  static String _questionTimeKey(
    String language,
    QuizCategory category,
    int questionNumber,
  ) =>
      'practice_question_time_${_accountPrefix()}${_languageKey(language)}_'
      '${category.name}_$questionNumber';

  static Future<DateTime?> getCooldown(
    String language,
    QuizCategory category,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _cooldownKey(language, category);
    final value = prefs.getInt(key);
    if (value != null) {
      final until = DateTime.fromMillisecondsSinceEpoch(value);
      if (until.isAfter(DateTime.now())) return until;
      await prefs.remove(key);
    }

    final deadlinePrefix =
        'practice_deadline_${_accountPrefix()}${_languageKey(language)}_'
        '${category.name}_';
    for (final deadlineKey in prefs.getKeys()) {
      if (!deadlineKey.startsWith(deadlinePrefix)) continue;
      final deadlineValue = prefs.getInt(deadlineKey);
      if (deadlineValue == null ||
          deadlineValue > DateTime.now().millisecondsSinceEpoch) {
        continue;
      }
      final questionNumber = int.tryParse(
        deadlineKey.substring(deadlinePrefix.length),
      );
      if (questionNumber == null) {
        throw FormatException('Invalid practice timer key: $deadlineKey');
      }
      await expireQuestion(
        language: language,
        category: category,
        questionNumber: questionNumber,
      );
      final cooldownValue = prefs.getInt(key);
      if (cooldownValue != null) {
        return DateTime.fromMillisecondsSinceEpoch(cooldownValue);
      }
    }
    return null;
  }

  static Future<Map<QuizCategory, DateTime?>> getCooldowns(
    String language,
  ) async {
    final values = <QuizCategory, DateTime?>{};
    for (final category in QuizCategory.values) {
      values[category] = await getCooldown(language, category);
    }
    return values;
  }

  static Future<DateTime> startOrResumeQuestion({
    required String language,
    required QuizCategory category,
    required int questionNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final deadlineKey =
        _questionDeadlineKey(language, category, questionNumber);
    final storedDeadline = prefs.getInt(deadlineKey);
    if (storedDeadline != null) {
      final deadline = DateTime.fromMillisecondsSinceEpoch(storedDeadline);
      if (deadline.isAfter(DateTime.now())) return deadline;
      await expireQuestion(
        language: language,
        category: category,
        questionNumber: questionNumber,
      );
      return deadline;
    }

    final cooldownUntil = await getCooldown(language, category);
    if (cooldownUntil != null) {
      throw StateError(
        'This practice is unavailable until ${cooldownUntil.toLocal()}.',
      );
    }

    final deadline = DateTime.now().add(questionDuration(category));
    await prefs.setInt(deadlineKey, deadline.millisecondsSinceEpoch);
    return deadline;
  }

  static Future<void> expireQuestion({
    required String language,
    required QuizCategory category,
    required int questionNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs
        .remove(_questionDeadlineKey(language, category, questionNumber));
    await prefs.setInt(
      _cooldownKey(language, category),
      DateTime.now().add(cooldownDuration).millisecondsSinceEpoch,
    );
  }

  static Future<void> recordQuestionTime({
    required String language,
    required QuizCategory category,
    required int questionNumber,
    required int elapsedSeconds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _questionTimeKey(language, category, questionNumber);
    if (prefs.containsKey(key)) return;
    final maximum = questionDuration(category).inSeconds;
    await prefs.setInt(key, elapsedSeconds.clamp(1, maximum).toInt());
  }

  static Future<void> completeQuestion({
    required String language,
    required QuizCategory category,
    required int questionNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs
        .remove(_questionDeadlineKey(language, category, questionNumber));
  }

  static Future<int> getTotalPracticeSeconds({String? language}) async {
    final prefs = await SharedPreferences.getInstance();
    final accountPrefix = _accountPrefix();
    final keyPrefix = 'practice_question_time_$accountPrefix';
    final languagePrefix =
        language == null ? null : '${_languageKey(language)}_';
    var totalSeconds = 0;
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(keyPrefix)) continue;
      if (languagePrefix != null &&
          !key.startsWith('$keyPrefix$languagePrefix')) {
        continue;
      }
      totalSeconds += prefs.getInt(key) ?? 0;
    }
    return totalSeconds;
  }

  static Future<int> getRecordedPracticeQuestionCount({
    String? language,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accountPrefix = _accountPrefix();
    final keyPrefix = 'practice_question_time_$accountPrefix';
    final languagePrefix =
        language == null ? null : '${_languageKey(language)}_';
    return prefs.getKeys().where((key) {
      if (!key.startsWith(keyPrefix)) return false;
      return languagePrefix == null ||
          key.startsWith('$keyPrefix$languagePrefix');
    }).length;
  }

  static String? certificationLevelForSeconds(int seconds) {
    if (seconds <= 0) return null;
    if (seconds < const Duration(hours: 2).inSeconds) return 'Advanced';
    if (seconds < const Duration(hours: 2, minutes: 30).inSeconds) {
      return 'Intermediate';
    }
    return 'Beginner';
  }
}
