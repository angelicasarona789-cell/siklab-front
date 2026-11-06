// lib/services/certificate_service.dart
// ─────────────────────────────────────────────────────────────
//  Works out whether the user has earned the Certificate of
//  Completion and provides the data printed on it.
//
//  Eligible = every module topic AND every practice question, in every
//  language and category, has been completed.
// ─────────────────────────────────────────────────────────────

import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_data.dart';
import '../models/user_session.dart';
import 'api_service.dart';
import 'certificate_completion_dates.dart';
import 'practice_timing_service.dart';

class CompletionStatus {
  final int modulesDone;
  final int modulesTotal;
  final int practiceDone;
  final int practiceTotal;
  const CompletionStatus({
    required this.modulesDone,
    required this.modulesTotal,
    required this.practiceDone,
    required this.practiceTotal,
  });

  bool get isComplete =>
      modulesTotal > 0 &&
      practiceTotal > 0 &&
      modulesDone >= modulesTotal &&
      practiceDone >= practiceTotal;

  int get percent {
    final total = modulesTotal + practiceTotal;
    if (total == 0) return 0;
    return (((modulesDone + practiceDone) / total) * 100).floor();
  }
}

class CertificateInfo {
  final String recipientName;
  final DateTime issuedOn;
  final String certificateId;
  final List<String> languages;
  final int totalModules;
  final int totalExercises;

  /// null = the overall certificate (every language); otherwise the single
  /// language this certificate is for (e.g. "Java").
  final String? language;

  /// e.g. "Beginner to Advanced" (used by language certificates).
  final String levelRange;
  final String? practiceLevel;

  const CertificateInfo({
    required this.recipientName,
    required this.issuedOn,
    required this.certificateId,
    required this.languages,
    required this.totalModules,
    required this.totalExercises,
    this.language,
    this.levelRange = '',
    this.practiceLevel,
  });
}

class CertificateService {
  /// Date a certificate was first earned (per user, per scope). Cleared when
  /// progress is reset so a re-earned certificate gets a fresh date.
  static const String issuedKeyPrefix = 'certificate_issued_';
  static int? _cachedUserId;
  static int? _cachedProgressRevision;
  static Future<Map<String, CompletionStatus>>? _statusesFuture;

