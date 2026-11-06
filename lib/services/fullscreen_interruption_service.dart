import 'package:shared_preferences/shared_preferences.dart';

class FullscreenInterruptionService {
  static const int _maxEvents = 100;
  static const int postReloginInterruptionLimit = 5;
  static const Duration lockoutDuration = Duration(hours: 1);

  static String _key(int userId) => 'fullscreen_interruption_log_$userId';
  static String _phaseKey(String email) =>
      'fullscreen_interruption_phase_${_emailKey(email)}';
  static String _postLoginAttemptKey(String email) =>
      'fullscreen_interruption_post_login_attempts_${_emailKey(email)}';
  static String _lockoutKey(String email) =>
      'fullscreen_interruption_lockout_${_emailKey(email)}';
  static String _userLockoutKey(int userId) =>
      'fullscreen_interruption_user_lockout_$userId';

  static String _emailKey(String email) =>
      Uri.encodeComponent(email.trim().toLowerCase());

  static Future<int> recordInterruption({
    required int userId,
    required String email,
    DateTime? occurredAt,
  }) async {
    if (userId <= 0) return 0;
    final prefs = await SharedPreferences.getInstance();
    final events = prefs.getStringList(_key(userId)) ?? [];
    events.add((occurredAt ?? DateTime.now()).toIso8601String());
    if (events.length > _maxEvents) {
      events.removeRange(0, events.length - _maxEvents);
    }

    final phaseKey = _phaseKey(email);
    final phase = prefs.getString(phaseKey) ?? 'initial';
    if (phase == 'initial') {
      await Future.wait([
        prefs.setStringList(_key(userId), events),
        prefs.setString(phaseKey, 'awaiting_relogin'),
      ]);
      return 1;
    }

    if (phase == 'post_login') {
      final postLoginKey = _postLoginAttemptKey(email);
      final postLoginAttempts = (prefs.getInt(postLoginKey) ?? 0) + 1;
      if (postLoginAttempts > postReloginInterruptionLimit) {
        final lockedUntilMillis = (occurredAt ?? DateTime.now())
            .add(lockoutDuration)
            .millisecondsSinceEpoch;
        await Future.wait([
          prefs.setStringList(_key(userId), events),
          prefs.setInt(postLoginKey, postLoginAttempts),
          prefs.setInt(_lockoutKey(email), lockedUntilMillis),
          prefs.setInt(_userLockoutKey(userId), lockedUntilMillis),
          prefs.setString(phaseKey, 'locked'),
        ]);
      } else {
        await Future.wait([
          prefs.setStringList(_key(userId), events),
          prefs.setInt(postLoginKey, postLoginAttempts),
        ]);
      }
      return postLoginAttempts + 1;
    }

    await prefs.setStringList(_key(userId), events);
    return 1;
  }

  static Future<void> recordSuccessfulLogin(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final phaseKey = _phaseKey(normalizedEmail);
    final phase = prefs.getString(phaseKey);
    if (phase == 'awaiting_relogin') {
      await prefs.setString(phaseKey, 'post_login');
      await prefs.setInt(_postLoginAttemptKey(normalizedEmail), 0);
    } else if (phase == 'locked') {
      await _clearLockoutIfExpired(normalizedEmail, prefs);
    }
  }

  static Future<DateTime?> getLockoutUntil(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    return _clearLockoutIfExpired(normalizedEmail, prefs);
  }

  static Future<DateTime?> getLockoutUntilForUserId(int userId) async {
    if (userId <= 0) return null;
    final prefs = await SharedPreferences.getInstance();
    final key = _userLockoutKey(userId);
    final lockedUntilMillis = prefs.getInt(key);
    if (lockedUntilMillis == null) return null;
    final lockedUntil = DateTime.fromMillisecondsSinceEpoch(lockedUntilMillis);
    if (lockedUntil.isAfter(DateTime.now())) return lockedUntil;
    await prefs.remove(key);
    return null;
  }

  static Future<DateTime?> _clearLockoutIfExpired(
    String email,
    SharedPreferences prefs,
  ) async {
    final key = _lockoutKey(email);
    final lockedUntilMillis = prefs.getInt(key);
    if (lockedUntilMillis == null) return null;
    final lockedUntil = DateTime.fromMillisecondsSinceEpoch(lockedUntilMillis);
    if (lockedUntil.isAfter(DateTime.now())) return lockedUntil;

    await prefs.remove(key);
    await prefs.remove(_phaseKey(email));
    await prefs.remove(_postLoginAttemptKey(email));
    return null;
  }

  static Future<List<DateTime>> getInterruptions(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final events = prefs.getStringList(_key(userId)) ?? [];
    return events
        .map(DateTime.tryParse)
        .whereType<DateTime>()
        .toList()
        .reversed
        .toList();
  }
}
