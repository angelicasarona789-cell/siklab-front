// Analytics Screen - Properly Labeled with Programming Languages
// Last updated: FINAL FIX - May 7, 2026 10:00pm - Ensured labels persist
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../models/user_session.dart';
import '../services/api_service.dart';
import 'audit_screen.dart';
import 'recommendations_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _session = UserSession();
  bool _loading = true;
  bool _fetching = false;
  String? _error;

  List<_TopicMastery> _mastery = [];
  List<String> _weakAreas = [];
  List<_Milestone> _milestones = [];
  String _skillLevel = 'Beginner';
  List<double> _velocityData = [];
  List<String> _velocityLabels = [];
  List<int> _velocityCounts = [];
  int _recoVersion = 0; // bumped on refresh → recommendations reload

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();

    // Listen to user session changes for real-time updates
    _session.addListener(_onUserSessionChanged);
  }

  @override
  void dispose() {
    _session.removeListener(_onUserSessionChanged);
    super.dispose();
  }

  // Handle real-time updates when user data changes
  void _onUserSessionChanged() {
    if (mounted && !_fetching) {
      debugPrint(
          'AnalyticsScreen: User session changed, updating analytics...');
      _refreshAnalytics();
    }
  }

  // Refresh analytics when user data changes (no backend call)
  void _refreshAnalytics() {
    debugPrint(
        'AnalyticsScreen: Refreshing analytics with latest user data...');

    // Only regenerate local data - no backend call needed for user progress changes
    _generateAllLocalData();

    // Update UI
    if (mounted) {
      setState(() => _recoVersion++);
    }

    debugPrint('AnalyticsScreen: Analytics refreshed successfully');
  }

  Future<void> _fetchAnalytics() async {
    if (_session.dbId == 0) {
      setState(() {
        _loading = false;
        _error = 'No linked account found. Please log in to load analytics.';
      });
      return;
    }

    setState(() => _fetching = true);
    await ApiService.loadLanguageProgress();
    if (!mounted) return;

    // Force use local data immediately for 100% functionality
    debugPrint(
        'AnalyticsScreen: Using local data generation for immediate results');
    _generateAllLocalData();

    // Try backend in background but don't wait for it
    ApiService.getAnalytics(_session.dbId).then((result) {
      if (mounted && result.success && result.data != null) {
        debugPrint('AnalyticsScreen: Backend data available, updating...');
        _parseAnalyticsData(result.data!);
      }
    }).catchError((e) {
      debugPrint(
          'AnalyticsScreen: Backend failed, continuing with local data: $e');
    });
    unawaited(_refreshProgressFromProfile(_session.dbId));

    if (mounted) {
      setState(() {
        _fetching = false;
        _loading = false;
        _error = null; // Clear any error
        _recoVersion++;
      });
    }
  }

  Future<void> _refreshProgressFromProfile(int userId) async {
    final result = await ApiService.getProfile(userId);
    if (!result.success) return;
    await ApiService.loadLanguageProgress();
    if (!mounted) return;
    _generateAllLocalData();
    setState(() => _recoVersion++);
  }

  // Generate all analytics data from local sources
  bool get _isNewUser {
    return _session.dbId == 0 ||
        !_session.languageProgress.values.any((progress) => progress > 0);
  }

  void _generateAllLocalData() {
    debugPrint('AnalyticsScreen: Generating local analytics data...');

    if (_isNewUser) {
      debugPrint(
          'AnalyticsScreen: New user detected, generating zeroed analytics');
      _generateTopicMasteryFromLocalData();
      _generateWeakAreasFromLocalData();
      _generateMilestonesFromLocalData();
      _calculateSkillLevel();
    } else {
      // Generate topic mastery
      _generateTopicMasteryFromLocalData();

      // Generate weak areas
      _generateWeakAreasFromLocalData();

      // Generate milestones
      _generateMilestonesFromLocalData();

      // Calculate skill level
      _calculateSkillLevel();
    }
    _loadCodingVelocityData();

    debugPrint('AnalyticsScreen: Local data generation complete');
    debugPrint('AnalyticsScreen: Topic mastery items: ${_mastery.length}');
    debugPrint('AnalyticsScreen: Weak areas: ${_weakAreas.length}');
    debugPrint('AnalyticsScreen: Milestones: ${_milestones.length}');
    debugPrint('AnalyticsScreen: Skill level: $_skillLevel');
  }

  void _parseAnalyticsData(Map<String, dynamic> data) {
    debugPrint('AnalyticsScreen: Parsing backend data...');

    // ALWAYS use local data for proper labels - ignore backend for labels
    _generateAllLocalData();

    if (_isNewUser) {
      debugPrint('AnalyticsScreen: New user - ignoring backend analytics data');
    }

    // Update UI only if data actually changed
    if (mounted) {
      setState(() {});
    }

    debugPrint('AnalyticsScreen: Data parsing complete - using local labels');
  }

  // Generate topic mastery from local language progress
  void _generateTopicMasteryFromLocalData() {
    if (_isNewUser) {
      _mastery = [];
      return;
    }
    _mastery = [];

    final languages = {
      'Java': {
        'color': SiklabColors.orange,
        'topics': [
          'Core Java Syntax',
          'Object-Oriented Programming',
          'Java Collections Framework',
          'Exception Handling',
          'Multithreading Concepts',
        ],
      },
      'Python': {
        'color': SiklabColors.purple,
        'topics': [
          'Python Syntax Basics',
          'Data Structures',
          'Functions & Modules',
          'File Operations',
          'Error Handling',
        ],
      },
      'C#': {
        'color': SiklabColors.success,
        'topics': [
          'C# Fundamentals',
          '.NET Framework',
          'LINQ Operations',
          'Event Programming',
          'Async Programming',
        ],
      },
      'JavaScript': {
        'color': SiklabColors.cyan,
        'topics': [
          'JavaScript Core',
          'DOM Manipulation',
          'Async Patterns',
          'ES6+ Features',
          'Module Systems',
        ],
      },
      'SQL': {
        'color': SiklabColors.error,
        'topics': [
          'SQL Fundamentals',
          'Query Optimization',
          'Database Design',
          'Advanced Joins',
          'Window Functions',
        ],
      },
    };

    for (final entry in languages.entries) {
      final language = entry.key;
      final languageData = entry.value;
      final progress = _session.getLanguageProgress(language);

      // Always generate topics, even with 0% progress for new users
      final topicCount =
          (progress * 5).ceil().clamp(1, 5); // 1-5 topics based on progress
      final topics = languageData['topics'] as List<String>;

      for (int i = 0; i < topicCount && i < topics.length; i++) {
        final topicProgress =
            progress * (1.0 - (i * 0.15)); // Decreasing progress for sub-topics
        _mastery.add(_TopicMastery(
          '$language: ${topics[i]}',
          topicProgress.clamp(0.0, 1.0),
          languageData['color'] as Color,
        ));
      }
    }

    // Sort by progress (highest first) and take top 8
    _mastery.sort((a, b) => b.value.compareTo(a.value));
    _mastery = _mastery.take(8).toList();
  }

  // Generate weak areas based on language progress
  void _generateWeakAreasFromLocalData() {
    if (_isNewUser) {
      _weakAreas = [];
      return;
    }
    _weakAreas = [];

    final languages = ['Java', 'Python', 'C#', 'JavaScript', 'SQL'];
    for (final language in languages) {
      final progress = _session.getLanguageProgress(language);
      if (progress < 0.5) {
        _weakAreas.add(
            '$language - Needs Practice (${(progress * 100).toInt()}% mastery)');
      }
    }

    // Add specific weak areas based on low progress
    if (_weakAreas.isEmpty) {
      _weakAreas = [
        'Python - Data Structures (${(_session.getLanguageProgress('Python') * 100).toInt()}%)',
        'JavaScript - Async Programming (${(_session.getLanguageProgress('JavaScript') * 100).toInt()}%)',
        'SQL - Complex Queries (${(_session.getLanguageProgress('SQL') * 100).toInt()}%)',
      ];
    }
  }

  // Generate milestones based on user achievements
  void _generateMilestonesFromLocalData() {
    if (_isNewUser) {
      _milestones = [];
      return;
    }
    _milestones = [];
    final totalProgress = ['Java', 'Python', 'C#', 'JavaScript', 'SQL']
        .map((lang) => _session.getLanguageProgress(lang))
        .reduce((a, b) => a + b);

    // Milestone 1: First language progress
    if (totalProgress > 0) {
      _milestones.add(const _Milestone(
        Icons.emoji_events_outlined,
        'First Steps',
        'Started learning programming languages',
        SiklabColors.orange,
      ));
    }

    // Milestone 2: Multiple languages
    final languagesWithProgress = ['Java', 'Python', 'C#', 'JavaScript', 'SQL']
        .where((lang) => _session.getLanguageProgress(lang) > 0)
        .length;

    if (languagesWithProgress >= 2) {
      _milestones.add(_Milestone(
        Icons.explore,
        'Multi-Language Learner',
        'Progress in $languagesWithProgress programming languages',
        SiklabColors.cyan,
      ));
    }

    // Milestone 3: Significant progress
    if (totalProgress >= 0.5) {
      _milestones.add(const _Milestone(
        Icons.trending_up,
        'Half Way There',
        'Achieved 50% overall progress',
        SiklabColors.purple,
      ));
    }

    // Milestone 4: High progress in a language
    final hasHighProgress = ['Java', 'Python', 'C#', 'JavaScript', 'SQL']
        .any((lang) => _session.getLanguageProgress(lang) >= 0.8);

    if (hasHighProgress) {
      _milestones.add(const _Milestone(
        Icons.military_tech,
        'Language Mastery',
        'Achieved 80%+ progress in a language',
        SiklabColors.success,
      ));
    }

    // Default milestone if no progress
    if (_milestones.isEmpty) {
      _milestones.add(const _Milestone(
        Icons.lightbulb,
        'Getting Started',
        'Ready to begin your coding journey',
        SiklabColors.orange,
      ));
    }
  }

  // Calculate skill level from the mastery values shown in Core Topic Mastery.
  void _calculateSkillLevel() {
    _skillLevel = _session.skillLevel;
  }

  Color _languageColor(String language) {
    switch (language) {
      case 'Java':
        return SiklabColors.orange;
      case 'Python':
        return SiklabColors.cyan;
      case 'C#':
        return SiklabColors.purple;
      case 'JavaScript':
        return SiklabColors.success;
      default:
        return SiklabColors.error;
    }
  }

  Future<void> _loadCodingVelocityData() async {
    final userId = _session.dbId;
    try {
      final counts = await ApiService.getCodingVelocityByDay(userId);
      if (!mounted || _session.dbId != userId) return;

      final maxCount =
          counts.fold<int>(0, (max, count) => count > max ? count : max);
      final now = DateTime.now();
      setState(() {
        _velocityCounts = counts;
        _velocityData = counts
            .map((count) => maxCount == 0 ? 0.0 : count / maxCount)
            .toList();
        _velocityLabels = List<String>.generate(7, (index) {
          final day = now.subtract(Duration(days: 6 - index));
          return _weekdayAbbreviation(day);
        });
      });
    } catch (error, stackTrace) {
      debugPrint('AnalyticsScreen: Failed to load coding velocity: $error');
      debugPrint('$stackTrace');
    }
  }

  String _weekdayAbbreviation(DateTime day) {
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return weekdays[day.weekday - 1];
  }

  // ignore: unused_element
  Color _parseColor(String? colorStr) {
    if (colorStr == null) return SiklabColors.cyan;
    switch (colorStr.toLowerCase()) {
      case 'cyan':
        return SiklabColors.cyan;
      case 'purple':
        return SiklabColors.purple;
      case 'orange':
        return SiklabColors.orange;
      case 'success':
        return SiklabColors.success;
      case 'pink':
        return SiklabColors.pink;
      default:
        return SiklabColors.cyan;
    }
  }

  // ignore: unused_element
  IconData _parseIcon(String? iconStr) {
    if (iconStr == null) return Icons.star;
    switch (iconStr.toLowerCase()) {
      case 'all_inclusive':
        return Icons.all_inclusive;
      case 'bolt':
        return Icons.bolt;
      case 'emoji_events':
        return Icons.emoji_events_outlined;
      case 'star':
        return Icons.star;
      case 'military_tech':
        return Icons.military_tech;
      default:
        return Icons.star;
    }
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

    if (_error != null) {
      return Scaffold(
        backgroundColor: context.clBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                color: context.clTextSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    final bg = context.clBg;
    final bgCard = context.clBgCard;
    final bgElev = context.clBgElevated;
    final border = context.clBorder;
    final txtPri = context.clTextPrimary;
    final txtSec = context.clTextSecondary; // ignore: unused_local_variable`n
    final txtMut = context.clTextMuted; // ignore: unused_local_variable
    const velocityLabelDescription = 'Coding attempts over the last 7 days';

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(
                'LEARNING ANALYTICS DASHBOARD',
                style: GoogleFonts.sourceCodePro(
                  color: SiklabColors.success,
                  fontSize: 10,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Performance\nAnalytics',
                style: GoogleFonts.spaceGrotesk(
                  color: txtPri,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events_outlined,
                        color: SiklabColors.orange, size: 18),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SKILL LEVEL',
                          style: GoogleFonts.sourceCodePro(
                            color: txtSec,
                            fontSize: 10,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          _skillLevel,
                          style: GoogleFonts.sourceCodePro(
                            color: txtPri,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LANGUAGE PROGRESS',
                      style: GoogleFonts.spaceGrotesk(
                        color: txtPri,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...const ['Java', 'Python', 'C#', 'JavaScript', 'SQL']
                        .map((language) {
                      final progress = _session
                          .getLanguageProgress(language)
                          .clamp(0.0, 1.0)
                          .toDouble();
                      final color = _languageColor(language);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    language,
                                    style: GoogleFonts.sourceCodePro(
                                      color: txtSec,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${_session.getLanguageProgressPercent(language)}%',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: txtPri,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: border,
                                valueColor: AlwaysStoppedAnimation(color),
                                minHeight: 4,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
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
                        const Icon(Icons.bar_chart,
                            color: SiklabColors.cyan, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Core Topic Mastery',
                          style: GoogleFonts.spaceGrotesk(
                            color: txtPri,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_mastery.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No mastery data yet. Start a lesson to generate personalized insights.',
                          style: GoogleFonts.sourceCodePro(
                            color: txtSec,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      ..._mastery.map((m) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        m.topic,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.sourceCodePro(
                                          color: txtSec,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${(m.value * 100).toInt()}%',
                                      style: GoogleFonts.spaceGrotesk(
                                        color: txtPri,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: m.value,
                                    backgroundColor: border,
                                    valueColor: AlwaysStoppedAnimation(m.color),
                                    minHeight: 4,
                                  ),
                                ),
                              ],
                            ),
                          )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Weak Areas',
                              style: GoogleFonts.spaceGrotesk(
                                color: txtPri,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Topics needing improvement',
                              style: GoogleFonts.sourceCodePro(
                                color: txtSec,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: SiklabColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color:
                                    SiklabColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      SiklabColors.error,
                                      SiklabColors.orange
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_weakAreas.length} Areas',
                                style: GoogleFonts.sourceCodePro(
                                  color: SiklabColors.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: bgElev.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _weakAreas.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'No weak area analysis yet. Complete a challenge to see personal recommendations.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.sourceCodePro(
                                    color: txtSec,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              children: _weakAreas.asMap().entries.map((entry) {
                                final index = entry.key;
                                final weakArea = entry.value;
                                return _OptimizedWeakAreaCard(
                                  weakArea: weakArea,
                                  index: index,
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              SiklabColors.orange.withValues(alpha: 0.1),
                              SiklabColors.error.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: SiklabColors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const AuditScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.analytics_outlined,
                            color: SiklabColors.orange,
                            size: 18,
                          ),
                          label: Text(
                            'View Performance Audit Report',
                            style: GoogleFonts.spaceGrotesk(
                              color: txtSec,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              RecommendationsSummaryCard(version: _recoVersion),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Coding Velocity',
                              style: GoogleFonts.spaceGrotesk(
                                color: txtPri,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              velocityLabelDescription,
                              style: GoogleFonts.sourceCodePro(
                                color: txtSec,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: bgElev,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      SiklabColors.cyan,
                                      SiklabColors.purple
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Live',
                                style: GoogleFonts.sourceCodePro(
                                  color: txtPri,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 200,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: bgElev.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _VelocityChart(
                        values: _velocityData,
                        labels: _velocityLabels,
                        counts: _velocityCounts,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bgElev.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildLegendItem('Low', SiklabColors.error),
                          _buildLegendItem('Medium', SiklabColors.orange),
                          _buildLegendItem('Good', SiklabColors.success),
                          _buildLegendItem('High', SiklabColors.cyan),
                          _buildLegendItem('Peak', SiklabColors.purple),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent Milestones',
                              style: GoogleFonts.spaceGrotesk(
                                color: txtPri,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your achievements so far',
                              style: GoogleFonts.sourceCodePro(
                                color: txtSec,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: bgElev,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      SiklabColors.success,
                                      SiklabColors.cyan
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_milestones.length} Earned',
                                style: GoogleFonts.sourceCodePro(
                                  color: txtPri,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: bgElev.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _milestones.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'No milestones yet. Finish your first learning activity to earn achievements.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.sourceCodePro(
                                    color: txtSec,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              children:
                                  _milestones.asMap().entries.map((entry) {
                                final index = entry.key;
                                final milestone = entry.value;
                                return _OptimizedMilestoneCard(
                                  milestone: milestone,
                                  index: index,
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _dot(Color c) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );

  Widget _buildLegendItem(String label, Color color) {
    return Builder(
      builder: (context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color,
                  color.withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.sourceCodePro(
              color: context.clTextSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _VelocityChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final List<int> counts;

  const _VelocityChart({
    required this.values,
    required this.labels,
    required this.counts,
  });

  Color _getBarColor(double value) {
    if (value >= 0.8) return SiklabColors.cyan;
    if (value >= 0.6) return SiklabColors.success;
    if (value >= 0.4) return SiklabColors.orange;
    return SiklabColors.pink;
  }

  @override
  Widget build(BuildContext context) {
    final bg = context.clBg;
    final txtSec = context.clTextSecondary; // ignore: unused_local_variable`n
    final txtMut = context.clTextMuted; // ignore: unused_local_variable

    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.asMap().entries.map((entry) {
          final index = entry.key;
          final value = entry.value;
          final count = index < counts.length ? counts[index] : 0;
          final color = _getBarColor(value);
          final label = index < labels.length ? labels[index] : 'Day';

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$count',
                style: GoogleFonts.sourceCodePro(
                  color: context.clTextSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 125 * value,
                width: 32,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.sourceCodePro(
                  color: txtSec,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _TopicMastery {
  final String topic;
  final double value;
  final Color color;
  const _TopicMastery(this.topic, this.value, this.color);
}

class _Milestone {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  const _Milestone(this.icon, this.title, this.desc, this.color);
}

class _OptimizedMilestoneCard extends StatelessWidget {
  final _Milestone milestone;
  final int index;

  const _OptimizedMilestoneCard({
    required this.milestone,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final bgCard = context.clBgCard;
    final txtPri = context.clTextPrimary;
    final txtSec = context.clTextSecondary; // ignore: unused_local_variable`n
    final txtMut = context.clTextMuted; // ignore: unused_local_variable
    final border = context.clBorder;

    final iconColor = index == 0
        ? SiklabColors.cyan
        : index == 1
            ? SiklabColors.orange
            : index == 2
                ? SiklabColors.purple
                : SiklabColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 4, right: 4, top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              milestone.icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title,
                  style: GoogleFonts.spaceGrotesk(
                    color: txtPri,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  milestone.desc,
                  style: GoogleFonts.sourceCodePro(
                    color: txtSec,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: txtMut,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _InteractiveMilestoneCard extends StatefulWidget {
  final _Milestone milestone;
  final int index;
  final int totalMilestones;

  const _InteractiveMilestoneCard({
    required this.milestone,
    required this.index,
    required this.totalMilestones,
  });

  @override
  State<_InteractiveMilestoneCard> createState() =>
      _InteractiveMilestoneCardState();
}

class _OptimizedWeakAreaCard extends StatelessWidget {
  final String weakArea;
  final int index;

  const _OptimizedWeakAreaCard({
    required this.weakArea,
    required this.index,
  });

  Color _getWeakAreaColor(String weakArea) {
    if (weakArea.toLowerCase().contains('python')) return SiklabColors.purple;
    if (weakArea.toLowerCase().contains('java')) return SiklabColors.cyan;
    if (weakArea.toLowerCase().contains('javascript')) {
      return SiklabColors.orange;
    }
    if (weakArea.toLowerCase().contains('c#')) return SiklabColors.success;
    if (weakArea.toLowerCase().contains('sql')) return SiklabColors.pink;
    return SiklabColors.error;
  }

  double _extractProgress(String weakArea) {
    final regex = RegExp(r'(\d+)%');
    final match = regex.firstMatch(weakArea);
    if (match != null) {
      return int.parse(match.group(1)!) / 100.0;
    }
    return 0.3;
  }

  String _extractTopic(String weakArea) {
    return weakArea.split(' - ').first;
  }

  String _extractDescription(String weakArea) {
    final parts = weakArea.split(' - ');
    if (parts.length > 1) {
      return parts.sublist(1).join(' - ');
    }
    return 'Needs improvement';
  }

  @override
  Widget build(BuildContext context) {
    final bgCard = context.clBgCard;
    final txtPri = context.clTextPrimary;
    final txtSec = context.clTextSecondary; // ignore: unused_local_variable`n
    final txtMut = context.clTextMuted; // ignore: unused_local_variable
    final border = context.clBorder;

    final weakAreaColor = _getWeakAreaColor(weakArea);
    final progress = _extractProgress(weakArea);
    final topic = _extractTopic(weakArea);
    final description = _extractDescription(weakArea);

    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 4, right: 4, top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: weakAreaColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.trending_down,
                  color: weakAreaColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic,
                      style: GoogleFonts.spaceGrotesk(
                        color: txtPri,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: GoogleFonts.sourceCodePro(
                        color: txtSec,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: weakAreaColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: GoogleFonts.spaceGrotesk(
                    color: weakAreaColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: border.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: weakAreaColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveMilestoneCardState extends State<_InteractiveMilestoneCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300 + (widget.index * 100)),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    // Start animation after a delay based on index
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = widget.index == widget.totalMilestones - 1;
    final bg = context.clBg;
    final bgCard = context.clBgCard;
    final txtPri = context.clTextPrimary;
    final txtMut = context.clTextMuted; // ignore: unused_local_variable
    final border = context.clBorder;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: () {
              // Add haptic feedback or navigation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Milestone: ${widget.milestone.title}',
                    style: GoogleFonts.sourceCodePro(),
                  ),
                  backgroundColor: widget.milestone.color,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                bottom: isLast ? 0 : 8,
                left: 4,
                right: 4,
                top: 4,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isHovered
                    ? widget.milestone.color.withValues(alpha: 0.1)
                    : bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isHovered
                      ? widget.milestone.color.withValues(alpha: 0.3)
                      : border,
                  width: _isHovered ? 2 : 1,
                ),
                boxShadow: [
                  if (_isHovered)
                    BoxShadow(
                      color: widget.milestone.color.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              transform: Matrix4.diagonal3Values(_scaleAnimation.value,
                  _scaleAnimation.value, _scaleAnimation.value),
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Row(
                  children: [
                    // Enhanced icon with gradient and animation
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.milestone.color.withValues(alpha: 0.2),
                            widget.milestone.color.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.milestone.color.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                widget.milestone.color.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.milestone.icon,
                        color: widget.milestone.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Enhanced text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.milestone.title,
                            style: GoogleFonts.spaceGrotesk(
                              color: txtPri,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.milestone.desc,
                            style: GoogleFonts.sourceCodePro(
                              color: txtMut,
                              fontSize: 12,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Progress indicator
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _isHovered ? 1.0 : 0.7,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      widget.milestone.color,
                                      widget.milestone.color
                                          .withValues(alpha: 0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Interactive arrow icon
                    AnimatedRotation(
                      turns: _isHovered ? 0.25 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: _isHovered ? widget.milestone.color : txtMut,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
