// lib/services/ai_feedback_service.dart
// ─────────────────────────────────────────────────────────────
//  AI-reliance questionnaire (check-ins on the Practice page).
//
//  WHEN IT APPEARS
//    After the learner has answered 10 practice questions correctly
//    (10 different questions), and again for every further 10 correct
//    (20, 30, ...). Re-answering a question never counts twice.
//    The FIRST answered check-in is the learner's baseline ("pre");
//    every later check-in is a follow-up ("post") compared against it.
//
//  The SAME four questions and the SAME scoring method are used every time:
//
//    Q1  How often do you ask AI to generate code for you?          (frequency)
//    Q2  How often do you copy AI-generated code without fully
//        understanding it?                                          (frequency)
//    Q3  How confident are you in solving basic programming
//        problems without AI?                                       (confidence)
//    Q4  How confident are you in understanding and correcting
//        code independently?                                        (confidence)
//
//  Scoring - AI Reliance Index (0-100, higher = MORE reliance on AI):
//    Q1 and Q2 already point the "reliance" way.
//    Q3 and Q4 are reverse-scored (6 - answer), because high confidence
//    means LOW reliance.
//    mean  = (Q1 + Q2 + (6 - Q3) + (6 - Q4)) / 4        -> 1 ... 5
//    index = (mean - 1) / 4 x 100                        -> 0 ... 100
//    A negative (follow-up - baseline) change indicates lower self-reported
//    reliance.
//
//  Answers are always saved locally and also POSTed to /ai-feedback on a
//  best-effort basis.
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

enum AiFeedbackPhase { pre, post }

/// What happened when a check-in was saved.
class AiCheckpointOutcome {
  final double? index; // null when skipped
  final bool isBaseline; // this check-in became the learner's baseline
  final double? baseline; // the earlier baseline (null for the baseline itself)
  const AiCheckpointOutcome({
    required this.index,
    required this.isBaseline,
    required this.baseline,
  });
}

class AiRelianceQuestion {
  final String id; // q1 … q4
  final String text;
  final bool isConfidence; // true → reverse-scored
  final List<String> scale; // labels for answers 1 … 5
  const AiRelianceQuestion({
    required this.id,
    required this.text,
    required this.isConfidence,
    required this.scale,
  });
}

class AiFeedbackService {
  static const List<String> _frequencyScale = [
    'Never',
    'Rarely',
    'Sometimes',
    'Often',
    'Always',
  ];

  static const List<String> _confidenceScale = [
    'Not at all confident',
    'Slightly confident',
    'Moderately confident',
    'Very confident',
    'Extremely confident',
  ];

  /// Identical wording at the pre-test and every post-test.
  static const List<AiRelianceQuestion> questions = [
    AiRelianceQuestion(
      id: 'q1',
      text: 'How often do you ask AI to generate code for you?',
      isConfidence: false,
      scale: _frequencyScale,
    ),
    AiRelianceQuestion(
      id: 'q2',
      text: 'How often do you copy AI-generated code without fully '
          'understanding it?',
      isConfidence: false,
      scale: _frequencyScale,
    ),
    AiRelianceQuestion(
      id: 'q3',
      text: 'How confident are you in solving basic programming problems '
          'without AI?',
      isConfidence: true,
      scale: _confidenceScale,
    ),
    AiRelianceQuestion(
      id: 'q4',
      text: 'How confident are you in understanding and correcting code '
          'independently?',
      isConfidence: true,
      scale: _confidenceScale,
    ),
  ];

  // ── Scoring ────────────────────────────────────────────────────────────────

  /// AI Reliance Index from the four answers (each 1–5). 0 = lowest reliance,
  /// 100 = highest reliance.
  static double relianceIndex(List<int> answers) {
    assert(answers.length == questions.length);
    var total = 0;
    for (var i = 0; i < questions.length; i++) {
      final a = answers[i].clamp(1, 5).toInt();
      total += questions[i].isConfidence ? (6 - a) : a;
    }
    final mean = total / questions.length;
    final index = (mean - 1) / 4 * 100;
    return double.parse(index.toStringAsFixed(1));
  }

  // ── Trigger: every N correct practice questions ───────────────────────────

  /// A check-in is shown after every [checkpointEvery] correct questions.
  static const int checkpointEvery = 10;

  // ── Storage keys ───────────────────────────────────────────────────────────
  // Both "asked" keys start with 'ai_feedback_asked_' so Reset Progress clears
  // them (the counting then starts over). Saved answers are kept.

  /// Highest check-in level already shown (1 = after 10 correct, 2 = after 20 …).
  static const String checkpointKeyPrefix = 'ai_feedback_asked_checkpoint_';

  /// The distinct questions answered correctly, as "language|questionId".
  static const String correctKeyPrefix = 'ai_feedback_asked_correct_';

