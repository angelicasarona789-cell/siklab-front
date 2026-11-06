import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siklab/models/user_session.dart';
import 'package:siklab/services/certificate_service.dart';
import 'package:siklab/services/demo_certificate_accounts.dart';

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

  test('account-switch reset keeps the selected identity', () {
    session.setUser(
      id: 910001,
      name: 'Mars',
      email: 'demo.mars@siklab.local',
      assessmentCompleted: true,
    );
    session.setExerciseXpPoints(25);

    session.resetForAccountSwitch();

    expect(session.dbId, 910001);
    expect(session.displayName, 'Mars');
    expect(session.assessmentCompleted, isTrue);
    expect(session.exerciseXpPoints, 0);
    expect(session.languageProgress.values.every((progress) => progress == 0),
        isTrue);
  });

  test('demo certificate accounts unlock completed certificates at each level',
      () async {
    expect(
      DemoCertificateAccounts.accounts.map((account) => account.name),
      ['Mars', 'Edcel', 'Miguel', 'Jelord', 'Mcking'],
    );

    for (final account in DemoCertificateAccounts.accounts) {
      await DemoCertificateAccounts.activate(account);

      expect(session.displayName, account.name);
      final status = await CertificateService.getStatus();
      expect(status.isComplete, isTrue);
      final languageStatuses = await CertificateService.getLanguageStatuses();
      expect(languageStatuses.keys, ['Java', 'Python', 'C#', 'JavaScript', 'SQL']);
      expect(
          languageStatuses.values.every((status) => status.isComplete), isTrue);

      final certificate = await CertificateService.getCertificate();
      expect(certificate, isNotNull);
      expect(certificate!.recipientName, account.name);
      expect(certificate.practiceLevel, account.level);
    }
  });
}
