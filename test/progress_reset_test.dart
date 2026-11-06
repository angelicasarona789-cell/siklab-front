import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siklab/models/user_session.dart';
import 'package:siklab/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resetLocalProgress clears device progress and preserves account state',
      () async {
    SharedPreferences.setMockInitialValues({
      'unique_questions_java': ['beginner_1'],
      'quiz_attempts_Java': ['beginner_1'],
      'completed_module_topics_java': ['beginner_1'],
      'total_active_seconds_42': 900,
      'assessment_completed_42': true,
    });
    final session = UserSession()
      ..dbId = 42
      ..totalLogicCycles = 10
      ..currentStreak = 3
      ..avgPrecision = 0.8
      ..globalRank = 2
      ..weeklyRank = 1
      ..xpPoints = 50
      ..completedChallenges = 4
      ..assessmentCompleted = true;
    session.updateLanguageProgress('Java', 0.5);

    await ApiService.resetLocalProgress();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('unique_questions_java'), isNull);
    expect(prefs.getStringList('quiz_attempts_Java'), isNull);
    expect(prefs.getStringList('completed_module_topics_java'), isNull);
    expect(prefs.getInt('total_active_seconds_42'), isNull);
    expect(prefs.getBool('assessment_completed_42'), isTrue);

    expect(session.dbId, 42);
    expect(session.totalLogicCycles, 0);
    expect(session.currentStreak, 0);
    expect(session.avgPrecision, 0);
    expect(session.globalRank, 0);
    expect(session.weeklyRank, 0);
    expect(session.xpPoints, 0);
    expect(session.completedChallenges, 0);
    expect(session.getLanguageProgress('Java'), 0);
    expect(session.assessmentCompleted, isTrue);
  });
}
