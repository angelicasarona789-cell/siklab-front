import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_data.dart';
import '../models/user_session.dart';
import 'api_service.dart';

class DemoCertificateAccount {
  final int id;
  final String name;
  final String level;
  final int practiceTimeSeconds;

  const DemoCertificateAccount({
    required this.id,
    required this.name,
    required this.level,
    required this.practiceTimeSeconds,
  });
}

class DemoCertificateAccounts {
  static const accounts = [
    DemoCertificateAccount(
      id: 910001,
      name: 'Mars',
      level: 'Beginner',
      practiceTimeSeconds: 9900,
    ),
    DemoCertificateAccount(
      id: 910002,
      name: 'Edcel',
      level: 'Intermediate',
      practiceTimeSeconds: 8100,
    ),
    DemoCertificateAccount(
      id: 910003,
      name: 'Miguel',
      level: 'Advanced',
      practiceTimeSeconds: 6300,
    ),
    DemoCertificateAccount(
      id: 910004,
      name: 'Jelord',
      level: 'Intermediate',
      practiceTimeSeconds: 7800,
    ),
    DemoCertificateAccount(
      id: 910005,
      name: 'Mcking',
      level: 'Beginner',
      practiceTimeSeconds: 9300,
    ),
  ];

  static Future<void> activate(DemoCertificateAccount account) async {
    final prefs = await SharedPreferences.getInstance();
    final questions =
        <({String language, QuizCategory category, int number})>[];

    for (final quiz in languageQuizzes) {
      final languageKey = _languageKey(quiz.name);
      final completedIds = <String>[];
      for (final entry in quiz.categories.entries) {
        for (var index = 0; index < entry.value.length; index++) {
          final questionNumber = index + 1;
          final questionId = '${entry.key.name}_$questionNumber';
          completedIds.add(questionId);
          questions.add((
            language: languageKey,
            category: entry.key,
            number: questionNumber,
          ));
        }
      }

      final suffix = '_${account.id}';
      await prefs.setStringList(
        'answered_questions_$languageKey$suffix',
        completedIds,
      );
      await prefs.setStringList(
        'completed_module_topics_$languageKey$suffix',
        completedIds,
      );
      final completedOn = DateTime.now().toIso8601String();
      await prefs.setString(
        'certificate_progress_modules_${account.id}_$languageKey',
        completedOn,
      );
      await prefs.setString(
        'certificate_progress_practice_${account.id}_$languageKey',
        completedOn,
      );
    }

    final capacity = questions.fold<int>(
      0,
      (total, question) => total + _questionLimitSeconds(question.category),
    );
    if (account.practiceTimeSeconds < questions.length ||
        account.practiceTimeSeconds > capacity) {
      throw StateError(
        'Could not assign ${account.level} demo timing within the configured question limits.',
      );
    }

    var remainingSeconds = account.practiceTimeSeconds;
    for (var index = 0; index < questions.length; index++) {
      final question = questions[index];
      final questionsLeft = questions.length - index;
      final evenShare = (remainingSeconds + questionsLeft - 1) ~/ questionsLeft;
      final seconds =
          evenShare.clamp(1, _questionLimitSeconds(question.category)).toInt();
      remainingSeconds -= seconds;
      await prefs.setInt(
        'practice_question_time_${account.id}_${question.language}_'
        '${question.category.name}_${question.number}',
        seconds,
      );
    }

    await prefs.setBool('assessment_completed_${account.id}', true);
    ApiService.notifyLocalProgressChanged();
    UserSession().setUser(
      id: account.id,
      name: account.name,
      email: _email(account),
      assessmentCompleted: true,
    );
  }

  static int _questionLimitSeconds(QuizCategory category) {
    switch (category) {
      case QuizCategory.beginner:
        return const Duration(minutes: 3).inSeconds;
      case QuizCategory.intermediate:
        return const Duration(minutes: 6).inSeconds;
      case QuizCategory.upperIntermediate:
        return const Duration(minutes: 9).inSeconds;
    }
  }

  static String _languageKey(String language) {
    final normalized = language.trim().toLowerCase();
    return normalized == 'c#' ? 'csharp' : normalized;
  }

  static String _email(DemoCertificateAccount account) =>
      'demo.${account.name.toLowerCase()}@siklab.local';
}
