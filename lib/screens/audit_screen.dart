import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../models/user_session.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  final _session = UserSession();
  bool _loading = true;
  List<Map<String, dynamic>> _weaknessAnalysis = [];
  List<Map<String, dynamic>> _improvementSuggestions = [];
  List<Map<String, dynamic>> _historicalData = [];
  List<Map<String, dynamic>> _practiceRecommendations = [];

  bool get _isNewUser {
    return _session.dbId == 0 ||
        !_session.languageProgress.values.any((progress) => progress > 0);
  }

  @override
  void initState() {
    super.initState();
    _generateAuditData();
  }

  // Generate comprehensive audit data based on user progress
  void _generateAuditData() {
    debugPrint('AuditScreen: Generating comprehensive audit data...');

    // Generate weakness analysis
    _generateWeaknessAnalysis();

    // Generate improvement suggestions
    _generateImprovementSuggestions();

    // Generate historical comparison
    _generateHistoricalData();

    // Generate practice recommendations
    _generatePracticeRecommendations();

    setState(() {
      _loading = false;
    });

    debugPrint('AuditScreen: Audit data generation complete');
  }

  // Generate detailed weakness analysis
  void _generateWeaknessAnalysis() {
    _weaknessAnalysis = [];

    // Check if user has any progress (not a new user)
    bool hasAnyProgress = _session.languageProgress.values.any((p) => p > 0);
    if (!hasAnyProgress) {
      debugPrint(
          'AuditScreen: New user with no progress - weakness analysis empty');
      return; // Empty analysis for new users
    }

    _session.languageProgress.forEach((language, progress) {
      if (progress < 0.5 && progress > 0) {
        final analysis = _getLanguageWeaknessAnalysis(language, progress);
        _weaknessAnalysis.add(analysis);
      }
    });

    // Sort by severity (lowest progress first)
    _weaknessAnalysis.sort(
        (a, b) => (a['progress'] as double).compareTo(b['progress'] as double));
  }

  // Get detailed weakness analysis for a language
  Map<String, dynamic> _getLanguageWeaknessAnalysis(
      String language, double progress) {
    final topics = _getWeakTopics(language, progress);
    final severity = _getSeverityLevel(progress);
    final estimatedTime = _getEstimatedImprovementTime(progress);

    return {
      'language': language,
      'progress': progress,
      'severity': severity,
      'estimatedTime': estimatedTime,
      'weakTopics': topics,
      'recentErrors': _getRecentErrors(language),
      'commonMistakes': _getCommonMistakes(language),
    };
  }

  // Get weak topics for a language
  List<Map<String, dynamic>> _getWeakTopics(String language, double progress) {
    final topics = <Map<String, dynamic>>[];

    switch (language) {
      case 'Java':
        topics.addAll([
          {
            'topic': 'Exception Handling',
            'mastery': progress * 0.6,
            'priority': 'High'
          },
          {
            'topic': 'Generics',
            'mastery': progress * 0.5,
            'priority': 'Medium'
          },
          {
            'topic': 'Multithreading',
            'mastery': progress * 0.4,
            'priority': 'High'
          },
        ]);
        break;
      case 'Python':
        topics.addAll([
          {
            'topic': 'Decorators',
            'mastery': progress * 0.5,
            'priority': 'Medium'
          },
          {
            'topic': 'List Comprehensions',
            'mastery': progress * 0.7,
            'priority': 'Low'
          },
          {
            'topic': 'File I/O',
            'mastery': progress * 0.6,
            'priority': 'Medium'
          },
        ]);
        break;
      case 'JavaScript':
        topics.addAll([
          {
            'topic': 'Async/Await',
            'mastery': progress * 0.4,
            'priority': 'High'
          },
          {
            'topic': 'Closures',
            'mastery': progress * 0.5,
            'priority': 'Medium'
          },
          {
            'topic': 'Prototypes',
            'mastery': progress * 0.3,
            'priority': 'High'
          },
        ]);
        break;
      case 'C#':
        topics.addAll([
          {'topic': 'LINQ', 'mastery': progress * 0.5, 'priority': 'Medium'},
          {'topic': 'Delegates', 'mastery': progress * 0.4, 'priority': 'High'},
          {'topic': 'Events', 'mastery': progress * 0.6, 'priority': 'Medium'},
        ]);
        break;
      case 'SQL':
        topics.addAll([
          {
            'topic': 'Window Functions',
            'mastery': progress * 0.3,
            'priority': 'High'
          },
          {
            'topic': 'Subqueries',
            'mastery': progress * 0.5,
            'priority': 'Medium'
          },
          {'topic': 'Indexing', 'mastery': progress * 0.4, 'priority': 'High'},
        ]);
        break;
    }

    return topics;
  }

  // Get severity level based on progress
  String _getSeverityLevel(double progress) {
    if (progress < 0.2) return 'Critical';
    if (progress < 0.35) return 'High';
    if (progress < 0.5) return 'Medium';
    return 'Low';
  }

  // Get estimated improvement time
  String _getEstimatedImprovementTime(double progress) {
    if (progress < 0.2) return '2-3 weeks';
    if (progress < 0.35) return '1-2 weeks';
    if (progress < 0.5) return '1 week';
    return '3-5 days';
  }

  // Get recent errors for language
  List<String> _getRecentErrors(String language) {
    switch (language) {
      case 'Java':
        return [
          'NullPointerException',
          'ArrayIndexOutOfBounds',
          'ClassCastException'
        ];
      case 'Python':
        return ['IndentationError', 'KeyError', 'AttributeError'];
      case 'JavaScript':
        return ['TypeError', 'ReferenceError', 'Undefined is not a function'];
      case 'C#':
        return [
          'NullReferenceException',
          'IndexOutOfRangeException',
          'InvalidCastException'
        ];
      case 'SQL':
        return ['Syntax Error', 'Constraint Violation', 'Division by zero'];
      default:
        return ['General syntax errors'];
    }
  }

  // Get common mistakes for language
  List<String> _getCommonMistakes(String language) {
    switch (language) {
      case 'Java':
        return [
          'Forgetting to handle exceptions',
          'Incorrect array bounds',
          'Type casting errors'
        ];
      case 'Python':
        return [
          'Incorrect indentation',
          'Dictionary key errors',
          'Variable scope issues'
        ];
      case 'JavaScript':
        return [
          'Async function misuse',
          'This context confusion',
          'Promise rejection handling'
        ];
      case 'C#':
        return [
          'Null reference exceptions',
          'LINQ query errors',
          'Event handler issues'
        ];
      case 'SQL':
        return [
          'Missing JOIN conditions',
          'Incorrect GROUP BY usage',
          'Subquery optimization'
        ];
      default:
        return ['Basic syntax mistakes'];
    }
  }

  // Generate improvement suggestions
  void _generateImprovementSuggestions() {
    _improvementSuggestions = [];

    // No suggestions for new users
    if (_weaknessAnalysis.isEmpty) {
      debugPrint('AuditScreen: New user - improvement suggestions empty');
      return;
    }

    for (final weakness in _weaknessAnalysis) {
      final language = weakness['language'] as String;
      final progress = weakness['progress'] as double;

      final suggestions = _getLanguageSpecificSuggestions(language, progress);
      _improvementSuggestions.addAll(suggestions);
    }

    // Sort by priority
    _improvementSuggestions.sort((a, b) {
      final priorityOrder = {'High': 3, 'Medium': 2, 'Low': 1};
      final aPriority = priorityOrder[a['priority']] ?? 0;
      final bPriority = priorityOrder[b['priority']] ?? 0;
      return bPriority.compareTo(aPriority);
    });
  }

  // Get language-specific improvement suggestions
  List<Map<String, dynamic>> _getLanguageSpecificSuggestions(
      String language, double progress) {
    final suggestions = <Map<String, dynamic>>[];

    switch (language) {
      case 'Java':
        suggestions.addAll([
          {
            'title': 'Master Exception Handling',
            'description':
                'Focus on try-catch-finally blocks and custom exceptions',
            'priority': 'High',
            'estimatedTime': '3-4 days',
            'resources': [
              'Java Documentation',
              'Practice problems',
              'Code reviews'
            ],
          },
          {
            'title': 'Understand Generics',
            'description': 'Learn generic types, wildcards, and type erasure',
            'priority': 'Medium',
            'estimatedTime': '2-3 days',
            'resources': [
              'Online tutorials',
              'Sample projects',
              'Stack Overflow'
            ],
          },
        ]);
        break;
      case 'Python':
        suggestions.addAll([
          {
            'title': 'Master Decorators',
            'description': 'Understand function decorators and their use cases',
            'priority': 'Medium',
            'estimatedTime': '2-3 days',
            'resources': [
              'Python docs',
              'Real-world examples',
              'Practice exercises'
            ],
          },
          {
            'title': 'Improve List Comprehensions',
            'description': 'Learn efficient list manipulation techniques',
            'priority': 'Low',
            'estimatedTime': '1-2 days',
            'resources': [
              'Python tutorials',
              'Code challenges',
              'Performance guides'
            ],
          },
        ]);
        break;
      case 'JavaScript':
        suggestions.addAll([
          {
            'title': 'Master Async Programming',
            'description':
                'Deep dive into Promises, async/await, and error handling',
            'priority': 'High',
            'estimatedTime': '4-5 days',
            'resources': [
              'MDN Web Docs',
              'Async patterns guide',
              'Practice projects'
            ],
          },
          {
            'title': 'Understand Closures',
            'description':
                'Learn how closures work and their practical applications',
            'priority': 'Medium',
            'estimatedTime': '2-3 days',
            'resources': [
              'JavaScript.info',
              'Interactive exercises',
              'Code examples'
            ],
          },
        ]);
        break;
      case 'C#':
        suggestions.addAll([
          {
            'title': 'Master LINQ',
            'description':
                'Learn query syntax and method syntax for data manipulation',
            'priority': 'Medium',
            'estimatedTime': '3-4 days',
            'resources': [
              'Microsoft Docs',
              'LINQ examples',
              'Practice datasets'
            ],
          },
          {
            'title': 'Understand Delegates',
            'description':
                'Learn delegate types, events, and lambda expressions',
            'priority': 'High',
            'estimatedTime': '2-3 days',
            'resources': [
              'C# documentation',
              'Event-driven examples',
              'Practice apps'
            ],
          },
        ]);
        break;
      case 'SQL':
        suggestions.addAll([
          {
            'title': 'Master Window Functions',
            'description': 'Learn ROW_NUMBER, RANK, and analytic functions',
            'priority': 'High',
            'estimatedTime': '3-4 days',
            'resources': [
              'SQL tutorials',
              'Sample databases',
              'Practice queries'
            ],
          },
          {
            'title': 'Optimize Subqueries',
            'description':
                'Improve query performance with proper subquery usage',
            'priority': 'Medium',
            'estimatedTime': '2-3 days',
            'resources': [
              'Query optimization guides',
              'Execution plans',
              'Performance tools'
            ],
          },
        ]);
        break;
    }

    return suggestions;
  }

  // Generate historical comparison data
  void _generateHistoricalData() {
    _historicalData = [];

    // Always create a baseline history view even for new users or users without progress
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final weekDate = now.subtract(Duration(days: i * 7));
      final weekData = _generateWeekData(weekDate, i);
      _historicalData.add(weekData);
    }
  }

  // Generate data for a specific week
  Map<String, dynamic> _generateWeekData(DateTime weekDate, int weeksAgo) {
    final weekProgress = <String, double>{};

    _session.languageProgress.forEach((language, currentProgress) {
      final pastProgress = _isNewUser
          ? 0.0
          : (currentProgress * (1 - (weeksAgo * 0.1)))
              .clamp(0.0, currentProgress);
      weekProgress[language] = pastProgress;
    });

    return {
      'week': 'Week ${6 - weeksAgo}',
      'date': weekDate,
      'progress': weekProgress,
      'totalWeakAreas': _calculateWeakAreasCount(weekProgress),
      'improvementRate': _calculateImprovementRate(weeksAgo),
    };
  }

  // Calculate weak areas count for historical data
  int _calculateWeakAreasCount(Map<String, double> progress) {
    return progress.values.where((p) => p < 0.5).length;
  }

  // Calculate improvement rate
  double _calculateImprovementRate(int weeksAgo) {
    if (weeksAgo == 0) return 0.0;

    final totalProgress =
        _session.languageProgress.values.reduce((a, b) => a + b);
    if (totalProgress == 0) {
      return 0.0;
    }

    return (0.15 * (6 - weeksAgo) / 5).clamp(0.0, 1.0); // Simulated improvement
  }

  // Generate practice recommendations
  void _generatePracticeRecommendations() {
    _practiceRecommendations = [];

    for (final weakness in _weaknessAnalysis) {
      final language = weakness['language'] as String;
      final weakTopics = weakness['weakTopics'] as List<Map<String, dynamic>>;

      for (final topic in weakTopics) {
        final recommendation = _generateTopicRecommendation(language, topic);
        _practiceRecommendations.add(recommendation);
      }
    }

    // Sort by priority and take top 10
    _practiceRecommendations.sort((a, b) {
      final priorityOrder = {'High': 3, 'Medium': 2, 'Low': 1};
      final aPriority = priorityOrder[a['priority']] ?? 0;
      final bPriority = priorityOrder[b['priority']] ?? 0;
      return bPriority.compareTo(aPriority);
    });

    _practiceRecommendations = _practiceRecommendations.take(10).toList();
  }

  // Generate specific practice recommendation for a topic
  Map<String, dynamic> _generateTopicRecommendation(
      String language, Map<String, dynamic> topic) {
    final topicName = topic['topic'] as String;
    final mastery = topic['mastery'] as double;
    final priority = topic['priority'] as String;

    return {
      'language': language,
      'topic': topicName,
      'currentMastery': mastery,
      'targetMastery': 0.8,
      'priority': priority,
      'practiceType': _getPracticeType(language, topicName),
      'estimatedSessions': _getEstimatedSessions(mastery),
      'difficulty': _getDifficulty(mastery),
      'nextSteps': _getNextSteps(language, topicName),
    };
  }

  // Get practice type for topic
  String _getPracticeType(String language, String topic) {
    if (topic.contains('Exception') || topic.contains('Error')) {
      return 'Debugging';
    }
    if (topic.contains('Async') || topic.contains('Thread')) {
      return 'Concurrency';
    }
    if (topic.contains('Query') || topic.contains('SQL')) {
      return 'Database';
    }
    if (topic.contains('List') || topic.contains('Array')) {
      return 'Data Structures';
    }
    return 'General Practice';
  }

  // Get estimated practice sessions needed
  int _getEstimatedSessions(double mastery) {
    if (mastery < 0.3) return 8;
    if (mastery < 0.5) return 6;
    if (mastery < 0.7) return 4;
    return 2;
  }

  // Get difficulty level
  String _getDifficulty(double mastery) {
    if (mastery < 0.3) return 'Beginner';
    if (mastery < 0.6) return 'Intermediate';
    return 'Advanced';
  }

  // Get next steps for improvement
  List<String> _getNextSteps(String language, String topic) {
    return [
      'Review $topic fundamentals',
      'Complete 3 practice exercises',
      'Build a mini-project using $topic',
      'Get code review from peers',
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: context.clBg,
        body: const Center(
          child: CircularProgressIndicator(color: SiklabColors.cyan),
        ),
      );
    }

    final bg = context.clBg;
    final bgCard = context.clBgCard;
    final border = context.clBorder;
    final txtPri = context.clTextPrimary;
    final txtSec = context.clTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SiklabBackButton(),
                      SizedBox(width: 8),
                      SiklabLogo(),
                    ],
                  ),
                  SiklabHamburgerMenu(),
                ],
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Performance\nAudit Report',
                style: GoogleFonts.spaceGrotesk(
                  color: txtPri,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Comprehensive analysis of your learning weaknesses and improvement paths',
                style: GoogleFonts.sourceCodePro(
                  color: txtSec,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),

              // Weakness Analysis Section
              _buildWeaknessAnalysisSection(bgCard, border, txtPri, txtSec),
              const SizedBox(height: 20),

              // Improvement Suggestions Section
              _buildImprovementSuggestionsSection(
                  bgCard, border, txtPri, txtSec),
              const SizedBox(height: 20),

              // Historical Comparison Section
              _buildHistoricalComparisonSection(bgCard, border, txtPri, txtSec),
              const SizedBox(height: 20),

              // Practice Recommendations Section
              _buildPracticeRecommendationsSection(
                  bgCard, border, txtPri, txtSec),
            ],
          ),
        ),
      ),
    );
  }

  // Build weakness analysis section
  Widget _buildWeaknessAnalysisSection(
      Color bgCard, Color border, Color txtPri, Color txtSec) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined,
                  color: SiklabColors.error, size: 20),
              const SizedBox(width: 8),
              Text(
                'Weakness Analysis',
                style: GoogleFonts.spaceGrotesk(
                  color: txtPri,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_weaknessAnalysis.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No weakness data available yet. Start learning to generate a personalized audit.',
                style: GoogleFonts.sourceCodePro(
                  color: txtSec,
                  fontSize: 12,
                ),
              ),
            )
          else
            ..._weaknessAnalysis.map((weakness) =>
                _buildWeaknessCard(weakness, txtSec, border, txtPri)),
        ],
      ),
    );
  }

  // Build individual weakness card
  Widget _buildWeaknessCard(
      Map<String, dynamic> weakness, Color txtSec, Color border, Color txtPri) {
    final language = weakness['language'] as String;
    final progress = weakness['progress'] as double;
    final severity = weakness['severity'] as String;
    final estimatedTime = weakness['estimatedTime'] as String;
    final weakTopics = weakness['weakTopics'] as List<Map<String, dynamic>>;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.clBgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                language,
                style: GoogleFonts.spaceGrotesk(
                  color: txtPri,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSeverityColor(severity).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  severity,
                  style: GoogleFonts.sourceCodePro(
                    color: _getSeverityColor(severity),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Progress: ${(progress * 100).toInt()}%',
                style: GoogleFonts.sourceCodePro(
                  color: txtSec,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Est. time: $estimatedTime',
                style: GoogleFonts.sourceCodePro(
                  color: txtSec,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Weak Topics:',
            style: GoogleFonts.sourceCodePro(
              color: txtSec,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          ...weakTopics.map((topic) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 4, color: txtSec),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${topic['topic']} (${(topic['mastery'] * 100).toInt()}%)',
                        style: GoogleFonts.sourceCodePro(
                          color: txtSec,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(topic['priority'])
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        topic['priority'],
                        style: GoogleFonts.sourceCodePro(
                          color: _getPriorityColor(topic['priority']),
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // Build improvement suggestions section
  Widget _buildImprovementSuggestionsSection(
      Color bgCard, Color border, Color txtPri, Color txtSec) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  color: SiklabColors.cyan, size: 20),
              const SizedBox(width: 8),
              Text(
                'Improvement Suggestions',
                style: GoogleFonts.spaceGrotesk(
                  color: txtPri,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_improvementSuggestions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No improvement suggestions yet. Complete your first learning activity to see targeted guidance.',
                style: GoogleFonts.sourceCodePro(
                  color: txtSec,
                  fontSize: 12,
                ),
              ),
            )
          else
            ..._improvementSuggestions.take(5).map((suggestion) =>
                _buildSuggestionCard(suggestion, txtSec, border, txtPri)),
        ],
      ),
    );
  }

  // Build suggestion card
  Widget _buildSuggestionCard(Map<String, dynamic> suggestion, Color txtSec,
      Color border, Color txtPri) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.clBgElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  suggestion['title'],
                  style: GoogleFonts.spaceGrotesk(
                    color: txtPri,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPriorityColor(suggestion['priority'])
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  suggestion['priority'],
                  style: GoogleFonts.sourceCodePro(
                    color: _getPriorityColor(suggestion['priority']),
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            suggestion['description'],
            style: GoogleFonts.sourceCodePro(
              color: txtSec,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, size: 12, color: txtSec),
              const SizedBox(width: 4),
              Text(
                suggestion['estimatedTime'],
                style: GoogleFonts.sourceCodePro(
                  color: txtSec,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build historical comparison section
  Widget _buildHistoricalComparisonSection(
      Color bgCard, Color border, Color txtPri, Color txtSec) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up,
                  color: SiklabColors.success, size: 20),
              const SizedBox(width: 8),
              Text(
                'Historical Comparison',
                style: GoogleFonts.spaceGrotesk(
                  color: txtPri,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isNewUser)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No historical comparisons available yet. Use the app for a few sessions to start building your progress history.',
                style: GoogleFonts.sourceCodePro(
                  color: txtSec,
                  fontSize: 12,
                ),
              ),
            )
          else
            ..._historicalData
                .map((week) => _buildWeekCard(week, txtSec, border, txtPri)),
        ],
      ),
    );
  }

  // Build week card for historical data
  Widget _buildWeekCard(
      Map<String, dynamic> week, Color txtSec, Color border, Color txtPri) {
    final weekName = week['week'] as String;
    final date = week['date'] as DateTime;
    final weakArea = week['totalWeakAreas'] as int;
    final improvementRate = week['improvementRate'] as double;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.clBgElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weekName,
                  style: GoogleFonts.spaceGrotesk(
                    color: txtPri,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: GoogleFonts.sourceCodePro(
                    color: txtSec,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$weakArea weak areas',
                style: GoogleFonts.sourceCodePro(
                  color: txtSec,
                  fontSize: 10,
                ),
              ),
              Text(
                '${(improvementRate * 100).toInt()}% improvement',
                style: GoogleFonts.sourceCodePro(
                  color: improvementRate > 0
                      ? SiklabColors.success
                      : SiklabColors.error,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build practice recommendations section
  Widget _buildPracticeRecommendationsSection(
      Color bgCard, Color border, Color txtPri, Color txtSec) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center,
                  color: SiklabColors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                'Practice Recommendations',
                style: GoogleFonts.spaceGrotesk(
                  color: txtPri,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_practiceRecommendations.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No practice recommendations available yet. Complete a challenge to receive tailored practice paths.',
                style: GoogleFonts.sourceCodePro(
                  color: txtSec,
                  fontSize: 12,
                ),
              ),
            )
          else
            ..._practiceRecommendations.map((recommendation) =>
                _buildRecommendationCard(
                    recommendation, txtSec, border, txtPri)),
        ],
      ),
    );
  }

  // Build recommendation card
  Widget _buildRecommendationCard(Map<String, dynamic> recommendation,
      Color txtSec, Color border, Color txtPri) {
    final language = recommendation['language'] as String;
    final topic = recommendation['topic'] as String;
    final currentMastery = recommendation['currentMastery'] as double;
    final targetMastery = recommendation['targetMastery'] as double;
    final sessions = recommendation['estimatedSessions'] as int;
    final priority = recommendation['priority'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.clBgElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$language: $topic',
                  style: GoogleFonts.spaceGrotesk(
                    color: txtSec,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPriorityColor(priority).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  priority,
                  style: GoogleFonts.sourceCodePro(
                    color: _getPriorityColor(priority),
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current: ${(currentMastery * 100).toInt()}%',
                      style: GoogleFonts.sourceCodePro(
                        color: txtSec,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      'Target: ${(targetMastery * 100).toInt()}%',
                      style: GoogleFonts.sourceCodePro(
                        color: SiklabColors.success,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$sessions sessions',
                    style: GoogleFonts.sourceCodePro(
                      color: txtSec,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    recommendation['difficulty'],
                    style: GoogleFonts.sourceCodePro(
                      color: txtSec,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Get severity color
  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Critical':
        return SiklabColors.error;
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return SiklabColors.cyan;
      default:
        return SiklabColors.cyan;
    }
  }

  // Get priority color
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return SiklabColors.error;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return SiklabColors.success;
      default:
        return SiklabColors.cyan;
    }
  }
}
