import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siklab/models/user_session.dart';
import 'package:siklab/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    UserSession().clearAll();
    for (final language in ['Java', 'Python', 'C#', 'JavaScript', 'SQL']) {
      UserSession().updateLanguageProgress(language, 0);
    }
  });

  test('each unique answer advances only its language progress', () async {
    for (final language in ['Java', 'Python', 'C#', 'JavaScript', 'SQL']) {
      expect(
        await ApiService.recordLocalExerciseAttempt(language, 'beginner_1'),
        isTrue,
      );
      expect(UserSession().getLanguageProgress(language),
          ApiService.calculatePracticeProgress(language, {'beginner_1'}));
    }

    expect(
      await ApiService.recordLocalExerciseAttempt('Java', 'beginner_1'),
      isFalse,
    );
    expect(UserSession().getLanguageProgress('Java'),
        ApiService.calculatePracticeProgress('Java', {'beginner_1'}));
    expect(UserSession().getLanguageProgress('Python'),
        ApiService.calculatePracticeProgress('Python', {'beginner_1'}));

    await ApiService.loadLanguageProgress();
    for (final language in ['Java', 'Python', 'C#', 'JavaScript', 'SQL']) {
      expect(UserSession().getLanguageProgress(language),
          ApiService.calculatePracticeProgress(language, {'beginner_1'}));
    }
  });

  test('new accounts show zero progress for all five languages', () async {
    final session = UserSession()
      ..setUser(id: 606, name: 'New learner', email: 'new@test.com');

    await ApiService.loadLanguageProgress();

    expect(
      session.languageProgress,
      {
        'Java': 0.0,
        'Python': 0.0,
        'C#': 0.0,
        'JavaScript': 0.0,
        'SQL': 0.0,
      },
    );
  });

  test('correct answers from before the new tracking format are retained',
      () async {
    SharedPreferences.setMockInitialValues({
      'correct_questions_java': ['beginner_1', 'beginner_2'],
    });
    await ApiService.loadLanguageProgress();

    expect(
      UserSession().getLanguageProgress('Java'),
      ApiService.calculatePracticeProgress(
          'Java', {'beginner_1', 'beginner_2'}),
    );
    expect(
      await ApiService.getAnsweredQuestionIds('Java'),
      {'beginner_1', 'beginner_2'},
    );
  });

  test('module exercise attempts are included in language progress', () async {
    expect(
      await ApiService.recordLocalExerciseAttempt(
        'Java',
        'module_beginner_1',
      ),
      isTrue,
    );
    expect(
      UserSession().getLanguageProgress('Java'),
      ApiService.calculatePracticeProgress('Java', {'module_beginner_1'}),
    );

    await ApiService.loadLanguageProgress();

    expect(
      UserSession().getLanguageProgress('Java'),
      ApiService.calculatePracticeProgress('Java', {'module_beginner_1'}),
    );
  });

  test('progress is capped at 100 percent', () async {
    for (var i = 0; i < 55; i++) {
      await ApiService.recordLocalExerciseAttempt('SQL', 'beginner_$i');
    }

    expect(UserSession().getLanguageProgress('SQL'), 1);
  });

  test('all language percentages use the Practice question totals', () async {
    SharedPreferences.setMockInitialValues({
      'answered_questions_java': ['beginner_1', 'beginner_2'],
      'answered_questions_python': ['beginner_1'],
      'answered_questions_csharp': ['intermediate_1'],
      'answered_questions_javascript': ['upperIntermediate_1'],
      'answered_questions_sql': [],
    });
    UserSession().clearAll();
    UserSession().setUser(id: 212, name: 'Learner', email: 'learner@test.com');

    await ApiService.loadLanguageProgress();

    for (final language in ['Java', 'Python', 'C#', 'JavaScript', 'SQL']) {
      final answered = await ApiService.getAnsweredQuestionIds(language);
      expect(
        UserSession().getLanguageProgress(language),
        ApiService.calculatePracticeProgress(language, answered),
      );
    }
  });

  test('server progress percentages and language aliases are normalized',
      () async {
    ApiService.applyLanguageProgressFromServer({
      'java': 35,
      'csharp': 0.75,
      'JavaScript': 110,
      'unknown-language': 80,
    });

    expect(UserSession().getLanguageProgress('Java'), 0.35);
    expect(UserSession().getLanguageProgress('C#'), 0.75);
    expect(UserSession().getLanguageProgress('JavaScript'), 1);
    expect(UserSession().getLanguageProgress('Python'), 0);
  });

  test('reloading progress returns to the exact Practice calculation',
      () async {
    ApiService.applyLanguageProgressFromServer({'Java': 0.8});
    await ApiService.recordLocalExerciseAttempt('Java', 'beginner_1');
    await ApiService.loadLanguageProgress();
    expect(
      UserSession().getLanguageProgress('Java'),
      ApiService.calculatePracticeProgress('Java', {'beginner_1'}),
    );
  });

  test('only newly registered accounts are asked to complete assessment',
      () async {
    expect(await ApiService.requiresInitialAssessment(42), isFalse);

    await ApiService.clearStaleStateForNewAccount(42);
    expect(await ApiService.requiresInitialAssessment(42), isTrue);

    await ApiService.markAssessmentCompleted(42);
    expect(await ApiService.requiresInitialAssessment(42), isFalse);
  });

  test('exercise progress is isolated per account and restored on login',
      () async {
    final session = UserSession();
    session.setUser(id: 101, name: 'First', email: 'first@example.com');
    const languages = ['Java', 'Python', 'C#', 'JavaScript', 'SQL'];
    for (final language in languages) {
      await ApiService.recordLocalExerciseAttempt(language, 'beginner_1');
    }

    session.clearAll();
    session.setUser(id: 202, name: 'Second', email: 'second@example.com');
    await ApiService.loadLanguageProgress();
    expect(session.languageProgress.values, everyElement(0));

    session.clearAll();
    session.setUser(id: 101, name: 'First', email: 'first@example.com');
    await ApiService.loadLanguageProgress();
    for (final language in languages) {
      expect(
        session.getLanguageProgress(language),
        ApiService.calculatePracticeProgress(language, {'beginner_1'}),
      );
    }

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('answered_questions_java_101'), ['beginner_1']);
    expect(prefs.getStringList('answered_questions_java_202'), isNull);
    expect(prefs.getStringList('answered_questions_sql_101'), ['beginner_1']);
    expect(prefs.getStringList('answered_questions_sql_202'), isNull);
  });

  test('legacy local progress migrates to the first existing account',
      () async {
    SharedPreferences.setMockInitialValues({
      'answered_questions_java': ['beginner_1', 'beginner_2'],
      'completed_module_topics_java': ['beginner_3'],
    });
    final session = UserSession();
    session.setUser(id: 303, name: 'Existing', email: 'existing@example.com');

    await ApiService.loadLanguageProgress();

    expect(
      session.getLanguageProgress('Java'),
      ApiService.calculatePracticeProgress(
        'Java',
        {'beginner_1', 'beginner_2'},
      ),
    );
    expect(
      await ApiService.getCompletedModuleTopicIds('Java'),
      {'beginner_3'},
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('answered_questions_java'), isNull);
    expect(prefs.getStringList('answered_questions_java_303'),
        ['beginner_1', 'beginner_2']);
  });

  test('new account cleanup starts progress and module completion at zero',
      () async {
    SharedPreferences.setMockInitialValues({
      'answered_questions_java': ['old_account_question'],
      'answered_questions_java_404': ['beginner_1'],
      'completed_module_topics_java_404': ['beginner_2'],
      'correct_exercise_xp_404': 50,
      'correct_exercise_completed_404': 1,
    });
    final session = UserSession()
      ..setUser(id: 404, name: 'New', email: 'new@example.com');
    session.updateLanguageProgress('Java', 0.5);
    session.setExerciseXpPoints(50);
    session.setExerciseCompletedCount(1);

    await ApiService.clearStaleStateForNewAccount(404);
    await ApiService.loadLanguageProgress();

    expect(session.languageProgress.values, everyElement(0));
    expect(session.exerciseXpPoints, 0);
    expect(session.exerciseCompletedCount, 0);
    expect(await ApiService.getCompletedModuleTopicIds('Java'), isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('answered_questions_java'),
        ['old_account_question']);
  });
}
