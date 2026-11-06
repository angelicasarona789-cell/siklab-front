import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siklab/models/quiz_data.dart';
import 'package:siklab/models/user_session.dart';
import 'package:siklab/services/practice_timing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final session = UserSession();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    session.clearAll();
    session.setUser(id: 515, name: 'Learner', email: 'learner@test.com');
  });

  tearDown(() {
    session.clearAll();
  });

  test('question time limits match the three categories', () {
    expect(
      QuizCategory.values.map((category) => category.label).toList(),
      ['Beginner', 'Intermediate', 'Advanced'],
    );
    expect(
      PracticeTimingService.questionDuration(QuizCategory.beginner),
      const Duration(minutes: 3),
    );
    expect(
      PracticeTimingService.questionDuration(QuizCategory.intermediate),
      const Duration(minutes: 6),
    );
    expect(
      PracticeTimingService.questionDuration(QuizCategory.upperIntermediate),
      const Duration(minutes: 9),
    );
    expect(
      PracticeTimingService.formatDuration(const Duration(minutes: 90)),
      '1h 30m',
    );
    expect(
      PracticeTimingService.categoryDuration(QuizCategory.beginner, 10),
      const Duration(minutes: 30),
    );
    expect(
      PracticeTimingService.categoryDuration(QuizCategory.intermediate, 10),
      const Duration(minutes: 60),
    );
    expect(
      PracticeTimingService.categoryDuration(
        QuizCategory.upperIntermediate,
        10,
      ),
      const Duration(minutes: 90),
    );
  });

  test('practice time is recorded once per question and scoped by language',
      () async {
    await PracticeTimingService.recordQuestionTime(
      language: 'Java',
      category: QuizCategory.beginner,
      questionNumber: 1,
      elapsedSeconds: 42,
    );
    await PracticeTimingService.recordQuestionTime(
      language: 'Java',
      category: QuizCategory.beginner,
      questionNumber: 1,
      elapsedSeconds: 120,
    );
    await PracticeTimingService.recordQuestionTime(
      language: 'Python',
      category: QuizCategory.intermediate,
      questionNumber: 2,
      elapsedSeconds: 90,
    );

    expect(await PracticeTimingService.getTotalPracticeSeconds(), 132);
    expect(await PracticeTimingService.getRecordedPracticeQuestionCount(), 2);
    expect(
      await PracticeTimingService.getTotalPracticeSeconds(language: 'Java'),
      42,
    );
    expect(
      await PracticeTimingService.getRecordedPracticeQuestionCount(
        language: 'Java',
      ),
      1,
    );
  });

  test('timed-out questions start a five-minute category cooldown', () async {
    await PracticeTimingService.expireQuestion(
      language: 'Java',
      category: QuizCategory.beginner,
      questionNumber: 1,
    );

    final until = await PracticeTimingService.getCooldown(
      'Java',
      QuizCategory.beginner,
    );

    expect(until, isNotNull);
    expect(
      until!.difference(DateTime.now()).inSeconds,
      inInclusiveRange(295, 300),
    );
    expect(
      await PracticeTimingService.getCooldown(
        'Java',
        QuizCategory.intermediate,
      ),
      isNull,
    );
  });

  test('question deadlines persist and expired deadlines trigger cooldowns',
      () async {
    final firstDeadline = await PracticeTimingService.startOrResumeQuestion(
      language: 'Java',
      category: QuizCategory.beginner,
      questionNumber: 1,
    );
    final resumedDeadline = await PracticeTimingService.startOrResumeQuestion(
      language: 'Java',
      category: QuizCategory.beginner,
      questionNumber: 1,
    );
    expect(
      resumedDeadline.millisecondsSinceEpoch,
      firstDeadline.millisecondsSinceEpoch,
    );

    final prefs = await SharedPreferences.getInstance();
    final deadlineKey = prefs.getKeys().singleWhere(
          (key) => key.startsWith('practice_deadline_515_java_beginner_1'),
        );
    await prefs.setInt(
      deadlineKey,
      DateTime.now()
          .subtract(const Duration(seconds: 1))
          .millisecondsSinceEpoch,
    );

    expect(
      await PracticeTimingService.getCooldown('Java', QuizCategory.beginner),
      isNotNull,
    );
  });

  test('certification level uses the requested elapsed-time thresholds', () {
    expect(
      PracticeTimingService.certificationLevelForSeconds(7199),
      'Advanced',
    );
    expect(
      PracticeTimingService.certificationLevelForSeconds(7200),
      'Intermediate',
    );
    expect(
      PracticeTimingService.certificationLevelForSeconds(8999),
      'Intermediate',
    );
    expect(
      PracticeTimingService.certificationLevelForSeconds(90000),
      'Beginner',
    );
    expect(
      PracticeTimingService.certificationLevelForSeconds(4 * 60 * 60),
      'Beginner',
    );
    expect(PracticeTimingService.certificationLevelForSeconds(0), isNull);
  });
}
