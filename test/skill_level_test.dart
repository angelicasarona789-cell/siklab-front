import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siklab/models/user_session.dart';
import 'package:siklab/models/user_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final session = UserSession();
  const languages = ['Java', 'Python', 'C#', 'JavaScript', 'SQL'];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserProfile().clearAssessment(0);
    session.clearAll();
  });

  tearDown(() {
    for (final language in languages) {
      session.updateLanguageProgress(language, 0);
    }
  });

  test('skill level matches the Home recommendation experience level', () {
    expect(UserProfile().experienceLevel, 'beginner');
    expect(session.skillLevel, 'Beginner');

    UserProfile()
      ..setGateAnswer('A little — I know the basics.')
      ..setAssessmentAnswers(
          {'experience': 2, 'logic': 2, 'goal': 2, 'time': 2});
    expect(UserProfile().experienceLevel, 'intermediate');
    expect(session.skillLevel, 'Intermediate');

    UserProfile()
      ..setGateAnswer('Yes — I code regularly.')
      ..setAssessmentAnswers(
        {'experience': 4, 'logic': 4, 'goal': 4, 'time': 4},
      );
    expect(UserProfile().experienceLevel, 'expert');
    expect(session.skillLevel, 'Advanced');

    UserProfile()
      ..setGateAnswer('No idea — completely new.')
      ..setAssessmentAnswers(
        {'experience': 1, 'logic': 1, 'goal': 1, 'time': 1},
      );
    expect(UserProfile().experienceLevel, 'novice');
    expect(session.skillLevel, 'Getting Started');
  });

  test('skill recommendation level is independent of language progress bars',
      () {
    UserProfile()
      ..setGateAnswer('No idea — completely new.')
      ..setAssessmentAnswers(
        {'experience': 1, 'logic': 1, 'goal': 1, 'time': 1},
      );
    session.updateLanguageProgress('Java', 1);

    expect(session.overallLanguageProgress, 0.2);
    expect(session.skillLevel, 'Getting Started');
  });

  test('assessment recommendation level is restored per account', () async {
    UserProfile()
      ..setGateAnswer('Yes — I code regularly.')
      ..setAssessmentAnswers(
        {'experience': 4, 'logic': 4, 'goal': 4, 'time': 4},
      );
    await UserProfile().saveAssessment(515);

    await UserProfile().loadAssessment(616);
    expect(session.skillLevel, 'Beginner');

    await UserProfile().loadAssessment(515);
    expect(UserProfile().experienceLevel, 'expert');
    expect(session.skillLevel, 'Advanced');
  });
}
