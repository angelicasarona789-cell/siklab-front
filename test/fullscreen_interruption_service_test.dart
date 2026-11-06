import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siklab/services/fullscreen_interruption_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('stores focus-loss events separately for each account', () async {
    final occurrence = DateTime.utc(2026, 10, 26, 6);

    expect(
      await FullscreenInterruptionService.recordInterruption(
        userId: 17,
        email: 'learner@example.com',
        occurredAt: occurrence,
      ),
      1,
    );
    expect(
      await FullscreenInterruptionService.getInterruptions(17),
      [occurrence],
    );
    expect(
      await FullscreenInterruptionService.getInterruptions(18),
      isEmpty,
    );
  });

  test('keeps only the most recent 100 focus-loss events', () async {
    for (var index = 0; index < 102; index++) {
      await FullscreenInterruptionService.recordInterruption(
        userId: 17,
        email: 'learner@example.com',
        occurredAt: DateTime.utc(2026, 1, 1).add(Duration(minutes: index)),
      );
    }

    final events = await FullscreenInterruptionService.getInterruptions(17);
    expect(events, hasLength(100));
    expect(events.first,
        DateTime.utc(2026, 1, 1).add(const Duration(minutes: 101)));
    expect(
        events.last, DateTime.utc(2026, 1, 1).add(const Duration(minutes: 2)));
  });

  test('first interruption signs out and login allows five more interruptions',
      () async {
    expect(
      await FullscreenInterruptionService.recordInterruption(
        userId: 17,
        email: 'learner@example.com',
      ),
      1,
    );
    expect(
      await FullscreenInterruptionService.getLockoutUntil(
        'learner@example.com',
      ),
      isNull,
    );

    await FullscreenInterruptionService.recordSuccessfulLogin(
      'learner@example.com',
    );
    for (var attempt = 1; attempt <= 5; attempt++) {
      expect(
        await FullscreenInterruptionService.recordInterruption(
          userId: 17,
          email: 'learner@example.com',
        ),
        attempt + 1,
      );
      await FullscreenInterruptionService.recordSuccessfulLogin(
        'learner@example.com',
      );
    }

    expect(
      await FullscreenInterruptionService.getLockoutUntil(
        'learner@example.com',
      ),
      isNull,
    );
    expect(
      await FullscreenInterruptionService.recordInterruption(
        userId: 17,
        email: 'learner@example.com',
      ),
      7,
    );

    final lockedUntil = await FullscreenInterruptionService.getLockoutUntil(
      'LEARNER@example.com',
    );
    expect(lockedUntil, isNotNull);
    expect(
      lockedUntil!.difference(DateTime.now()).inMinutes,
      inInclusiveRange(59, 60),
    );
    expect(
      await FullscreenInterruptionService.getLockoutUntilForUserId(17),
      lockedUntil,
    );
    expect(
      await FullscreenInterruptionService.getLockoutUntil(
        'another@example.com',
      ),
      isNull,
    );
  });

  test('guest focus loss does not count as a signed-in user attempt', () async {
    expect(
      await FullscreenInterruptionService.recordInterruption(
        userId: 0,
        email: 'guest@example.com',
      ),
      0,
    );
    expect(await FullscreenInterruptionService.getInterruptions(0), isEmpty);
  });
}
