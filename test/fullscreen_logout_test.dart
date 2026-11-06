import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siklab/models/user_session.dart';
import 'package:siklab/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final session = UserSession();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'user_id': 42,
      'cached_user_name_42': 'Learner',
      'cached_user_email_42': 'learner@example.com',
    });
    session.clearAll();
    session.setUser(
      id: 42,
      name: 'Learner',
      email: 'learner@example.com',
    );
  });

  tearDown(() {
    session.clearAll();
  });

  test('sign-out clears saved login without waiting for server sync', () async {
    await ApiService.logout();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('user_id'), isNull);
    expect(prefs.getString('cached_user_name_42'), isNull);
    expect(prefs.getString('cached_user_email_42'), isNull);
    expect(prefs.getInt('total_active_seconds_42'), 0);
    expect(session.dbId, 0);
  });
}
