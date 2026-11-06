// lib/services/recommendation_service.dart
// ─────────────────────────────────────────────────────────────
//  Rule-based recommendation engine (predictive analysis).
//
//  STEP 1  Record the exercise result      → AttemptHistory.record()
//          (learner, language, topic, exercise, correctness, time)
//  STEP 2  Retrieve the recent attempts    → up to the 5 most recent attempts
//          for the same learner + topic       (a topic = language + level,
//                                              e.g. "Java · Beginner")
//  STEP 3  Calculate the performance rate  → Accuracy = correct / total × 100
//  STEP 4  Apply the rules                 → RecommendationEngine.evaluate()
//  STEP 5  Display the recommendation      → RecommendationCard widget
//
//  RULES
//    Rule 4  Insufficient Data     fewer than 5 recorded attempts
//    Rule 1  Needs Improvement     accuracy below 60 %
//    Rule 2  Moderate Performance  accuracy 60 % – 79 %
//    Rule 3  Good Performance      accuracy 80 % or higher
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_data.dart';

// ═════════════════════════════════════════════════════════════════════════════
// STEP 1 – attempt history
// ═════════════════════════════════════════════════════════════════════════════

class AttemptRecord {
  final String language; // e.g. "Java"
  final String category; // QuizCategory.name, e.g. "beginner"
  final String questionId; // e.g. "beginner_3"
  final bool isCorrect;
  final DateTime submittedAt;
  const AttemptRecord({
    required this.language,
    required this.category,
    required this.questionId,
    required this.isCorrect,
    required this.submittedAt,
  });

  Map<String, dynamic> toJson() => {
        'language': language,
        'category': category,
        'question_id': questionId,
        'is_correct': isCorrect,
        'submitted_at': submittedAt.toIso8601String(),
      };

  static AttemptRecord? fromJson(Map<String, dynamic> j) {
    final at = DateTime.tryParse('${j['submitted_at']}');
    if (at == null) return null;
    return AttemptRecord(
      language: '${j['language']}',
      category: '${j['category']}',
      questionId: '${j['question_id']}',
      isCorrect: j['is_correct'] == true,
      submittedAt: at,
    );
  }
}

class AttemptHistory {
  /// Per-user list of attempts. Cleared when progress is reset.
  static const String keyPrefix = 'attempt_history_';
  static const int maxRecords = 1000;

  static String _key(int userId) => '$keyPrefix$userId';

  /// Saves one submitted answer (correct or not).
  static Future<void> record({
    required int userId,
    required String language,
    required String category,
    required String questionId,
    required bool isCorrect,
    DateTime? at,
  }) async {
    if (userId <= 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_key(userId)) ?? <String>[];
      final entry = jsonEncode(AttemptRecord(
        language: language,
        category: category,
        questionId: questionId,
        isCorrect: isCorrect,
        submittedAt: at ?? DateTime.now(),
      ).toJson());
      final updated = [...stored, entry];
      final trimmed = updated.length > maxRecords
          ? updated.sublist(updated.length - maxRecords)
          : updated;
      await prefs.setStringList(_key(userId), trimmed);
    } catch (e) {
      debugPrint('AttemptHistory: could not record attempt: $e');
    }
  }

  /// STEP 2 – the [limit] most recent attempts for one learner + topic,
  /// newest first.
  static Future<List<AttemptRecord>> recent({
    required int userId,
    required String language,
    required String category,
    int limit = 5,
  }) async {
    if (userId <= 0) return const [];
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_key(userId)) ?? const <String>[];
    final out = <AttemptRecord>[];
    for (var i = stored.length - 1; i >= 0 && out.length < limit; i--) {
      try {
        final r = AttemptRecord.fromJson(
            jsonDecode(stored[i]) as Map<String, dynamic>);
        if (r != null && r.language == language && r.category == category) {
          out.add(r);
        }
      } catch (_) {
        // skip malformed entries
      }
    }
    return out;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// STEPS 3 & 4 – performance rate + rules
// ═════════════════════════════════════════════════════════════════════════════

enum RecommendationRule {
  needsImprovement, // Rule 1
  moderatePerformance, // Rule 2
  goodPerformance, // Rule 3
  insufficientData, // Rule 4
}

