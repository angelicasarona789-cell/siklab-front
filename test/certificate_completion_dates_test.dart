import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siklab/models/user_session.dart';
import 'package:siklab/services/api_service.dart';
import 'package:siklab/services/certificate_completion_dates.dart';
import 'package:siklab/services/certificate_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final session = UserSession();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    session.clearAll();
  });

  tearDown(() {
    session.clearAll();
  });

  test('uses the later completion date for a language certificate', () async {
    session.setUser(id: 101, name: 'Student', email: 'student@example.com');

    await CertificateCompletionDates.recordModulesCompleted('Java');
    final modulesCompletedOn =
        await CertificateCompletionDates.languageCompletedOn('Java');
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await CertificateCompletionDates.recordPracticeCompleted('Java');

    final completedOn =
        await CertificateCompletionDates.languageCompletedOn('Java');
    expect(completedOn, isNotNull);
    expect(completedOn!.isAfter(modulesCompletedOn!), isTrue);
  });

  test('completion dates are scoped to the current user', () async {
    session.setUser(id: 101, name: 'First', email: 'first@example.com');
    await CertificateCompletionDates.recordPracticeCompleted('C#');

    session.setUser(id: 202, name: 'Second', email: 'second@example.com');
    expect(
      await CertificateCompletionDates.languageCompletedOn('C#'),
      isNull,
    );
    await CertificateCompletionDates.recordModulesCompleted('C#');
    expect(
      await CertificateCompletionDates.languageCompletedOn('C#'),
      isNotNull,
    );
  });

  test('certificate progress refreshes after a local completion is recorded',
      () async {
    session.setUser(id: 303, name: 'Student', email: 'student@example.com');

    final before = await CertificateService.getStatus(language: 'Java');
    expect(before.modulesDone, 0);
    expect(before.practiceDone, 0);

    await ApiService.markModuleTopicCompleted(
      language: 'Java',
      topicId: 'beginner_1',
    );
    await ApiService.recordLocalExerciseAttempt('Java', 'beginner_1');

    final after = await CertificateService.getStatus(language: 'Java');
    expect(after.modulesDone, 1);
    expect(after.practiceDone, 1);
  });
}
