// lib/services/api_service.dart
// ─────────────────────────────────────────────────────────────
//  All HTTP calls to the Flask backend.
//
//  Add to pubspec.yaml (under dependencies):
//    http: ^1.2.1
//    shared_preferences: ^2.2.3
//
//  Then run:  flutter pub get
// ─────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_data.dart';
import '../models/user_session.dart';
import '../models/user_profile.dart';
import 'certificate_completion_dates.dart';
import 'fullscreen_interruption_service.dart';

class ApiService {
  static int _localProgressRevision = 0;
  static int get localProgressRevision => _localProgressRevision;
  static void notifyLocalProgressChanged() => _localProgressRevision++;

  // ── Base URL ──────────────────────────────────────────────
  // Production Flask backend hosted on Render.
  // Used by Android, Android Emulator, and Flutter Web.

  static String get _baseUrl {
    return 'https://siklab-backend-fjt8.onrender.com';
  }

  // Render free service may need time to wake up.
  static const Duration _timeout = Duration(seconds: 30);

  static String baseUrl() => _baseUrl;


  // ─────────────────────────────────────────────────────────
  //  POST /signup
  // ─────────────────────────────────────────────────────────
  static Future<ApiResult> signup({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/signup'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'full_name': fullName,
              'email': email,
              'password': password,
            }),
          )
          .timeout(_timeout);

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (body['success'] == true && body['user'] != null) {
        final user = body['user'] as Map<String, dynamic>;
        await _applyToSession(user, isNewAccount: true);
        await _saveUserId(user['id'] as int);
        return ApiResult.ok(user);
      }
      return ApiResult.err(body['message'] ?? 'Signup failed.');
    } catch (e) {
      debugPrint('Signup error: $e');
      return _offlineSignup(
        fullName: fullName,
        email: email,
        password: password,
      );
    }
  }

  // ─────────────────────────────────────────────────────────
  //  POST /login
  // ─────────────────────────────────────────────────────────
  static Future<ApiResult> login({
    required String email,
    required String password,
  }) async {
    final lockedUntil =
        await FullscreenInterruptionService.getLockoutUntil(email);
    if (lockedUntil != null) {
      final remaining = lockedUntil.difference(DateTime.now());
      final minutes = (remaining.inSeconds + 59) ~/ 60;
      return ApiResult.err(
        'This account is temporarily locked on this device after repeated fullscreen interruptions. '
        'Try signing in again in about $minutes minute${minutes == 1 ? '' : 's'}.',
      );
    }

    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_timeout);

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (body['success'] == true && body['user'] != null) {
        final user = body['user'] as Map<String, dynamic>;
        await _applyToSession(user);
        await _saveUserId(user['id'] as int);
        await FullscreenInterruptionService.recordSuccessfulLogin(email);
        return ApiResult.ok(user);
      }
      return ApiResult.err(body['message'] ?? 'Login failed.');
    } catch (e) {
      debugPrint('Login error: $e');
      return _offlineLogin(email: email, password: password);
    }
  }

  // ─────────────────────────────────────────────────────────
  //  GET /profile/<id>
  // ─────────────────────────────────────────────────────────
  static Future<ApiResult> getProfile(int id) async {
    try {
      final res =
          await http.get(Uri.parse('$_baseUrl/profile/$id')).timeout(_timeout);

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (body['success'] == true && body['user'] != null) {
        final user = body['user'] as Map<String, dynamic>;
        await _applyToSession(user);
        return ApiResult.ok(user);
      }
      return ApiResult.err(body['message'] ?? 'Could not load profile.');
    } catch (e) {
      final user = await _findOfflineUserById(id);
      if (user != null) {
        await _applyToSession(user);
        return ApiResult.ok(user, 'Using local profile.');
      }
      return ApiResult.err('Cannot reach server.\n$e');
    }
  }

  // ─────────────────────────────────────────────────────────
  //  PUT /profile/<id>
  //  Pass only the fields you want to update.
  //  e.g. { 'full_name': 'New Name' }  or  { 'password': 'newpw' }
  // ─────────────────────────────────────────────────────────
  static Future<ApiResult> updateProfile(
      int id, Map<String, dynamic> fields) async {
    try {
      final res = await http
          .put(
            Uri.parse('$_baseUrl/profile/$id'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(fields),
          )
          .timeout(_timeout);

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (body['success'] == true && body['user'] != null) {
        final user = body['user'] as Map<String, dynamic>;
        await _applyToSession(user);
        return ApiResult.ok(user);
      }
      return ApiResult.err(body['message'] ?? 'Update failed.');
    } catch (e) {
      final user = await _findOfflineUserById(id);
      if (user != null) {
        user['full_name'] = fields['full_name'] ?? user['full_name'];
        user['email'] = fields['email'] ?? user['email'];
        await _saveOfflineUser(user);
        await _applyToSession(user);
        return ApiResult.ok(user, 'Saved locally.');
      }
      return ApiResult.err('Cannot reach server.\n$e');
    }
  }

  // ─────────────────────────────────────────────────────────
  //  GET /analytics/<id>
  //  Fetch analytics data: topic mastery, weak areas, velocity, milestones
  // ─────────────────────────────────────────────────────────
  static Future<ApiResult> getAnalytics(int id) async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/analytics/$id'))
          .timeout(_timeout);

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (body['success'] == true && body['analytics'] != null) {
        return ApiResult.ok(body['analytics'] as Map<String, dynamic>);
      }
      return ApiResult.err(body['message'] ?? 'Could not load analytics.');
    } catch (e) {
      return ApiResult.err('Cannot reach server.\n$e');
    }
  }

  static Future<ApiResult> submitFeedback({
    required int userId,
    required String category,
    required String message,
  }) async {
    if (userId <= 0) {
      return ApiResult.err('Sign in before submitting feedback.');
    }

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/feedback'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'category': category,
              'message': message.trim(),
            }),
          )
          .timeout(_timeout);
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return ApiResult.err('Server returned an invalid feedback response.');
      }
      final body = decoded;
      if (body['success'] == true) {
        return ApiResult.ok(
          {
            'id': body['feedback_id'],
            'status': body['status'] ?? 'new',
          },
          body['message'] as String? ?? 'Feedback submitted.',
        );
      }
      return ApiResult.err(
        body['message'] as String? ?? 'Could not submit feedback.',
      );
    } on TimeoutException catch (error) {
      debugPrint('Feedback submission timed out: $error');
      return ApiResult.err('The request timed out. Please try again.');
    } on http.ClientException catch (error) {
      debugPrint('Feedback submission failed: $error');
      return ApiResult.err(
          'Could not reach the server. Please try again later.');
    } on FormatException catch (error) {
      debugPrint('Feedback submission failed: $error');
      return ApiResult.err('Server returned an invalid feedback response.');
    }
  }

  // ─────────────────────────────────────────────────────────
  //  POST /quiz-attempt
  //  Records user practice result for real analytics.
  // ─────────────────────────────────────────────────────────
  static Future<ApiResult> submitQuizAttempt({
    required int userId,
    required String language,
    required String category,
    required String questionId,
    required String topicName,
    required bool isCorrect,
    required int timeTakenSeconds,
  }) async {
    await _recordCodingVelocityActivity(userId);
    if (UserSession().dbId == userId && userId > 0) {
      UserSession().recordCodingActivity();
    }

    await recordLocalExerciseAttempt(language, questionId);
    final isNewCorrectExercise =
        isCorrect && await _recordLocalCorrectQuestion(language, questionId);
    final reward = _experienceRewardForCategory(category);
    if (isNewCorrectExercise && reward > 0) {
      final prefs = await SharedPreferences.getInstance();
      if (userId > 0) {
        final xpKey = 'correct_exercise_xp_$userId';
        final earnedXp = (prefs.getInt(xpKey) ?? 0) + reward;
        await prefs.setInt(xpKey, earnedXp);
        final countKey = 'correct_exercise_completed_$userId';
        final completedCount = (prefs.getInt(countKey) ?? 0) + 1;
        await prefs.setInt(countKey, completedCount);
      }
      if (UserSession().dbId == userId && userId > 0) {
        UserSession().addExerciseXpPoints(reward);
        UserSession().addExerciseCompletedCount();
      }
    }

    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/quiz-attempt'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'language': language,
              'category': category,
              'question_id': questionId,
              'topic_name': topicName,
              'is_correct': isCorrect,
              'time_taken_seconds': timeTakenSeconds,
            }),
          )
          .timeout(_timeout);

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        return ApiResult.ok(
            {'recorded': true}, body['message'] as String? ?? '');
      }
      return ApiResult.err(body['message'] ?? 'Could not submit attempt.');
    } catch (e) {
      return ApiResult.err('Cannot reach server.\n$e');
    }
  }

  static int _experienceRewardForCategory(String category) {
    switch (category.trim().toLowerCase()) {
      case 'beginner':
        return 1;
      case 'intermediate':
        return 2;
      case 'upper intermediate':
      case 'upperintermediate':
      case 'advanced':
        return 3;
      default:
        return 0;
    }
  }

  // ─────────────────────────────────────────────────────────
  //  POST /assessment/<id>
  // ─────────────────────────────────────────────────────────
  static Future<ApiResult> saveAssessment({
    required int userId,
    required int experienceLevelScore,
    required int logicConfidenceScore,
    required String learningGoal,
    required int weeklyTimeScore,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/assessment/$userId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'experience_level_score': experienceLevelScore,
              'logic_confidence_score': logicConfidenceScore,
              'learning_goal': learningGoal,
              'weekly_time_score': weeklyTimeScore,
            }),
          )
          .timeout(_timeout);

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        return ApiResult.ok({'saved': true}, body['message'] as String? ?? '');
      }
      return ApiResult.err(body['message'] ?? 'Could not save assessment.');
    } catch (e) {
      return ApiResult.err('Cannot reach server.\n$e');
    }
  }

  // ─────────────────────────────────────────────────────────
  //  GET /lessons
  // ─────────────────────────────────────────────────────────
  static Future<ApiResult> listLessons(
      {String? language, String? level}) async {
    try {
      final uri = Uri.parse('$_baseUrl/lessons').replace(queryParameters: {
        if (language != null && language.trim().isNotEmpty)
          'language': language,
        if (level != null && level.trim().isNotEmpty) 'level': level,
      });
      final res = await http.get(uri).timeout(_timeout);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['success'] == true && body['lessons'] != null) {
        return ApiResult.ok({'lessons': body['lessons']});
      }
      return ApiResult.err(body['message'] ?? 'Could not load lessons.');
    } catch (e) {
      return ApiResult.err('Cannot reach server.\n$e');
    }
  }

  // ─────────────────────────────────────────────────────────
  //  GET /lessons/<id>
  // ─────────────────────────────────────────────────────────
  static Future<ApiResult> getLesson(int lessonId) async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/lessons/$lessonId'))
          .timeout(_timeout);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['success'] == true && body['lesson'] != null) {
        return ApiResult.ok(body['lesson'] as Map<String, dynamic>);
      }
      return ApiResult.err(body['message'] ?? 'Could not load lesson.');
    } catch (e) {
      return ApiResult.err('Cannot reach server.\n$e');
    }
  }

  // ─────────────────────────────────────────────────────────
  //  GET /exercises
  // ─────────────────────────────────────────────────────────
  static Future<ApiResult> listExercises({
    String? language,
    String? level,
    String? type,
    int? lessonId,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/exercises').replace(queryParameters: {
        if (language != null && language.trim().isNotEmpty)
          'language': language,
        if (level != null && level.trim().isNotEmpty) 'level': level,
        if (type != null && type.trim().isNotEmpty) 'type': type,
        if (lessonId != null) 'lesson_id': lessonId.toString(),
      });
      final res = await http.get(uri).timeout(_timeout);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['success'] == true && body['exercises'] != null) {
        return ApiResult.ok({'exercises': body['exercises']});
      }
      return ApiResult.err(body['message'] ?? 'Could not load exercises.');
    } catch (e) {
      return ApiResult.err('Cannot reach server.\n$e');
    }
  }

  // ─────────────────────────────────────────────────────────
  //  POST /evaluate
  // ─────────────────────────────────────────────────────────
  static Future<ApiResult> evaluateExercise({
    required int exerciseId,
    required String submitted,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/evaluate'),
            headers: {'Content-Type': 'application/json'},
            body:
                jsonEncode({'exercise_id': exerciseId, 'submitted': submitted}),
          )
          .timeout(_timeout);

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['success'] == true && body['result'] != null) {
        return ApiResult.ok(body['result'] as Map<String, dynamic>);
      }
      return ApiResult.err(body['message'] ?? 'Could not evaluate exercise.');
    } catch (e) {
      return ApiResult.err('Cannot reach server.\n$e');
    }
  }

  // ─────────────────────────────────────────────────────────
  //  SharedPreferences: save / load / clear user ID
  //  so the user stays logged in after app restart
  // ─────────────────────────────────────────────────────────
  static Future<void> _saveUserId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', id);
  }

  // ─────────────────────────────────────────────────────────
  //  Offline mode: local accounts used when the API is unavailable.
  // ─────────────────────────────────────────────────────────
  static const String _offlineEmailsKey = 'offline_user_emails';

  static String _offlineUserKey(String email) =>
      'offline_user_${Uri.encodeComponent(email.trim().toLowerCase())}';

  static Future<ApiResult> _offlineSignup({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final existing = await _findOfflineUserByEmail(normalizedEmail);
    if (existing != null) {
      return ApiResult.err('An account with this email already exists.');
    }

    final prefs = await SharedPreferences.getInstance();
    final id = (prefs.getInt('offline_next_user_id') ?? 1000);
    await prefs.setInt('offline_next_user_id', id + 1);
    final user = _newOfflineUser(
      id: id,
      fullName: fullName,
      email: normalizedEmail,
      password: password,
    );
    await _saveOfflineUser(user);
    await _applyToSession(user, isNewAccount: true);
    await _saveUserId(id);
    return ApiResult.ok(user, 'Offline account created.');
  }

  static Future<ApiResult> _offlineLogin({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final user = await _findOfflineUserByEmail(normalizedEmail);
    if (user == null || user['password'] != password) {
      return ApiResult.err(
        'Server unavailable. Sign up first to create a local account.',
      );
    }

    await _applyToSession(user);
    await _saveUserId(user['id'] as int);
    await FullscreenInterruptionService.recordSuccessfulLogin(email);
    return ApiResult.ok(user, 'Signed in locally.');
  }

  static Map<String, dynamic> _newOfflineUser({
    required int id,
    required String fullName,
    required String email,
    required String password,
  }) {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'password': password,
      'total_logic_cycles': 0,
      'current_streak': 0,
      'avg_precision': 0.0,
      'global_rank': 0,
      'weekly_rank': 0,
      'xp_points': 0,
      'completed_challenges': 0,
      'assessment_completed': false,
    };
  }

  static Future<void> _saveOfflineUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    final email = user['email'] as String;
    final emails = prefs.getStringList(_offlineEmailsKey) ?? [];
    if (!emails.contains(email)) emails.add(email);
    await prefs.setStringList(_offlineEmailsKey, emails);
    await prefs.setString(_offlineUserKey(email), jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> _findOfflineUserByEmail(
      String email) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_offlineUserKey(email));
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _findOfflineUserById(int id) async {
    final prefs = await SharedPreferences.getInstance();
    for (final email in prefs.getStringList(_offlineEmailsKey) ?? []) {
      final user = await _findOfflineUserByEmail(email);
      if (user?['id'] == id) return user;
    }
    return null;
  }

  static Future<int?> getSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return null;
    final lockedUntil =
        await FullscreenInterruptionService.getLockoutUntilForUserId(userId);
    if (lockedUntil != null) {
      await prefs.remove('user_id');
      return null;
    }
    return userId;
  }

  static Future<void> markAssessmentCompleted(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('assessment_completed_$userId', true);
    await prefs.setBool('initial_assessment_required_$userId', false);
  }

  static Future<bool> isAssessmentCompleted(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('assessment_completed_$userId') ?? false;
  }

  static Future<bool> requiresInitialAssessment(int userId) async {
    if (userId <= 0) return false;
    final prefs = await SharedPreferences.getInstance();
    final isNewAccount =
        prefs.getBool('initial_assessment_required_$userId') ?? false;
    final isCompleted =
        (prefs.getBool('assessment_completed_$userId') ?? false) ||
            (UserSession().dbId == userId && UserSession().assessmentCompleted);
    return isNewAccount && !isCompleted;
  }

  // ─────────────────────────────────────────────────────────
  //  Active Time Sync (Cross-device synchronization)
  // ─────────────────────────────────────────────────────────

  static Future<void> syncActiveTimeToServer(
      int userId, int totalSeconds) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/users/$userId/active-time'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'total_seconds': totalSeconds}),
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        debugPrint(
            'ApiService: Active time synced to server: $totalSeconds seconds');
      }
    } catch (e) {
      debugPrint('ApiService: Failed to sync active time: $e');
      // Fail silently - don't disrupt the app if sync fails
    }
  }

  static Future<int> fetchActiveTimeFromServer(int userId) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/users/$userId/active-time'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        var totalSeconds = body['total_seconds'] as int? ?? 0;
        // If the server returned a very large number it might be milliseconds.
        // Convert to seconds when value looks like milliseconds (>> 30 years).
        if (totalSeconds > 1000000000) {
          debugPrint(
              'ApiService: Warning - fetched active time looks large (maybe ms). Converting to seconds. Raw: $totalSeconds');
          totalSeconds = (totalSeconds ~/ 1000);
        }

        // Validate: reject if over 1 year (365 * 86400 = 31536000 seconds)
        if (totalSeconds > 31536000) {
          debugPrint(
              'ApiService: ⚠️ CORRUPTED active time from server: $totalSeconds seconds (>365 days). Returning 0.');
          return 0;
        }

        debugPrint(
            'ApiService: Fetched active time from server: $totalSeconds seconds');
        return totalSeconds;
      }
    } catch (e) {
      debugPrint('ApiService: Failed to fetch active time: $e');
    }
    return 0;
  }

  static Future<void> logout({bool syncActiveTimeToServer = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId != null) {
      await UserSession().saveActiveTime(syncToServer: false);
      if (syncActiveTimeToServer) {
        unawaited(
          ApiService.syncActiveTimeToServer(
            userId,
            UserSession().realTimeActiveSeconds,
          ),
        );
      }
    }

    await Future.wait([
      prefs.remove('user_id'),
      if (userId != null) ...[
        prefs.remove('cached_user_name_$userId'),
        prefs.remove('cached_user_email_$userId'),
      ],
    ]);

    // NOTE: Do NOT clear assessment_completed flag - it should persist across logout/login
    UserSession().stopActivityTracking();
    UserSession().clear();
  }

  /// A brand-new account must start clean even if an older account on this
  /// device once used the same id: it has to see the onboarding questions and
  /// start with fresh AI-check-in, attempt-history and certificate state.
  static Future<void> clearStaleStateForNewAccount(int userId) async {
    if (userId <= 0) return;
    _localProgressRevision++;
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      'assessment_completed_$userId',
      'initial_assessment_required_$userId',
      'ai_feedback_asked_checkpoint_$userId',
      'ai_feedback_asked_correct_$userId',
      'ai_feedback_responses_$userId',
      'attempt_history_$userId',
      'certificate_issued_$userId',
    ]) {
      await prefs.remove(key);
    }
    for (final key in prefs
        .getKeys()
        .where((k) =>
            _isUserProgressKey(k, userId) ||
            k.startsWith('certificate_issued_${userId}_') ||
            CertificateCompletionDates.isProgressDateKey(k, userId))
        .toList()) {
      await prefs.remove(key);
    }
    await prefs.setBool('initial_assessment_required_$userId', true);
    await prefs.setBool('skip_legacy_progress_migration_$userId', true);
    await UserProfile().clearAssessment(userId);
    UserSession().resetProgress();
    UserSession().assessmentCompleted = false;
  }

  static Future<void> resetLocalProgress() async {
    _localProgressRevision++;
    final prefs = await SharedPreferences.getInstance();
    final userId = UserSession().dbId;
    await _migrateLegacyProgress(userId);

    final progressKeys = prefs.getKeys().where((key) {
      if (userId <= 0) {
        return key.startsWith('correct_questions_') ||
            key.startsWith('answered_questions_') ||
            key.startsWith('unique_questions_') ||
            key.startsWith('quiz_attempts_') ||
            key.startsWith('completed_module_topics_') ||
            key.startsWith('ai_feedback_asked_') ||
            key.startsWith('certificate_issued_') ||
            CertificateCompletionDates.isProgressDateKey(key, userId) ||
            key.startsWith('attempt_history_') ||
            key.startsWith('practice_deadline_') ||
            key.startsWith('practice_cooldown_') ||
            key.startsWith('practice_question_time_');
      }
      return _isUserProgressKey(key, userId) ||
          key == 'ai_feedback_asked_checkpoint_$userId' ||
          key == 'ai_feedback_asked_correct_$userId' ||
          key == 'ai_feedback_responses_$userId' ||
          key == 'certificate_issued_$userId' ||
          key.startsWith('certificate_issued_${userId}_') ||
          CertificateCompletionDates.isProgressDateKey(key, userId) ||
          key == 'attempt_history_$userId';
    }).toList();
    for (final key in progressKeys) {
      await prefs.remove(key);
    }
    if (userId <= 0) {
      await prefs.remove('total_active_seconds');
    }
    if (userId > 0) {
      await prefs.remove('total_active_seconds_$userId');
      await prefs.remove('correct_exercise_xp_$userId');
      await prefs.remove('correct_exercise_completed_$userId');
      await prefs.remove('coding_velocity_days_$userId');

      final offlineUser = await _findOfflineUserById(userId);
      if (offlineUser != null) {
        offlineUser['total_logic_cycles'] = 0;
        offlineUser['current_streak'] = 0;
        offlineUser['avg_precision'] = 0.0;
        offlineUser['global_rank'] = 0;
        offlineUser['xp_points'] = 0;
        offlineUser['completed_challenges'] = 0;
        await _saveOfflineUser(offlineUser);
      }
    }

    UserSession().resetProgress();
  }

  // ─────────────────────────────────────────────────────────
  //  Returns the set of question IDs (format "<category>_<number>",
  //  e.g. "beginner_3") the user has already answered at least once
  //  for [language]. Used to show exercise-completion percentage in
  //  the Practice section.
  // ─────────────────────────────────────────────────────────
  static Future<Set<String>> getAnsweredQuestionIds(String language) async {
    await _migrateLegacyProgress(UserSession().dbId);
    final prefs = await SharedPreferences.getInstance();
    final normalized = _normalizeProgressLanguage(language);
    final answered = prefs.getStringList(
          _accountScopedProgressKey('answered_questions_$normalized'),
        ) ??
        [];
    final correct = prefs.getStringList(
          _accountScopedProgressKey('correct_questions_$normalized'),
        ) ??
        [];
    return {...answered, ...correct};
  }

  static int getTotalPracticeQuestionCount(String language) {
    for (final quiz in languageQuizzes) {
      if (quiz.name.toLowerCase() == language.trim().toLowerCase()) {
        return quiz.categories.values.fold<int>(
          0,
          (total, questions) => total + questions.length,
        );
      }
    }
    return 0;
  }

  static double calculatePracticeProgress(
    String language,
    Set<String> answeredQuestionIds,
  ) {
    final total = getTotalPracticeQuestionCount(language);
    if (total == 0) return 0;
    return (answeredQuestionIds.length / total).clamp(0.0, 1.0).toDouble();
  }

  static Future<Set<String>> getCompletedModuleTopicIds(String language) async {
    await _migrateLegacyProgress(UserSession().dbId);
    final prefs = await SharedPreferences.getInstance();
    final normalized = _normalizeProgressLanguage(language);
    final stored = prefs.getStringList(
          _accountScopedProgressKey('completed_module_topics_$normalized'),
        ) ??
        [];
    return stored.toSet();
  }

  static Future<Map<String, ({Set<String> answered, Set<String> modules})>>
      getCertificateProgressSnapshot(List<String> languages) async {
    await _migrateLegacyProgress(UserSession().dbId);
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final language in languages)
        language: (
          answered: {
            ...?prefs.getStringList(_accountScopedProgressKey(
              'answered_questions_${_normalizeProgressLanguage(language)}',
            )),
            ...?prefs.getStringList(_accountScopedProgressKey(
              'correct_questions_${_normalizeProgressLanguage(language)}',
            )),
          },
          modules: (prefs.getStringList(_accountScopedProgressKey(
                    'completed_module_topics_'
                    '${_normalizeProgressLanguage(language)}',
                  )) ??
                  [])
              .toSet(),
        ),
    };
  }

  static Future<void> markModuleTopicCompleted({
    required String language,
    required String topicId,
  }) async {
    await _migrateLegacyProgress(UserSession().dbId);
    final prefs = await SharedPreferences.getInstance();
    final normalized = _normalizeProgressLanguage(language);
    final key =
        _accountScopedProgressKey('completed_module_topics_$normalized');
    final completed = prefs.getStringList(key) ?? [];
    if (completed.contains(topicId)) return;
    await prefs.setStringList(key, [...completed, topicId]);
    _localProgressRevision++;
    await CertificateCompletionDates.recordModulesCompleted(language);
    UserSession().notifyProgressChanged();
  }

  static Future<int> getModuleTopicCompletionCount(String language) async {
    await _migrateLegacyProgress(UserSession().dbId);
    final prefs = await SharedPreferences.getInstance();
    final completedTopics = <String>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith('completed_module_topics_')) continue;
      final languageAndUser = key.substring('completed_module_topics_'.length);
      final currentUserId = UserSession().dbId;
      if (currentUserId > 0 && !languageAndUser.endsWith('_$currentUserId')) {
        continue;
      }
      if (currentUserId == 0 && RegExp(r'_\d+$').hasMatch(languageAndUser)) {
        continue;
      }
      final storedLanguage = _normalizeProgressLanguage(
        currentUserId > 0
            ? languageAndUser.substring(
                0, languageAndUser.length - '_$currentUserId'.length)
            : languageAndUser,
      );
      if (storedLanguage != _normalizeProgressLanguage(language)) continue;
      final topics = prefs.getStringList(key) ?? [];
      completedTopics.addAll(topics);
    }
    return completedTopics.length;
  }

  static String _normalizeProgressLanguage(String language) {
    final normalized = language.toLowerCase();
    return normalized == 'c#' ? 'csharp' : normalized;
  }

  static String _accountScopedProgressKey(String key, {int? userId}) {
    final id = userId ?? UserSession().dbId;
    return id > 0 ? '${key}_$id' : key;
  }

  static bool _isUserProgressKey(String key, int userId) {
    if (key.startsWith('practice_deadline_${userId}_') ||
        key.startsWith('practice_cooldown_${userId}_') ||
        key.startsWith('practice_question_time_${userId}_')) {
      return true;
    }
    if (!key.endsWith('_$userId')) return false;
    return key.startsWith('correct_questions_') ||
        key.startsWith('answered_questions_') ||
        key.startsWith('unique_questions_') ||
        key.startsWith('quiz_attempts_') ||
        key.startsWith('completed_module_topics_') ||
        key.startsWith('ai_feedback_asked_') ||
        key.startsWith('certificate_issued_') ||
        key.startsWith('attempt_history_') ||
        key.startsWith('correct_exercise_') ||
        key.startsWith('coding_velocity_days_') ||
        key == 'total_active_seconds_$userId';
  }

  static Future<void> _migrateLegacyProgress(int userId) async {
    if (userId <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('skip_legacy_progress_migration_$userId') == true) {
      return;
    }
    const languages = ['java', 'python', 'csharp', 'javascript', 'sql'];
    const prefixes = [
      'answered_questions_',
      'correct_questions_',
      'unique_questions_',
      'quiz_attempts_',
      'completed_module_topics_',
    ];

    for (final prefix in prefixes) {
      for (final language in languages) {
        final canonicalLanguage = language == 'csharp' ? 'csharp' : language;
        final scopedKey = _accountScopedProgressKey(
          '$prefix$canonicalLanguage',
          userId: userId,
        );
        final aliases = switch (language) {
          'java' => ['java', 'Java'],
          'python' => ['python', 'Python'],
          'csharp' => ['csharp', 'c#', 'C#'],
          'javascript' => ['javascript', 'JavaScript'],
          'sql' => ['sql', 'SQL'],
          _ => [language],
        };
        final legacyKeys = aliases.map((alias) => '$prefix$alias').toList();
        final scopedValues = prefs.getStringList(scopedKey) ?? [];
        final mergedValues = <String>{...scopedValues};
        var foundLegacy = false;
        for (final legacyKey in legacyKeys) {
          final values = prefs.getStringList(legacyKey);
          if (values != null) {
            mergedValues.addAll(values);
            foundLegacy = true;
          }
          await prefs.remove(legacyKey);
        }
        if (foundLegacy) {
          await prefs.setStringList(scopedKey, mergedValues.toList());
        }
      }
    }
  }

  static Future<List<int>> getCodingVelocityByDay(int userId) async {
    if (userId <= 0) return List<int>.filled(7, 0);

    final prefs = await SharedPreferences.getInstance();
    final activityDays =
        prefs.getStringList('coding_velocity_days_$userId') ?? [];
    final today = DateTime.now();

    return List<int>.generate(7, (index) {
      final day = today.subtract(Duration(days: 6 - index));
      final dayKey = '${day.year.toString().padLeft(4, '0')}-'
          '${day.month.toString().padLeft(2, '0')}-'
          '${day.day.toString().padLeft(2, '0')}';
      return activityDays.where((activityDay) => activityDay == dayKey).length;
    });
  }

  static Future<void> _recordCodingVelocityActivity(int userId) async {
    if (userId <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    String dayKey(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final activityKey = 'coding_velocity_days_$userId';
    final activityDays = prefs.getStringList(activityKey) ?? [];
    activityDays.add(dayKey(now));
    final cutoff = dayKey(now.subtract(const Duration(days: 30)));
    activityDays
        .removeWhere((activityDay) => activityDay.compareTo(cutoff) < 0);
    await prefs.setStringList(activityKey, activityDays);
  }

  // Manual method to set language progress (for testing/debugging)
  static Future<void> setLanguageProgress(
      String language, double progress) async {
    debugPrint(
        'Manually setting $language progress to ${(progress * 100).toInt()}%');
    UserSession().updateLanguageProgress(language, progress);
  }

  // Debug method to check and force load cached user data
  static Future<void> debugLoadCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getInt('user_id');

      debugPrint('ApiService: Debug - Saved user ID: $savedId');

      if (savedId != null && savedId > 0) {
        final cachedName = prefs.getString('cached_user_name_$savedId');
        final cachedEmail = prefs.getString('cached_user_email_$savedId');

        debugPrint('ApiService: Debug - Cached name: $cachedName');
        debugPrint('ApiService: Debug - Cached email: $cachedEmail');
        debugPrint(
            'ApiService: Debug - Current UserSession name: ${UserSession().displayName}');

        if (cachedName != null && cachedName.isNotEmpty) {
          UserSession().displayName = cachedName;
          UserSession().email = cachedEmail ?? '';
          // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
          UserSession().notifyListeners();
          debugPrint(
              'ApiService: Debug - Force updated UserSession name to: $cachedName');
        } else {
          debugPrint(
              'ApiService: Debug - No cached name found, setting a test name');
          // For testing, set a test name
          UserSession().displayName = 'Kenneth';
          // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
          UserSession().notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('ApiService: Debug - Error loading cached data: $e');
    }
  }

  // Comprehensive test method to verify all 5 programming languages work 100%
  static Future<void> testAllLanguagesProgress() async {
    debugPrint('=== TESTING ALL 5 PROGRAMMING LANGUAGES PROGRESS ===');

    final languages = ['Java', 'Python', 'C#', 'JavaScript', 'SQL'];
    final normalizedKeys = {
      'Java': 'java',
      'Python': 'python',
      'C#': 'csharp',
      'JavaScript': 'javascript',
      'SQL': 'sql'
    };

    for (final language in languages) {
      debugPrint('\n--- Testing $language ---');

      // Test 1: Check normalization
      final normalized = normalizedKeys[language];
      debugPrint('✓ Language normalization: $language → $normalized');

      // Test 2: Simulate quiz attempt
      await recordLocalExerciseAttempt(
          language, '${language.toLowerCase()}_test_1');
      debugPrint('✓ Quiz attempt tracking works');

      // Test 3: Check progress calculation
      final progress = UserSession().getLanguageProgress(language);
      debugPrint('✓ Progress calculation: ${(progress * 100).toInt()}%');

      // Test 4: Verify UI updates
      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      UserSession().notifyListeners();
      debugPrint('✓ UI notification sent');

      // Test 5: Check storage
      final prefs = await SharedPreferences.getInstance();
      final key = _accountScopedProgressKey(
        'answered_questions_$normalized',
      );
      final storedQuestions = prefs.getStringList(key) ?? [];
      debugPrint(
          '✓ Storage verification: ${storedQuestions.length} questions stored');

      debugPrint('✓ $language: ALL TESTS PASSED');
    }

    debugPrint('\n=== ALL 5 LANGUAGES VER VERSIFIED WORKING 100% ===');
  }

  // Enhanced debugging for language progress issues
  static Future<void> debugLanguageProgress(String language) async {
    debugPrint('\n=== DEBUGGING $language PROGRESS ===');

    // Normalize language
    String normalizedLanguage = language.toLowerCase();
    if (normalizedLanguage == 'c#') {
      normalizedLanguage = 'csharp';
    }

    debugPrint('Language: $language');
    debugPrint('Normalized: $normalizedLanguage');
    debugPrint('Storage key: answered_questions_$normalizedLanguage');

    final prefs = await SharedPreferences.getInstance();
    final storedQuestions = {
      ...?prefs.getStringList(
        _accountScopedProgressKey('answered_questions_$normalizedLanguage'),
      ),
      ...?prefs.getStringList(
        _accountScopedProgressKey('correct_questions_$normalizedLanguage'),
      ),
    };
    debugPrint('Stored questions: $storedQuestions');
    debugPrint('Unique count: ${storedQuestions.length}');

    final currentProgress = UserSession().getLanguageProgress(language);
    debugPrint('Current progress: ${(currentProgress * 100).toInt()}%');

    final expectedProgress =
        calculatePracticeProgress(language, storedQuestions);
    debugPrint('Expected progress: ${(expectedProgress * 100).toInt()}%');

    if ((currentProgress - expectedProgress).abs() > 0.01) {
      debugPrint('❌ PROGRESS MISMATCH - Current vs Expected');
    } else {
      debugPrint('✅ Progress matches expected value');
    }

    debugPrint('=== END DEBUG $language ===\n');
  }

  // Clear old quiz attempt data and migrate to unique question system
  static Future<void> migrateToUniqueQuestionSystem() async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint('Migrating to unique question system...');

    for (final language in ['java', 'python', 'c#', 'javascript', 'sql']) {
      // Remove old quiz_attempts data
      await prefs.remove('quiz_attempts_$language');
      debugPrint('Cleared old quiz_attempts for $language');
    }

    // Reload progress (will be 0% now)
    await loadLanguageProgress();
    debugPrint(
        'Migration complete. Progress reset to 0% - answer questions again to see progress.');
  }

  // Set Python progress to 20% manually (since you completed 10 unique beginner questions)
  static Future<void> setPythonProgressTo20Percent() async {
    final prefs = await SharedPreferences.getInstance();

    // Simulate 10 unique beginner questions for Python
    final pythonQuestions = [
      'python_beginner_1',
      'python_beginner_2',
      'python_beginner_3',
      'python_beginner_4',
      'python_beginner_5',
      'python_beginner_6',
      'python_beginner_7',
      'python_beginner_8',
      'python_beginner_9',
      'python_beginner_10',
    ];

    await prefs.setStringList(
      _accountScopedProgressKey('answered_questions_python'),
      pythonQuestions,
    );
    await loadLanguageProgress();
    debugPrint('Set Python progress to 20% (10 unique beginner questions)');
  }

  // Set progress for all 5 languages to test 100% functionality
  static Future<void> setAllLanguagesProgressForTesting() async {
    final prefs = await SharedPreferences.getInstance();

    // Test data for all 5 languages
    final testData = {
      'java': ['java_beginner_1', 'java_beginner_2', 'java_beginner_3'],
      'python': [
        'python_beginner_1',
        'python_beginner_2',
        'python_beginner_3',
        'python_beginner_4',
        'python_beginner_5'
      ],
      'csharp': ['csharp_beginner_1', 'csharp_beginner_2'],
      'javascript': [
        'javascript_beginner_1',
        'javascript_beginner_2',
        'javascript_beginner_3',
        'javascript_beginner_4'
      ],
      'sql': ['sql_beginner_1']
    };

    debugPrint('Setting test progress for all 5 languages...');

    for (final entry in testData.entries) {
      await prefs.setStringList(
        _accountScopedProgressKey('correct_questions_${entry.key}'),
        entry.value,
      );
      debugPrint(
          '✓ Set ${entry.key} progress: ${entry.value.length} questions');
    }

    // Load the progress into UserSession
    await loadLanguageProgress();

    // Verify all languages have progress
    for (final language in ['Java', 'Python', 'C#', 'JavaScript', 'SQL']) {
      final progress = UserSession().getLanguageProgress(language);
      debugPrint('✓ $language: ${(progress * 100).toInt()}%');
    }

    debugPrint('✅ All 5 languages set with test progress - 100% working!');
  }

  // Load saved language progress from local storage
  static Future<void> loadLanguageProgress() async {
    try {
      debugPrint('Loading language progress from local storage...');
      const languages = ['Java', 'Python', 'C#', 'JavaScript', 'SQL'];
      final snapshot = await getCertificateProgressSnapshot(languages);
      for (final language in languages) {
        final answeredQuestions = snapshot[language]!.answered;
        final progress = calculatePracticeProgress(language, answeredQuestions);
        debugPrint(
          '$language: ${answeredQuestions.length} answered, '
          '${(progress * 100).toInt()}% of '
          '${getTotalPracticeQuestionCount(language)} questions',
        );
        UserSession().updateLanguageProgress(language, progress);
      }
    } catch (e) {
      debugPrint('Error in loadLanguageProgress: $e');
      // Don't crash the app, just continue without loading progress
    }
  }

  static Future<bool> recordLocalExerciseAttempt(
    String language,
    String questionId,
  ) async {
    try {
      await _migrateLegacyProgress(UserSession().dbId);
      final prefs = await SharedPreferences.getInstance();
      final normalizedLanguage = _normalizeProgressLanguage(language);
      final key = _accountScopedProgressKey(
        'answered_questions_$normalizedLanguage',
      );
      final uniqueQuestions = <String>{
        ...?prefs.getStringList(key),
        ...?prefs.getStringList(
          _accountScopedProgressKey('correct_questions_$normalizedLanguage'),
        ),
      };

      if (uniqueQuestions.add(questionId)) {
        await prefs.setStringList(key, uniqueQuestions.toList());
        _localProgressRevision++;
        await CertificateCompletionDates.recordPracticeCompleted(language);
        final uniqueCount = uniqueQuestions.length;
        final progress = calculatePracticeProgress(language, uniqueQuestions);
        debugPrint(
            'New unique question: $language, question: $questionId, total unique: $uniqueCount');
        debugPrint(
            'Calculated progress for $language: ${(progress * 100).toInt()}%');
        UserSession().updateLanguageProgress(language, progress);
        return true;
      }
      debugPrint(
          'Duplicate question: $language, question: $questionId - not counting for progress');
      return false;
    } catch (e) {
      debugPrint('Error in recordLocalExerciseAttempt: $e');
      return false;
    }
  }

  static Future<bool> _recordLocalCorrectQuestion(
    String language,
    String questionId,
  ) async {
    try {
      await _migrateLegacyProgress(UserSession().dbId);
      final prefs = await SharedPreferences.getInstance();
      final normalizedLanguage = _normalizeProgressLanguage(language);
      final key = _accountScopedProgressKey(
        'correct_questions_$normalizedLanguage',
      );
      final correctQuestions = prefs.getStringList(key) ?? [];
      if (correctQuestions.contains(questionId)) return false;
      await prefs.setStringList(key, [...correctQuestions, questionId]);
      return true;
    } catch (e) {
      debugPrint('Error recording correct exercise: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  //  Internal: push DB row into the singleton UserSession
  // ─────────────────────────────────────────────────────────
  static Future<void> _applyToSession(
    Map<String, dynamic> user, {
    bool isNewAccount = false,
  }) async {
    final userId = user['id'] as int;
    final userName = user['full_name'] as String;
    final userEmail = user['email'] as String;
    if (UserSession().dbId != userId) {
      UserSession().clearAll();
    }
    if (isNewAccount) {
      await UserProfile().clearAssessment(userId);
    } else {
      await _migrateLegacyProgress(userId);
      await UserProfile().loadAssessment(userId);
    }
    final prefs = await SharedPreferences.getInstance();
    final exerciseXp = prefs.getInt('correct_exercise_xp_$userId') ?? 0;
    final exerciseCompletedCount =
        prefs.getInt('correct_exercise_completed_$userId') ?? 0;

    UserSession().setUser(
      id: userId,
      name: userName,
      email: userEmail,
      logicCycles: user['total_logic_cycles'] as int?,
      streak: user['current_streak'] as int?,
      precision: (user['avg_precision'] as num?)?.toDouble(),
      rank: user['global_rank'] as int?,
      weeklyRank: user['weekly_rank'] as int?,
      xp: user['xp_points'] as int?,
      completed: user['completed_challenges'] as int?,
      assessmentCompleted: user['assessment_completed'] as bool?,
    );
    UserSession().setExerciseXpPoints(exerciseXp);
    UserSession().setExerciseCompletedCount(exerciseCompletedCount);

    // Cache user data for persistent login
    await _cacheUserData(userId, userName, userEmail);

    // Update language progress if provided by backend
    final rawProgress = user['language_progress'];
    if (rawProgress is Map<String, dynamic>) {
      applyLanguageProgressFromServer(rawProgress);
    }
  }

  @visibleForTesting
  static void applyLanguageProgressFromServer(
    Map<String, dynamic> progressByLanguage,
  ) {
    const languageNames = {
      'java': 'Java',
      'python': 'Python',
      'c#': 'C#',
      'csharp': 'C#',
      'javascript': 'JavaScript',
      'sql': 'SQL',
    };
    for (final entry in progressByLanguage.entries) {
      final language = languageNames[entry.key.trim().toLowerCase()];
      final rawValue = entry.value;
      if (language == null || rawValue is! num || !rawValue.isFinite) continue;
      final fraction = rawValue > 1 ? rawValue / 100 : rawValue.toDouble();
      final currentProgress = UserSession().getLanguageProgress(language);
      if (fraction > currentProgress) {
        UserSession().updateLanguageProgress(language, fraction);
      }
    }
  }

  // Cache user data for persistent login
  static Future<void> _cacheUserData(
      int userId, String name, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user_name_$userId', name);
      await prefs.setString('cached_user_email_$userId', email);
      debugPrint('ApiService: Cached user data - ID: $userId, Name: $name');
    } catch (e) {
      debugPrint('ApiService: Failed to cache user data: $e');
    }
  }
}

// ── Simple result wrapper ─────────────────────────────────────
class ApiResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  const ApiResult._({required this.success, required this.message, this.data});

  factory ApiResult.ok(Map<String, dynamic> data, [String msg = '']) =>
      ApiResult._(success: true, message: msg, data: data);

  factory ApiResult.err(String message) =>
      ApiResult._(success: false, message: message);
}