extension RecommendationRuleX on RecommendationRule {
  String get label {
    switch (this) {
      case RecommendationRule.needsImprovement:
        return 'Rule 1: Needs Improvement';
      case RecommendationRule.moderatePerformance:
        return 'Rule 2: Moderate Performance';
      case RecommendationRule.goodPerformance:
        return 'Rule 3: Good Performance';
      case RecommendationRule.insufficientData:
        return 'Rule 4: Insufficient Data';
    }
  }

  /// Short status shown as a chip.
  String get status {
    switch (this) {
      case RecommendationRule.needsImprovement:
        return 'NEEDS IMPROVEMENT';
      case RecommendationRule.moderatePerformance:
        return 'MODERATE';
      case RecommendationRule.goodPerformance:
        return 'GOOD';
      case RecommendationRule.insufficientData:
        return 'NOT ENOUGH DATA';
    }
  }
}

class Recommendation {
  final RecommendationRule rule;
  final int attempts; // attempts in the window (0–5)
  final int correct;
  final double? accuracy; // null when there is insufficient data
  final List<bool> recent; // newest first
  final String message; // the recommendation shown to the learner

  const Recommendation({
    required this.rule,
    required this.attempts,
    required this.correct,
    required this.accuracy,
    required this.recent,
    required this.message,
  });
}

class RecommendationEngine {
  /// Number of most recent attempts that are considered.
  static const int windowSize = 5;

  /// Accuracy below this → Rule 1.
  static const double needsImprovementBelow = 60;

  /// Accuracy at or above this → Rule 3. (Between the two → Rule 2.)
  static const double goodAtLeast = 80;

  /// Pure rule evaluation. [recentNewestFirst] holds the correctness of the
  /// learner's most recent attempts in one topic (extra items are ignored).
  /// [nextTopicLabel] is the next level, if there is one (used by Rule 3).
  static Recommendation evaluate(
    List<bool> recentNewestFirst, {
    String? nextTopicLabel,
  }) {
    final window = recentNewestFirst.take(windowSize).toList();
    final attempts = window.length;
    final correct = window.where((c) => c).length;

    // Rule 4 – fewer than 5 recorded attempts.
    if (attempts < windowSize) {
      return Recommendation(
        rule: RecommendationRule.insufficientData,
        attempts: attempts,
        correct: correct,
        accuracy: null,
        recent: window,
        message: 'Submit more answers in this topic to get a '
            'performance-based recommendation.',
      );
    }

    // STEP 3 – Accuracy Rate = correct attempts / total attempts × 100
    final accuracy = correct / attempts * 100;

    // STEP 4 – apply the rules.
    if (accuracy < needsImprovementBelow) {
      return Recommendation(
        rule: RecommendationRule.needsImprovement,
        attempts: attempts,
        correct: correct,
        accuracy: accuracy,
        recent: window,
        message: 'Review the corresponding lesson and retry the exercises.',
      );
    }
    if (accuracy < goodAtLeast) {
      return Recommendation(
        rule: RecommendationRule.moderatePerformance,
        attempts: attempts,
        correct: correct,
        accuracy: accuracy,
        recent: window,
        message: 'Practice additional exercises related to this topic.',
      );
    }
    return Recommendation(
      rule: RecommendationRule.goodPerformance,
      attempts: attempts,
      correct: correct,
      accuracy: accuracy,
      recent: window,
      message: nextTopicLabel == null
          ? 'Great work! Attempt a more challenging exercise, if available.'
          : 'Continue to the next topic ($nextTopicLabel) or attempt a more '
              'challenging exercise, if available.',
    );
  }

  /// Runs steps 2–4 for one learner and one topic (language + level).
  static Future<Recommendation> forTopic({
    required int userId,
    required LanguageQuiz lang,
    required QuizCategory category,
  }) async {
    final attempts = await AttemptHistory.recent(
      userId: userId,
      language: lang.name,
      category: category.name,
      limit: windowSize,
    );

    final order = lang.categories.keys.toList();
    final idx = order.indexOf(category);
    final next = (idx >= 0 && idx + 1 < order.length) ? order[idx + 1] : null;

    return evaluate(
      attempts.map((a) => a.isCorrect).toList(),
      nextTopicLabel: next?.label,
    );
  }
}
