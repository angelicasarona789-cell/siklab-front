import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';
import 'user_profile.dart';

class UserSession extends ChangeNotifier {
  // ── Singleton ──────────────────────────────────────────────
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  // ── Core identity ───────────────────────────────────────────────
  int dbId = 0; // ← MySQL primary key
  String displayName = 'Developer';
  String email = '';
  String userId = '0x000000'; // hex display label

  // Flag to prevent unwanted resets during hot restart
  bool _isPersistentlyLoggedIn = false;
  int totalLogicCycles = 0;
  int currentStreak = 0;
  double avgPrecision = 0.0;
  int globalRank = 0;
  int weeklyRank = 0;
  int xpPoints = 0;
  int exerciseXpPoints = 0;
  int exerciseCompletedCount = 0;
  int codingActivityEvents = 0;
  int completedChallenges = 0;

  // Real-time active days tracking
  DateTime? _sessionStartTime;
  Timer? _activeTimer;
  // Baseline total seconds recorded when a session starts so we can show
  // "current session" elapsed time separately from the accumulated total.
  int _startTotalActiveSeconds = 0;

  // Persisted total active time (in seconds) - survives re-login
  int _totalActiveSeconds = 0;
  DateTime? _lastSessionSaveTime;

  // Threshold for detecting corrupted active time values (365 days in seconds)
  static const int _maxReasonableActiveSeconds = 365 * 86400;

  // Separate notification for active time updates
  final _activeTimeNotifier = ValueNotifier<int>(0);

  bool assessmentCompleted = false;

  Map<String, double> languageProgress = {
    'Java': 0.0,
    'Python': 0.0,
    'C#': 0.0,
    'JavaScript': 0.0,
    'SQL': 0.0,
  };

  void setUser({
    required int id,
    required String name,
    required String email,
    int? logicCycles,
    int? streak,
    double? precision,
    int? rank,
    int? weeklyRank,
    int? xp,
    int? completed,
    bool? assessmentCompleted,
  }) {
    dbId = id;
    displayName = name.isNotEmpty ? name : 'Developer';
    this.email = email;

    // Generate a decorative hex ID from the MySQL id
    userId = '0x${id.toRadixString(16).toUpperCase().padLeft(6, '0')}';
    _isPersistentlyLoggedIn = true;

    if (logicCycles != null) totalLogicCycles = logicCycles;
    if (streak != null) currentStreak = streak;
    if (precision != null) avgPrecision = precision;
    if (rank != null) globalRank = rank;
    if (weeklyRank != null) weeklyRank = weeklyRank;
    if (xp != null) xpPoints = xp;
    if (completed != null) completedChallenges = completed;
    if (assessmentCompleted == true) {
      this.assessmentCompleted = true;
      // A completed assessment must not be downgraded by stale profile data.
      saveAssessmentCompleted();
    }

    notifyListeners();
  }

  // ── Called by SyncService when sync_profile is received ────────
  // Updates profile fields from another device in real time
  void updateFromSync(Map<String, dynamic> data) {
    bool changed = false;

    if (data['full_name'] != null && data['full_name'] != displayName) {
      displayName = data['full_name'] as String;
      changed = true;
    }
    if (data['email'] != null && data['email'] != email) {
      email = data['email'] as String;
      changed = true;
    }
    if (data['total_logic_cycles'] != null) {
      totalLogicCycles = data['total_logic_cycles'] as int;
      changed = true;
    }
    if (data['current_streak'] != null) {
      currentStreak = data['current_streak'] as int;
      changed = true;
    }
    if (data['avg_precision'] != null) {
      avgPrecision = (data['avg_precision'] as num).toDouble();
      changed = true;
    }
    if (data['global_rank'] != null) {
      globalRank = data['global_rank'] as int;
      changed = true;
    }
    if (data['xp_points'] != null) {
      xpPoints = data['xp_points'] as int;
      changed = true;
    }
    if (data['completed_challenges'] != null) {
      completedChallenges = data['completed_challenges'] as int;
      changed = true;
    }

    if (changed) {
      debugPrint('UserSession: Profile synced from another device');
      notifyListeners();
    }
  }