  /// Completion status of every language, in app order.
  static Future<Map<String, CompletionStatus>> getLanguageStatuses() {
    final userId = UserSession().dbId;
    final revision = ApiService.localProgressRevision;
    if (_cachedUserId == userId &&
        _cachedProgressRevision == revision &&
        _statusesFuture != null) {
      return _statusesFuture!;
    }

    _cachedUserId = userId;
    _cachedProgressRevision = revision;
    late final Future<Map<String, CompletionStatus>> future;
    future = _loadLanguageStatuses().then(
      (statuses) => statuses,
      onError: (Object error, StackTrace stackTrace) {
        if (identical(_statusesFuture, future)) {
          _statusesFuture = null;
        }
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
    _statusesFuture = future;
    return future;
  }

  static Future<Map<String, CompletionStatus>> _loadLanguageStatuses() async {
    final result = <String, CompletionStatus>{};
    final snapshot = await ApiService.getCertificateProgressSnapshot(
      languageQuizzes.map((language) => language.name).toList(growable: false),
    );
    for (final lang in languageQuizzes) {
      final languageProgress = snapshot[lang.name]!;
      var modulesDone = 0, total = 0, practiceDone = 0;
      for (final entry in lang.categories.entries) {
        for (var i = 0; i < entry.value.length; i++) {
          final id = '${entry.key.name}_${i + 1}';
          total++;
          if (languageProgress.modules.contains(id)) modulesDone++;
          if (languageProgress.answered.contains(id)) practiceDone++;
        }
      }
      result[lang.name] = CompletionStatus(
        modulesDone: modulesDone,
        modulesTotal: total,
        practiceDone: practiceDone,
        practiceTotal: total,
      );
    }
    return result;
  }

  /// Sum of several language statuses (used for the overall certificate).
  static CompletionStatus combine(Iterable<CompletionStatus> statuses) {
    var md = 0, mt = 0, pd = 0, pt = 0;
    for (final s in statuses) {
      md += s.modulesDone;
      mt += s.modulesTotal;
      pd += s.practiceDone;
      pt += s.practiceTotal;
    }
    return CompletionStatus(
      modulesDone: md,
      modulesTotal: mt,
      practiceDone: pd,
      practiceTotal: pt,
    );
  }

  /// Status for one language, or for everything when [language] is null.
  static Future<CompletionStatus> getStatus({String? language}) async {
    final statuses = await getLanguageStatuses();
    if (language == null) return combine(statuses.values);
    return statuses[language] ??
        const CompletionStatus(
          modulesDone: 0,
          modulesTotal: 0,
          practiceDone: 0,
          practiceTotal: 0,
        );
  }

  static String _scopeSuffix(String? language) {
    if (language == null) return '';
    final lower = language.toLowerCase();
    return '_${lower == 'c#' ? 'csharp' : lower}';
  }

  static String _idCode(String language) {
    switch (language.toLowerCase()) {
      case 'python':
        return 'PY';
      case 'c#':
        return 'CS';
      case 'javascript':
        return 'JS';
      default:
        final letters = language.toUpperCase().replaceAll(RegExp('[^A-Z]'), '');
        return letters.substring(0, letters.length < 4 ? letters.length : 4);
    }
  }

  /// Returns the certificate data, or null if it hasn't been earned yet.
  /// Pass [language] for a single-language certificate (e.g. "Java"); leave it
  /// null for the overall certificate.
  static Future<CertificateInfo?> getCertificate({String? language}) async {
    final status = await getStatus(language: language);
    if (!status.isComplete) return null;
    final practiceQuestionCount =
        await PracticeTimingService.getRecordedPracticeQuestionCount(
      language: language,
    );
    final practiceSeconds = await PracticeTimingService.getTotalPracticeSeconds(
      language: language,
    );
    final practiceLevel = practiceQuestionCount == status.practiceTotal
        ? PracticeTimingService.certificationLevelForSeconds(practiceSeconds)
        : null;

    final session = UserSession();
    final prefs = await SharedPreferences.getInstance();
    final key = '$issuedKeyPrefix${session.dbId}${_scopeSuffix(language)}';

    DateTime? issuedOn;
    if (language == null) {
      issuedOn = await CertificateCompletionDates.overallCompletedOn(
        languageQuizzes.map((quiz) => quiz.name),
      );
    } else {
      issuedOn = await CertificateCompletionDates.languageCompletedOn(language);
    }

    final stored = prefs.getString(key);
    if (issuedOn == null && stored != null) {
      issuedOn = DateTime.tryParse(stored);
    }
    issuedOn ??= DateTime.now();
    await prefs.setString(key, issuedOn.toIso8601String());

    final y = issuedOn.year.toString().padLeft(4, '0');
    final m = issuedOn.month.toString().padLeft(2, '0');
    final d = issuedOn.day.toString().padLeft(2, '0');
    final uid = session.dbId.toString().padLeft(6, '0');
    final code = language == null ? 'SKL' : 'SKL-${_idCode(language)}';

    var levelRange = '';
    if (language != null) {
      final quiz = languageQuizzes.firstWhere((l) => l.name == language);
      final labels = quiz.categories.keys.map((c) => c.label).toList();
      if (labels.isNotEmpty) {
        levelRange = labels.length == 1
            ? labels.first
            : '${labels.first} to ${labels.last}';
      }
    }

    return CertificateInfo(
      recipientName: session.displayName,
      issuedOn: issuedOn,
      certificateId: '$code-$uid-$y$m$d',
      languages: language == null
          ? languageQuizzes.map((l) => l.name).toList(growable: false)
          : [language],
      totalModules: status.modulesTotal,
      totalExercises: status.practiceTotal,
      language: language,
      levelRange: levelRange,
      practiceLevel: practiceLevel,
    );
  }
}
