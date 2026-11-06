import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siklab/services/ai_feedback_service.dart';

void main() {
  group('AI Reliance Index', () {
    test('lowest reliance scores 0', () {
      // Never asks AI, never copies, extremely confident on both.
      expect(AiFeedbackService.relianceIndex([1, 1, 5, 5]), 0);
    });

    test('highest reliance scores 100', () {
      // Always asks AI, always copies, not at all confident on both.
      expect(AiFeedbackService.relianceIndex([5, 5, 1, 1]), 100);
    });

    test('confidence questions are reverse-scored', () {
      // Mid-point answers everywhere → exactly 50.
      expect(AiFeedbackService.relianceIndex([3, 3, 3, 3]), 50);
      // Higher confidence lowers the index.
      expect(
        AiFeedbackService.relianceIndex([3, 3, 5, 5]),
        lessThan(AiFeedbackService.relianceIndex([3, 3, 1, 1])),
      );
    });

    test('same four questions at pre-test and post-test', () {
      expect(AiFeedbackService.questions.length, 4);
      expect(
        AiFeedbackService.questions.map((q) => q.isConfidence).toList(),
        [false, false, true, true],
      );
    });
  });

  group('Check-in trigger (every 10 correct practice questions)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<int?> answer(int n) => AiFeedbackService.registerCorrectAnswer(
        userId: 1, language: 'Java', questionId: 'beginner_$n');

    test('appears on the 10th distinct correct question, not before', () async {
      for (var n = 1; n <= 9; n++) {
        expect(await answer(n), isNull);
      }
      expect(await answer(10), 10);
    });

    test('re-answering a question never counts twice', () async {
      for (var n = 1; n <= 9; n++) {
        await answer(n);
      }
      expect(await answer(9), isNull); // repeat
      expect(await answer(9), isNull);
      expect(await answer(10), 10);
    });

    test('is shown once per milestone, then again at 20', () async {
      for (var n = 1; n <= 10; n++) {
        await answer(n);
      }
      expect(await answer(10), isNull); // already shown for 10
      for (var n = 1; n <= 9; n++) {
        expect(
          await AiFeedbackService.registerCorrectAnswer(
              userId: 1, language: 'Python', questionId: 'beginner_$n'),
          isNull,
        );
      }
      expect(
        await AiFeedbackService.registerCorrectAnswer(
            userId: 1, language: 'Python', questionId: 'beginner_10'),
        20,
      );
    });

    test('first answered check-in is the baseline, later ones are follow-ups',
        () async {
      var o = await AiFeedbackService.saveCheckpoint(
          userId: 1,
          correctCount: 10,
          language: 'Java',
          categoryLabel: 'Beginner',
          answers: [4, 4, 2, 2]);
      expect(o.isBaseline, isTrue);
      expect(o.baseline, isNull);

      o = await AiFeedbackService.saveCheckpoint(
          userId: 1,
          correctCount: 20,
          language: 'Java',
          categoryLabel: 'Beginner',
          answers: [2, 2, 4, 4]);
      expect(o.isBaseline, isFalse);
      expect(o.baseline, isNotNull);
      expect(o.index!, lessThan(o.baseline!));
    });
  });
}
