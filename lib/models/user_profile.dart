import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile extends ChangeNotifier {
  static final UserProfile _instance = UserProfile._();
  UserProfile._();
  factory UserProfile() => _instance;

  String? _gateAnswer;
  String? get gateAnswer => _gateAnswer;
  Map<String, int> _assessment = {};
  Map<String, int> get assessment => Map.unmodifiable(_assessment);

  void setGateAnswer(String answer) {
    _gateAnswer = answer;
    notifyListeners();
  }

  void setAssessmentAnswers(Map<String, int> answers) {
    _assessment = Map<String, int>.from(answers);
    notifyListeners();
  }

  String get skillLevelLabel {
    switch (experienceLevel) {
      case 'expert':
        return 'Advanced';
      case 'intermediate':
        return 'Intermediate';
      case 'beginner':
        return 'Beginner';
      default:
        return 'Getting Started';
    }
  }

  Future<void> saveAssessment(int userId) async {
    if (userId <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'profile_assessment_$userId',
      jsonEncode({
        'gate_answer': _gateAnswer,
        'answers': _assessment,
      }),
    );
  }

  Future<void> loadAssessment(int userId) async {
    if (userId <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString('profile_assessment_$userId');
    _gateAnswer = null;
    _assessment = {};
    if (encoded != null) {
      final decoded = jsonDecode(encoded);
      if (decoded is Map<String, dynamic>) {
        _gateAnswer = decoded['gate_answer'] as String?;
        final answers = decoded['answers'];
        if (answers is Map<String, dynamic>) {
          _assessment = answers.map(
            (key, value) => MapEntry(key, (value as num).toInt()),
          );
        }
      }
    }
    notifyListeners();
  }

  Future<void> clearAssessment(int userId) async {
    if (userId > 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_assessment_$userId');
    }
    _gateAnswer = null;
    _assessment = {};
    notifyListeners();
  }

  String get experienceLevel {
    if (_assessment.isEmpty && _gateAnswer == null) return 'beginner';
    var score = _assessment.values.fold<int>(0, (a, b) => a + b);
    final a = (_gateAnswer ?? '').toLowerCase();
    if (a.contains('regularly') || a.contains('solid')) score += 5;
    if (a.contains('little') || a.contains('basics')) score += 3;
    if (score >= 14) return 'expert';
    if (score >= 10) return 'intermediate';
    if (score >= 6) return 'beginner';
    return 'novice';
  }

  List<RecommendedTopic> get recommendedTopics {
    switch (experienceLevel) {
      case 'expert':
        return [
          const RecommendedTopic(
            icon: Icons.account_tree_outlined,
            title: 'Java',
            desc: 'Advanced OOP, data structures, and algorithm drills.',
            color: Color(0xFFB57BFF),
            tag: 'Advanced',
          ),
          const RecommendedTopic(
            icon: Icons.bolt_outlined,
            title: 'JavaScript',
            desc: 'Async patterns, callbacks, and advanced language flow.',
            color: Color(0xFF00CFFF),
            tag: 'Advanced',
          ),
          const RecommendedTopic(
            icon: Icons.layers_outlined,
            title: 'SQL',
            desc: 'Window functions, CTEs, and performance-oriented queries.',
            color: Color(0xFFFF9A3C),
            tag: 'Advanced',
          ),
        ];
      case 'intermediate':
        return [
          const RecommendedTopic(
            icon: Icons.code,
            title: 'Python',
            desc: 'Functions, loops, and practical debugging workflow.',
            color: Color(0xFF00CFFF),
            tag: 'Intermediate',
          ),
          const RecommendedTopic(
            icon: Icons.terminal_outlined,
            title: 'C#',
            desc: 'Control flow, methods, and problem-solving patterns.',
            color: Color(0xFF00D68F),
            tag: 'Intermediate',
          ),
          const RecommendedTopic(
            icon: Icons.storage_outlined,
            title: 'SQL',
            desc: 'Filtering, joins, and query structure fundamentals.',
            color: Color(0xFFFF9A3C),
            tag: 'Intermediate',
          ),
        ];
      case 'beginner':
        return [
          const RecommendedTopic(
            icon: Icons.code,
            title: 'Python',
            desc: 'Start with readable syntax and coding basics.',
            color: Color(0xFF00D68F),
            tag: 'Beginner',
          ),
          const RecommendedTopic(
            icon: Icons.coffee_outlined,
            title: 'Java',
            desc: 'Learn typed variables, conditionals, and loops.',
            color: Color(0xFF00CFFF),
            tag: 'Beginner',
          ),
          const RecommendedTopic(
            icon: Icons.javascript_outlined,
            title: 'JavaScript',
            desc: 'Understand syntax and browser-side programming.',
            color: Color(0xFFB57BFF),
            tag: 'Beginner',
          ),
        ];
      default:
        return [
          const RecommendedTopic(
            icon: Icons.lightbulb_outline,
            title: 'Python',
            desc: 'First-time learner path with simple coding exercises.',
            color: Color(0xFF00CFFF),
            tag: 'Start Here',
          ),
          const RecommendedTopic(
            icon: Icons.storage_outlined,
            title: 'SQL',
            desc: 'Query basics for understanding database results.',
            color: Color(0xFF00D68F),
            tag: 'Beginner',
          ),
          const RecommendedTopic(
            icon: Icons.javascript_outlined,
            title: 'JavaScript',
            desc: 'Interactive learning with immediate visual outputs.',
            color: Color(0xFFFF9A3C),
            tag: 'Beginner',
          ),
        ];
    }
  }
}

class RecommendedTopic {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  final String tag;
  const RecommendedTopic({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
    required this.tag,
  });
}
