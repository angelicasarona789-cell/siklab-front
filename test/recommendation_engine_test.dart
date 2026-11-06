import 'package:flutter_test/flutter_test.dart';
import 'package:siklab/services/recommendation_service.dart';

List<bool> attempts(int correct, int total) =>
    [for (var i = 0; i < total; i++) i < correct];

void main() {
  group('RecommendationEngine rules', () {
    test('Rule 4: fewer than 5 attempts → insufficient data', () {
      for (final n in [0, 1, 4]) {
        final r = RecommendationEngine.evaluate(attempts(n, n));
        expect(r.rule, RecommendationRule.insufficientData);
        expect(r.accuracy, isNull);
        expect(r.message, contains('Submit more answers'));
      }
    });

    test('Rule 1: below 60% → needs improvement', () {
      // 0/5 = 0%, 2/5 = 40%, (3/5 = 60% is NOT below 60)
      expect(RecommendationEngine.evaluate(attempts(0, 5)).rule,
          RecommendationRule.needsImprovement);
      expect(RecommendationEngine.evaluate(attempts(2, 5)).rule,
          RecommendationRule.needsImprovement);
    });

    test('Rule 2: 60%-79% → moderate performance', () {
      expect(RecommendationEngine.evaluate(attempts(3, 5)).rule,
          RecommendationRule.moderatePerformance); // 60%
    });

    test('Rule 3: 80% or higher → good performance', () {
      expect(RecommendationEngine.evaluate(attempts(4, 5)).rule,
          RecommendationRule.goodPerformance); // 80%
      expect(RecommendationEngine.evaluate(attempts(5, 5)).rule,
          RecommendationRule.goodPerformance); // 100%
    });

    test('accuracy = correct / total × 100', () {
      final r = RecommendationEngine.evaluate(attempts(4, 5));
      expect(r.accuracy, 80);
      expect(r.correct, 4);
      expect(r.attempts, 5);
    });

    test('only the 5 most recent attempts are used', () {
      // Newest five are all correct; older failures are ignored.
      final r = RecommendationEngine.evaluate(
          [true, true, true, true, true, false, false, false, false]);
      expect(r.rule, RecommendationRule.goodPerformance);
      expect(r.attempts, 5);
    });

    test('Rule 3 message mentions the next topic when there is one', () {
      final r = RecommendationEngine.evaluate(attempts(5, 5),
          nextTopicLabel: 'Intermediate');
      expect(r.message, contains('Intermediate'));
    });
  });
}
