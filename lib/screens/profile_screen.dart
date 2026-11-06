// lib/screens/profile_screen.dart
// Replace your existing file entirely with this one.
// Change: initState calls GET /profile/<dbId> to always show live DB data.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../models/user_session.dart';
import '../services/api_service.dart';
import 'settings_screen.dart';
import 'feedback_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _session = UserSession();
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSessionChanged);
    // Load once when the tab is first opened; the refresh button stays
    // available for users who want to request newer server data.
    _fetchProfile();
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _fetchProfile() async {
    if (_session.dbId == 0) return; // not logged in yet
    final userId = _session.dbId;
    setState(() => _fetching = true);
    await ApiService.loadLanguageProgress();

    if (mounted) {
      setState(() {
        _fetching = false;
      });
    }

    unawaited(_refreshBackendProfile(userId));
  }

  Future<void> _refreshBackendProfile(int userId) async {
    final result = await ApiService.getProfile(userId);
    if (!result.success) {
      debugPrint(
          'ProfileScreen: Using saved local progress: ${result.message}');
      return;
    }
    await ApiService.loadLanguageProgress();
    if (!mounted) return;
    _generateRealTimeData();
    setState(() {});
  }

  // Generate real-time data from UserSession
  void _generateRealTimeData() {
    debugPrint('ProfileScreen: Generating real-time data...');
    debugPrint('ProfileScreen: Logic Cycles: ${_session.totalLogicCycles}');
    debugPrint('ProfileScreen: Streak: ${_session.currentStreak}');
    debugPrint('ProfileScreen: Precision: ${_session.avgPrecisionLabel}');
    debugPrint('ProfileScreen: XP: ${_session.xpPoints}');
    debugPrint('ProfileScreen: Completed: ${_session.completedChallenges}');
    debugPrint(
        'ProfileScreen: Languages with progress: ${_getLanguagesWithProgress()}');
  }

  // Get count of languages with progress
  int _getLanguagesWithProgress() {
    return _session.languageProgress.entries
        .where((entry) => entry.value > 0)
        .length;
  }

  // Get total progress across all languages
  // ignore: unused_element
  double _getTotalProgress() {
    return _session.languageProgress.values.reduce((a, b) => a + b);
  }

  @override
  Widget build(BuildContext context) {
    final bg = context.clBg;
    final bgCard = context.clBgCard;
    final border = context.clBorder;
    final txtSec = context.clTextSecondary;

    const Color textLight = Color(0xFFE8E8F0);
    const Color textMid = Color(0xFFAAAAAC);
    const Color textDim = Color(0xFF6B6B80);

    final isNewUser = _session.dbId == 0 ||
        !_session.languageProgress.values.any((p) => p > 0);
    final currentStreak = isNewUser ? 0 : _session.currentStreak;
    final xpLabel = isNewUser ? '0' : _session.xpLabel;
    final completedChallenges = isNewUser ? 0 : _session.exerciseCompletedCount;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                // ── Top bar ─────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            SiklabBackButton(),
                            SizedBox(width: 8),
                            SiklabLogo(),
                          ],
                        ),
                        Row(
                          children: [
                            // Refresh button
                            GestureDetector(
                              onTap: () {
                                _fetchProfile();
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color: bgCard,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: border),
                                ),
                                child: const Icon(Icons.refresh,
                                    color: textMid, size: 18),
                              ),
                            ),
                            const SiklabHamburgerMenu(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Avatar + name ────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 160,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Align(
                                alignment: Alignment.topCenter,
                                child: Stack(
                                  children: [
                                    // Main avatar container
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          colors: [
                                            SiklabColors.cyan,
                                            SiklabColors.purple
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: SiklabColors.cyan
                                                .withValues(alpha: 0.3),
                                            blurRadius: 15,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: bgCard,
                                          ),
                                          child: const Icon(Icons.person,
                                              color: textMid, size: 50),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: bgCard,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: border),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.workspace_premium,
                                            color: SiklabColors.purple,
                                            size: 18),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                              _session.skillLevel.toUpperCase(),
                                              style: GoogleFonts.sourceCodePro(
                                                color: textLight,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        // ── Real name from DB ──────────────
                        Text(
                          _session.displayName,
                          style: GoogleFonts.spaceGrotesk(
                              color: textLight,
                              fontSize: 24,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text('// User ID: ${_session.userId}',
                            style: GoogleFonts.sourceCodePro(
                                color: textDim, fontSize: 12)),
                        if (_session.email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(_session.email,
                              style: GoogleFonts.sourceCodePro(
                                  color: textDim, fontSize: 11)),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // ── Current Streak ─────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color:
                                  SiklabColors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.local_fire_department,
                                color: SiklabColors.orange, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  const Icon(Icons.local_fire_department,
                                      color: SiklabColors.orange, size: 11),
                                  const SizedBox(width: 4),
                                  Text('CURRENT STREAK',
                                      style: GoogleFonts.sourceCodePro(
                                          color: textDim,
                                          fontSize: 9,
                                          letterSpacing: 1.5)),
                                ]),
                                const SizedBox(height: 6),
                                Text('$currentStreak days',
                                    style: GoogleFonts.spaceGrotesk(
                                        color: textLight,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 3),
                                Text('keep it going!',
                                    style: GoogleFonts.sourceCodePro(
                                        color: textDim, fontSize: 9)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ── Language Progress Overview ─────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
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
                              const Icon(Icons.code,
                                  color: SiklabColors.cyan, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'LANGUAGE PROGRESS',
                                style: GoogleFonts.spaceGrotesk(
                                  color: textLight,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${_getLanguagesWithProgress()}/5 languages',
                                style: GoogleFonts.sourceCodePro(
                                  color: textDim,
                                  fontSize: 10,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ..._session.languageProgress.entries.map((entry) {
                            final progress = entry.value;
                            final color = _getLanguageColor(entry.key);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          entry.key,
                                          style: GoogleFonts.sourceCodePro(
                                            color: textMid,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '${_session.getLanguageProgressPercent(entry.key)}%',
                                        style: GoogleFonts.spaceGrotesk(
                                          color: textLight,
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
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ── Row 2: XP + Completed ────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: bgCard,
                              border: Border(
                                left: const BorderSide(
                                    color: SiklabColors.success, width: 3),
                                right: BorderSide(color: border),
                                top: BorderSide(color: border),
                                bottom: BorderSide(color: border),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  const Icon(Icons.star_outline,
                                      color: SiklabColors.success, size: 11),
                                  const SizedBox(width: 4),
                                  Text('XP POINTS',
                                      style: GoogleFonts.sourceCodePro(
                                          color: textDim,
                                          fontSize: 9,
                                          letterSpacing: 1.5)),
                                ]),
                                const SizedBox(height: 6),
                                Text(xpLabel,
                                    style: GoogleFonts.spaceGrotesk(
                                        color: textLight,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 3),
                                Text('experience pts',
                                    style: GoogleFonts.sourceCodePro(
                                        color: textDim, fontSize: 9)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: bgCard,
                              border: Border(
                                left: const BorderSide(
                                    color: SiklabColors.orange, width: 3),
                                right: BorderSide(color: border),
                                top: BorderSide(color: border),
                                bottom: BorderSide(color: border),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  const Icon(Icons.check_circle_outline,
                                      color: SiklabColors.orange, size: 11),
                                  const SizedBox(width: 4),
                                  Text('COMPLETED',
                                      style: GoogleFonts.sourceCodePro(
                                          color: textDim,
                                          fontSize: 9,
                                          letterSpacing: 1.5)),
                                ]),
                                const SizedBox(height: 6),
                                Text('$completedChallenges',
                                    style: GoogleFonts.spaceGrotesk(
                                        color: textLight,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 3),
                                Text('challenges done',
                                    style: GoogleFonts.sourceCodePro(
                                        color: textDim, fontSize: 9)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── Topic strengths ──────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                                width: 20,
                                height: 1,
                                color: SiklabColors.success),
                            const SizedBox(width: 8),
                            Text('TOPIC STRENGTHS',
                                style: GoogleFonts.sourceCodePro(
                                    color: textDim,
                                    fontSize: 10,
                                    letterSpacing: 1.5)),
                            const SizedBox(width: 8),
                            Container(
                                width: 20,
                                height: 1,
                                color: SiklabColors.success),
                          ]),
                          const SizedBox(height: 16),
                          ..._getTopicStrengthBars(textMid, border),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── Feedback ───────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FeedbackScreen(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.feedback_outlined,
                              color: SiklabColors.cyan,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'FEEDBACK',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: textLight,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Text(
                                    'Share your thoughts with the admin team',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: textDim,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: txtSec, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ── Settings ─────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.settings_outlined,
                                color: textMid, size: 20),
                            const SizedBox(width: 10),
                            Text('SETTINGS',
                                style: GoogleFonts.spaceGrotesk(
                                    color: textMid,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),

            // ── Thin loading bar at top while fetching ───────
            if (_fetching)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  color: SiklabColors.cyan,
                  backgroundColor: Colors.transparent,
                  minHeight: 2,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _strengthBar(
      String label, double value, Color color, Color textMid, Color border) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.spaceGrotesk(color: textMid, fontSize: 14)),
            Text('${(value * 100).toInt()}%',
                style: GoogleFonts.sourceCodePro(color: textMid, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: border,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  List<Widget> _getTopicStrengthBars(Color textMid, Color border) {
    // Generate real topic strengths based on actual language progress
    final realTopicStrengths = _generateRealTopicStrengths();

    return realTopicStrengths.map((entry) {
      final topic = entry['topic'] as String;
      final value = entry['value'] as double;
      final color = entry['color'] as Color;
      return Column(
        children: [
          _strengthBar(topic, value, color, textMid, border),
          const SizedBox(height: 12),
        ],
      );
    }).toList();
  }

  // Generate real topic strengths based on actual language progress
  List<Map<String, dynamic>> _generateRealTopicStrengths() {
    final strengths = <Map<String, dynamic>>[];

    // Generate topic strengths based on language progress
    _session.languageProgress.forEach((language, progress) {
      if (progress > 0) {
        // Create specific topics for each language based on progress
        strengths.addAll(_getLanguageSpecificTopics(language, progress));
      }
    });

    // Sort by strength (highest first)
    strengths
        .sort((a, b) => (b['value'] as double).compareTo(a['value'] as double));

    // Return top 5 topics
    return strengths.take(5).toList();
  }

  // Get language-specific topics based on progress (only for users with progress)
  List<Map<String, dynamic>> _getLanguageSpecificTopics(
      String language, double progress) {
    final topics = <Map<String, dynamic>>[];
    final color = _getLanguageColor(language);

    // Only generate topics if there is actual progress
    if (progress <= 0) {
      return topics;
    }

    switch (language) {
      case 'Java':
        topics.addAll([
          {
            'topic': 'Java: Core Java Syntax',
            'value': progress * 0.9,
            'color': color
          },
          {
            'topic': 'Java: Object-Oriented Programming',
            'value': progress * 0.8,
            'color': color
          },
          {
            'topic': 'Java: Java Collections Framework',
            'value': progress * 0.7,
            'color': color
          },
        ]);
        break;
      case 'Python':
        topics.addAll([
          {
            'topic': 'Python: Python Syntax Basics',
            'value': progress * 0.95,
            'color': color
          },
          {
            'topic': 'Python: Data Structures',
            'value': progress * 0.85,
            'color': color
          },
          {
            'topic': 'Python: Functions & Modules',
            'value': progress * 0.75,
            'color': color
          },
        ]);
        break;
      case 'C#':
        topics.addAll([
          {
            'topic': 'C#: C# Fundamentals',
            'value': progress * 0.9,
            'color': color
          },
          {
            'topic': 'C#: .NET Framework',
            'value': progress * 0.8,
            'color': color
          },
          {
            'topic': 'C#: LINQ Operations',
            'value': progress * 0.7,
            'color': color
          },
        ]);
        break;
      case 'JavaScript':
        topics.addAll([
          {
            'topic': 'JavaScript: JavaScript Core',
            'value': progress * 0.9,
            'color': color
          },
          {
            'topic': 'JavaScript: DOM Manipulation',
            'value': progress * 0.8,
            'color': color
          },
          {
            'topic': 'JavaScript: Async Patterns',
            'value': progress * 0.7,
            'color': color
          },
        ]);
        break;
      case 'SQL':
        topics.addAll([
          {
            'topic': 'SQL: SQL Fundamentals',
            'value': progress * 0.9,
            'color': color
          },
          {
            'topic': 'SQL: Query Optimization',
            'value': progress * 0.8,
            'color': color
          },
          {
            'topic': 'SQL: Database Design',
            'value': progress * 0.7,
            'color': color
          },
        ]);
        break;
    }

    return topics;
  }

  // ignore: unused_element
  Color _getTopicColor(String topic) {
    final lower = topic.toLowerCase();
    if (lower.contains('data') || lower.contains('structure')) {
      return SiklabColors.cyan;
    } else if (lower.contains('algorithm')) {
      return SiklabColors.purple;
    } else if (lower.contains('design') || lower.contains('system')) {
      return SiklabColors.orange;
    } else if (lower.contains('big-o') || lower.contains('complexity')) {
      return SiklabColors.success;
    } else {
      return SiklabColors.cyan;
    }
  }

  Color _getLanguageColor(String language) {
    switch (language) {
      case 'Java':
        return SiklabColors.orange;
      case 'Python':
        return SiklabColors.purple;
      case 'C#':
        return SiklabColors.success;
      case 'JavaScript':
        return SiklabColors.cyan;
      case 'SQL':
        return SiklabColors.error;
      default:
        return SiklabColors.cyan;
    }
  }
}