  // Set basic login info for persistent login (used during hot restart)
  Future<void> setBasicLoginInfo(int id) async {
    if (_isPersistentlyLoggedIn && dbId == id) {
      debugPrint(
          'UserSession: Already logged in with ID $id, preserving session');
      return; // Don't reset if already logged in with same ID
    }

    dbId = id;
    userId = '0x${id.toRadixString(16).toUpperCase().padLeft(6, '0')}';
    _isPersistentlyLoggedIn = true;

    // Load assessment completion status from persistent storage
    await loadAssessmentCompleted();
    await UserProfile().loadAssessment(id);

    debugPrint(
        'UserSession: Set basic login info for ID $id, assessment completed: $assessmentCompleted');
    notifyListeners();
  }

  void clear() {
    stopActivityTracking();
    dbId = 0;
    displayName = 'Developer';
    email = '';
    userId = '0x000000';
    totalLogicCycles = 0;
    currentStreak = 0;
    avgPrecision = 0;
    globalRank = 0;
    weeklyRank = 0;
    xpPoints = 0;
    exerciseXpPoints = 0;
    exerciseCompletedCount = 0;
    codingActivityEvents = 0;
    completedChallenges = 0;
    assessmentCompleted = false;
    _isPersistentlyLoggedIn = false;
    _sessionStartTime = null;
    _startTotalActiveSeconds = 0;
    _totalActiveSeconds = 0;
    _activeTimeNotifier.value = 0;
    languageProgress = {
      'Java': 0.0,
      'Python': 0.0,
      'C#': 0.0,
      'JavaScript': 0.0,
      'SQL': 0.0,
    };
    unawaited(UserProfile().clearAssessment(0));
    notifyListeners();
  }

  void clearAll() {
    dbId = 0;
    displayName = 'Developer';
    email = '';
    userId = '0x000000';
    totalLogicCycles = 0;
    currentStreak = 0;
    avgPrecision = 0;
    globalRank = 0;
    weeklyRank = 0;
    xpPoints = 0;
    exerciseXpPoints = 0;
    exerciseCompletedCount = 0;
    codingActivityEvents = 0;
    completedChallenges = 0;
    assessmentCompleted = false;
    _isPersistentlyLoggedIn = false;
    _totalActiveSeconds = 0;
    _startTotalActiveSeconds = 0;
    languageProgress = {
      'Java': 0.0,
      'Python': 0.0,
      'C#': 0.0,
      'JavaScript': 0.0,
      'SQL': 0.0,
    };
    unawaited(UserProfile().clearAssessment(0));
    notifyListeners();
  }

  void resetProgress() {
    totalLogicCycles = 0;
    currentStreak = 0;
    avgPrecision = 0;
    globalRank = 0;
    weeklyRank = 0;
    xpPoints = 0;
    exerciseXpPoints = 0;
    exerciseCompletedCount = 0;
    codingActivityEvents = 0;
    completedChallenges = 0;
    _totalActiveSeconds = 0;
    _startTotalActiveSeconds = 0;
    _lastSessionSaveTime = null;
    _activeTimeNotifier.value = 0;
    languageProgress = {
      'Java': 0.0,
      'Python': 0.0,
      'C#': 0.0,
      'JavaScript': 0.0,
      'SQL': 0.0,
    };
    notifyListeners();
  }

  void resetForAccountSwitch() {
    stopActivityTracking();
    _sessionStartTime = null;
    _lastSessionSaveTime = null;
    resetProgress();
  }

  void setExerciseXpPoints(int points) {
    exerciseXpPoints = points;
    notifyListeners();
  }

  void addExerciseXpPoints(int points) {
    if (points <= 0) return;
    exerciseXpPoints += points;
    notifyListeners();
  }