  /// Every saved response. Kept when progress is reset.
  static const String responsesKeyPrefix = 'ai_feedback_responses_';

  static String _checkpointKey(int userId) => '$checkpointKeyPrefix$userId';
  static String _correctKey(int userId) => '$correctKeyPrefix$userId';
  static String _responsesKey(int userId) => '$responsesKeyPrefix$userId';

  /// Call when the learner answers a practice question CORRECTLY.
  /// Returns the milestone just reached (10, 20, 30 …) when the AI-reliance
  /// check-in is due, otherwise null. Each milestone is returned only once.
  static Future<int?> registerCorrectAnswer({
    required int userId,
    required String language,
    required String questionId,
  }) async {
    if (userId <= 0) return null;
    final prefs = await SharedPreferences.getInstance();

    final correct = prefs.getStringList(_correctKey(userId)) ?? <String>[];
    final entry = '${language.toLowerCase()}|$questionId';
    if (!correct.contains(entry)) {
      correct.add(entry);
      await prefs.setStringList(_correctKey(userId), correct);
    }

    final level = correct.length ~/ checkpointEvery;
    final done = prefs.getInt(_checkpointKey(userId)) ?? 0;
    if (level < 1 || level <= done) return null;

    // Mark first so it can never repeat, even if the app closes mid-dialog.
    await prefs.setInt(_checkpointKey(userId), level);
    return level * checkpointEvery;
  }

  // ── Saving a check-in ──────────────────────────────────────────────────────

  /// The baseline AI Reliance Index (the first answered check-in), or null.
  static Future<double?> getBaselineIndex(int userId) async {
    final responses = await getResponses(userId);
    for (final r in responses) {
      if (r['phase'] == 'pre' && r['skipped'] != true) {
        return (r['reliance_index'] as num?)?.toDouble();
      }
    }
    return null;
  }

  /// Saves a check-in. Pass [answers] = null when the learner skipped it.
  /// The first answered check-in becomes the baseline ("pre"); later ones are
  /// follow-ups ("post").
  static Future<AiCheckpointOutcome> saveCheckpoint({
    required int userId,
    required int correctCount,
    required String language,
    required String categoryLabel,
    required List<int>? answers,
  }) async {
    final baseline = await getBaselineIndex(userId);
    final isBaseline = answers != null && baseline == null;

    final record = _buildRecord(
      userId: userId,
      phase: isBaseline ? AiFeedbackPhase.pre : AiFeedbackPhase.post,
      correctCount: correctCount,
      language: language,
      category: categoryLabel,
      answers: answers,
    );
    await _saveRecord(record);

    return AiCheckpointOutcome(
      index: (record['reliance_index'] as num?)?.toDouble(),
      isBaseline: isBaseline,
      baseline: baseline,
    );
  }

  // ── Reading back ───────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getResponses(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_responsesKey(userId)) ?? const [];
    final out = <Map<String, dynamic>>[];
    for (final s in stored) {
      try {
        out.add(jsonDecode(s) as Map<String, dynamic>);
      } catch (_) {
        // Ignore malformed / legacy entries.
      }
    }
    return out;
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  static Map<String, dynamic> _buildRecord({
    required int userId,
    required AiFeedbackPhase phase,
    required int correctCount,
    required String language,
    required String category,
    required List<int>? answers,
  }) {
    final a = answers;
    return <String, dynamic>{
      'user_id': userId,
      'phase': phase.name, // 'pre' (baseline) | 'post' (follow-up)
      'correct_count': correctCount,
      'language': language,
      'category': category,
      'q1': a?[0],
      'q2': a?[1],
      'q3': a?[2],
      'q4': a?[3],
      'reliance_index': a == null ? null : relianceIndex(a),
      'skipped': a == null,
      'answered_at': DateTime.now().toIso8601String(),
    };
  }

  static Future<void> _saveRecord(Map<String, dynamic> record) async {
    final userId = record['user_id'] as int;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_responsesKey(userId)) ?? <String>[];
      await prefs.setStringList(
        _responsesKey(userId),
        [...stored, jsonEncode(record)],
      );
    } catch (e) {
      debugPrint('AiFeedbackService: could not save locally: $e');
    }

    if (record['skipped'] != true) {
      await _sendToServer(record);
    }
  }

  static Future<void> _sendToServer(Map<String, dynamic> record) async {
    try {
      await http
          .post(
            Uri.parse('${ApiService.baseUrl()}/ai-feedback'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': record['user_id'],
              'phase': record['phase'],
              'correct_count': record['correct_count'],
              'language': record['language'],
              'category': record['category'],
              'q1': record['q1'],
              'q2': record['q2'],
              'q3': record['q3'],
              'q4': record['q4'],
              'reliance_index': record['reliance_index'],
            }),
          )
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      // Offline or endpoint not available yet — the local copy is enough.
      debugPrint('AiFeedbackService: server upload skipped: $e');
    }
  }
}