  void setExerciseCompletedCount(int count) {
    exerciseCompletedCount = count;
    notifyListeners();
  }

  void addExerciseCompletedCount() {
    exerciseCompletedCount++;
    notifyListeners();
  }

  void recordCodingActivity() {
    codingActivityEvents++;
    notifyListeners();
  }

  void updateLanguageProgress(String language, double progress) {
    if (!languageProgress.containsKey(language) || !progress.isFinite) return;
    languageProgress[language] = progress.clamp(0.0, 1.0).toDouble();
    notifyListeners();
  }

  void notifyProgressChanged() {
    notifyListeners();
  }

  double getLanguageProgress(String language) {
    return languageProgress[language] ?? 0.0;
  }

  int getLanguageProgressPercent(String language) =>
      (getLanguageProgress(language) * 100).round();

  bool get isLoggedIn => dbId > 0;
  String get firstName => displayName.split(' ').first;
  double get overallLanguageProgress {
    const languages = [
      'Java',
      'Python',
      'C#',
      'JavaScript',
      'SQL',
    ];
    final totalProgress =
        languages.map(getLanguageProgress).reduce((a, b) => a + b);
    return totalProgress / languages.length;
  }

  String get skillLevel {
    return UserProfile().skillLevelLabel;
  }

  String get avgPrecisionLabel => '${(avgPrecision * 100).toInt()}%';
  String get weeklyRankLabel => weeklyRank > 0 ? '#$weeklyRank' : '#0';
  String get xpLabel => (xpPoints + exerciseXpPoints) >= 1000
      ? '${((xpPoints + exerciseXpPoints) / 1000).toStringAsFixed(1)}k'
      : '${xpPoints + exerciseXpPoints}';

  // Real-time active days tracking methods
  Future<void> startActivityTracking() async {
    debugPrint('UserSession: startActivityTracking called');

    // Load saved active time before starting
    await loadActiveTime();
    // Capture a baseline so we can show current-session elapsed without
    // exposing an accumulated/all-time value that may be inflated by
    // cross-device sync or incorrect server values.
    // Set the baseline to the currently-loaded total so the UI shows
    // only the current session (total - baseline) and avoids jumps when
    // another device or the server reports a higher accumulated value.
    _startTotalActiveSeconds = _totalActiveSeconds;

    if (_sessionStartTime == null) {
      _sessionStartTime = DateTime.now();
      debugPrint(
          'UserSession: Started activity tracking at $_sessionStartTime');
    } else {
      debugPrint(
          'UserSession: Activity tracking already started at $_sessionStartTime');
    }

    // Cancel existing timer and clear reference
    _activeTimer?.cancel();
    _activeTimer = null;

    // Determine whether this is a new user (no recorded progress)
    final bool isNewUser = languageProgress.values.every((p) => p <= 0);
    if (isNewUser) {
      debugPrint('UserSession: New user detected - starting timer');
    }

    // Start a timer to update active time every second (for all users)
    _activeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _totalActiveSeconds++; // Increment total active time
      final newValue = _totalActiveSeconds; // Use total seconds for persistence
      _activeTimeNotifier.value = newValue;
      debugPrint(
          'UserSession: Timer tick - total active seconds: $newValue, label: $realTimeActiveDaysLabel');
    });

    // Connect to WebSocket sync service for real-time updates (replaces periodic HTTP sync)
    if (dbId > 0) {
      SyncService().connect(dbId);
      debugPrint('UserSession: Connected to SyncService for user $dbId');
    }

    // Force immediate update with loaded time
    _activeTimeNotifier.value = _totalActiveSeconds;
    debugPrint(
        'UserSession: Initial update - total active seconds: $_totalActiveSeconds, label: $realTimeActiveDaysLabel');
  }

  void stopActivityTracking() {
    _activeTimer?.cancel();
    _activeTimer = null;
    SyncService().disconnect();
    debugPrint('UserSession: Disconnected from SyncService');
  }

  // Called by SyncService when receiving active time sync from server/other devices
  void syncActiveTime(int seconds) {
    // Validate incoming server time
    if (seconds > _maxReasonableActiveSeconds) {
      debugPrint(
          'UserSession: ⚠️ Ignoring corrupted server active time: $seconds seconds (>365 days)');
      return;
    }

    // Update local time if server has higher value (synchronized across devices)
    if (seconds > _totalActiveSeconds) {
      // Preserve the current-session elapsed seconds so the UI doesn't jump
      final sessionSeconds = currentSessionActiveSeconds;
      _totalActiveSeconds = seconds;
      // Recompute baseline so that (total - baseline) == sessionSeconds
      _startTotalActiveSeconds =
          (_totalActiveSeconds - sessionSeconds).clamp(0, _totalActiveSeconds);
      _activeTimeNotifier.value = _totalActiveSeconds;
      debugPrint(
          'UserSession: Synced from SyncService - total active seconds: $_totalActiveSeconds (preserved session: $sessionSeconds)');
    }
  }

  int get realTimeActiveDays {
    if (_totalActiveSeconds == 0) return 0;
    return (_totalActiveSeconds / 86400).floor(); // 86400 seconds = 1 day
  }

  String get realTimeActiveDaysLabel {
    // If the timer is currently running, indicate active now for clarity.
    if (_activeTimer != null && _activeTimer!.isActive) {
      return 'Active now';
    }

    if (_totalActiveSeconds == 0) return '0 minutes active';

    final days = _totalActiveSeconds ~/ 86400;
    final hours = (_totalActiveSeconds % 86400) ~/ 3600;
    final minutes = (_totalActiveSeconds % 3600) ~/ 60;
    final seconds = _totalActiveSeconds % 60;

    debugPrint(
        'UserSession: realTimeActiveDaysLabel - total seconds: $_totalActiveSeconds, days: $days, hours: $hours, minutes: $minutes, seconds: $seconds');

    if (days > 0) {
      return '$days days ${hours}h ${minutes}m active';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m active';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s active';
    } else if (seconds > 0) {
      return '${seconds}s active';
    } else {
      return 'Starting...';
    }
  }

  // Add a getter for total seconds for more precise tracking
  int get realTimeActiveSeconds {
    return _totalActiveSeconds;
  }

  // Seconds elapsed for the current session only (since `startActivityTracking`)
  int get currentSessionActiveSeconds {
    // If tracking hasn't started, there's no current-session time.
    if (_sessionStartTime == null) return 0;
    final diff = _totalActiveSeconds - _startTotalActiveSeconds;
    return diff < 0 ? 0 : diff;
  }

  // Expose whether the active timer is currently running
  bool get isTimerRunning => _activeTimer?.isActive ?? false;

  // Save total active time to persist it across sessions and sync to server
  Future<void> saveActiveTime({bool syncToServer = true}) async {
    _lastSessionSaveTime = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final userId = dbId;
    final key =
        userId > 0 ? 'total_active_seconds_$userId' : 'total_active_seconds';

    // Validate before saving - reject if corrupted
    if (_totalActiveSeconds > _maxReasonableActiveSeconds) {
      debugPrint(
          'UserSession: ⚠️ Refusing to save corrupted active time: $_totalActiveSeconds seconds. Resetting to 0.');
      _totalActiveSeconds = 0;
      _startTotalActiveSeconds = 0;
      await prefs.remove(key);
      return;
    }

    await prefs.setInt(key, _totalActiveSeconds);

    // Also sync to server
    if (userId > 0 && syncToServer) {
      await ApiService.syncActiveTimeToServer(userId, _totalActiveSeconds);
    }
    debugPrint(
        'UserSession: Saved active time: $_totalActiveSeconds seconds at $_lastSessionSaveTime with key: $key');
  }

  // Load total active time from persistence and server
  Future<void> loadActiveTime() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = dbId;
    final key =
        userId > 0 ? 'total_active_seconds_$userId' : 'total_active_seconds';
    final savedTime = prefs.getInt(key) ?? 0;

    // Validate saved time - reject if corrupted (over 1 year)
    if (savedTime > _maxReasonableActiveSeconds) {
      debugPrint(
          'UserSession: ⚠️ CORRUPTED saved active time detected: $savedTime seconds (>365 days). Clearing...');
      await prefs.remove(key);
      _totalActiveSeconds = 0;
      _activeTimeNotifier.value = 0;
      return;
    }

    // Try to fetch from server first (for cross-device sync) only for existing users
    int serverTime = 0;
    final bool isNewUser = languageProgress.values.every((p) => p <= 0);
    if (userId > 0 && !isNewUser) {
      serverTime = await ApiService.fetchActiveTimeFromServer(userId);
    } else if (userId > 0 && isNewUser) {
      debugPrint(
          'UserSession: New user - skipping server fetch during loadActiveTime');
    }

    // Validate server time - reject if corrupted
    if (serverTime > _maxReasonableActiveSeconds) {
      debugPrint(
          'UserSession: ⚠️ CORRUPTED server active time detected: $serverTime seconds (>365 days). Ignoring server value.');
      serverTime = 0;
    }

    // Use the highest value between local and server (both validated)
    final maxTime = serverTime > savedTime ? serverTime : savedTime;

    // Only load if the saved/server time is greater than current time (to avoid resetting)
    if (maxTime > _totalActiveSeconds) {
      _totalActiveSeconds = maxTime;
      debugPrint(
          'UserSession: Loaded active time: $_totalActiveSeconds seconds (local: $savedTime, server: $serverTime) with key: $key');
    } else {
      debugPrint(
          'UserSession: Keeping current active time: $_totalActiveSeconds seconds (local: $savedTime, server: $serverTime)');
    }

    // Update the notifier to reflect the loaded time
    _activeTimeNotifier.value = _totalActiveSeconds;
  }

  // Save assessment completion status to persist it across sessions
  Future<void> saveAssessmentCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = dbId;
    final key =
        userId > 0 ? 'assessment_completed_$userId' : 'assessment_completed';
    await prefs.setBool(key, assessmentCompleted);
    debugPrint(
        'UserSession: Saved assessment completed: $assessmentCompleted with key: $key');
  }

  // Load assessment completion status from persistence
  Future<void> loadAssessmentCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = dbId;
    final key =
        userId > 0 ? 'assessment_completed_$userId' : 'assessment_completed';
    final savedStatus = prefs.getBool(key) ?? false;

    // Only update if saved status is true (to avoid overriding completed status)
    if (savedStatus) {
      assessmentCompleted = savedStatus;
      debugPrint(
          'UserSession: Loaded assessment completed: $assessmentCompleted with key: $key');
    } else {
      debugPrint(
          'UserSession: Assessment not completed or already marked, keeping current status: $assessmentCompleted');
    }
  }

  // Getter for active time notifier
  ValueNotifier<int> get activeTimeNotifier => _activeTimeNotifier;

  // Clear corrupted active time data from SharedPreferences
  Future<void> clearCorruptedActiveTimeData() async {
    final prefs = await SharedPreferences.getInstance();
    // Check all user IDs that might have corrupted data
    final allKeys = prefs.getKeys();
    for (final key in allKeys) {
      if (key.startsWith('total_active_seconds_')) {
        final value = prefs.getInt(key);
        if (value != null && value > _maxReasonableActiveSeconds) {
          debugPrint(
              'UserSession: Clearing corrupted active time key: $key (value: $value)');
          await prefs.remove(key);
        }
      }
    }
  }

  @override
  void dispose() {
    _activeTimer?.cancel();
    _activeTimeNotifier.dispose();
    super.dispose();
  }
}
