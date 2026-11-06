import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../models/user_profile.dart';
import '../models/user_session.dart';
import '../navigation/shell_navigator.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../services/certificate_service.dart';
import 'search_screen.dart';
import 'modules_screen.dart';
import 'certificate_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _activeTimeSaveTimer;
  final _session = UserSession();
  int _lastDbId = 0; // tracks auth state to detect sign-out / sign-in

  final List<_Module> _allModules = const [
    _Module(
        Icons.coffee_outlined,
        'Java',
        'Object-oriented fundamentals, syntax, and debugging challenges.',
        SiklabColors.cyan),
    _Module(
        Icons.code,
        'Python',
        'Readable scripting, logic flow, and practical coding exercises.',
        SiklabColors.purple),
    _Module(
        Icons.terminal,
        'C#',
        '.NET-oriented syntax, methods, and intermediate problem solving.',
        SiklabColors.orange),
    _Module(
        Icons.javascript_outlined,
        'JavaScript',
        'Browser/Node logic, async thinking, and modern JS patterns.',
        SiklabColors.cyan),
    _Module(
        Icons.storage_outlined,
        'SQL',
        'Query building, joins, and relational database reasoning.',
        SiklabColors.success),
  ];

  // ignore: unused_element
  double _getModuleProgress(String language) {
    final progress = _session.getLanguageProgress(language);
    debugPrint(
        'HomeScreen: Getting progress for $language: ${(progress * 100).toInt()}%');
    return progress;
  }

  @override
  void initState() {
    super.initState();

    // Capture initial auth state before any listener fires
    _lastDbId = _session.dbId;

    // Load persisted data first, then start tracking
    _initializeSession();

    _session.addListener(_onSessionChanged);
    _loadSavedProgress();
  }

  Future<void> _startActivityTracking() async {
    await _session.startActivityTracking();

    // Save active time periodically (every 30 seconds)
    _activeTimeSaveTimer ??= Timer.periodic(
      const Duration(seconds: 30),
      (_) => _session.saveActiveTime(),
    );
  }

  @override
  void dispose() {
    _activeTimeSaveTimer?.cancel();
    _session.removeListener(_onSessionChanged);
    _session.stopActivityTracking();
    // Save active time when disposing
    _session.saveActiveTime();
    super.dispose();
  }

  void _onSessionChanged() {
    if (!mounted) return;

    final currentDbId = _session.dbId;
    final previousDbId = _lastDbId;
    _lastDbId = currentDbId;

    // ── User just signed OUT ──────────────────────────────────────────────
    if (previousDbId > 0 && currentDbId == 0) {
      debugPrint(
          'HomeScreen: Sign-out detected — deferring I/O operations to prevent jank');
      _activeTimeSaveTimer?.cancel();
      _activeTimeSaveTimer = null;
      _session.stopActivityTracking();
      // Update the auth transition before clearing so this notification
      // cannot recursively re-enter the sign-out branch.
      _session.clearAll();
    }

    // ── User just signed IN (fresh login from logged-out state) ───────────
    else if (previousDbId == 0 && currentDbId > 0) {
      debugPrint(
          'HomeScreen: Sign-in detected — clearing stale data, resuming for user $currentDbId');
      // CRITICAL: Clear any leftover data from a previous session before
      // loading this user's data
      _session.clearAll();
      _initializeSession();
      _loadSavedProgress();
    }

    // ── User switched accounts (both non-zero but different IDs) ──────────
    else if (previousDbId > 0 &&
        currentDbId > 0 &&
        previousDbId != currentDbId) {
      debugPrint(
          'HomeScreen: Account switch detected ($previousDbId → $currentDbId) — deferring I/O to prevent jank');
      _session.resetForAccountSwitch();

      _initializeSession();
      _loadSavedProgress();
    }
    setState(() {});
  }

  Future<void> _initializeSession() async {
    debugPrint('HomeScreen: Initializing session...');

    // Clear any corrupted active time data first
    await _session.clearCorruptedActiveTimeData();

    // Load persisted active time first
    await _loadPersistedActiveTime();

    // Then start activity tracking (which will also load time again but shouldn't reset it)
    await _startActivityTracking();

    debugPrint(
        'HomeScreen: Session initialized with active time: ${_session.realTimeActiveSeconds} seconds');
  }

  Future<void> _loadPersistedActiveTime() async {
    await _session.loadActiveTime();
    debugPrint(
        'HomeScreen: Loaded persisted active time: ${_session.realTimeActiveSeconds} seconds');
  }

  Future<void> _loadSavedProgress() async {
    final currentDbId = _session.dbId;

    // ── Logged-in user ────────────────────────────────────────────────────
    if (currentDbId > 0) {
      debugPrint('HomeScreen: Loading saved progress for user $currentDbId...');
      // Load language progress from the locally stored exercise answers.
      await ApiService.loadLanguageProgress();

      // Safety check: if loadLanguageProgress returned no data (truly new user
      // who has never answered a practice), ensure all languages are at 0
      // so they never accidentally inherit a previous user's cached values.
      final hasAnyProgress = _session.languageProgress.values.any((p) => p > 0);
      if (!hasAnyProgress) {
        debugPrint(
            'HomeScreen: No progress found for user $currentDbId — initialising all languages to 0%');
        for (final language in ['Java', 'Python', 'C#', 'JavaScript', 'SQL']) {
          _session.updateLanguageProgress(language, 0.0);
        }
      }
    }

    // ── Guest / not logged in ─────────────────────────────────────────────
    else {
      debugPrint('HomeScreen: Guest/new user — resetting all data to zero');
      // Explicitly zero every language so the singleton never shows stale data
      for (final language in ['Java', 'Python', 'C#', 'JavaScript', 'SQL']) {
        _session.updateLanguageProgress(language, 0.0);
      }
      _session.clearAll();
    }

    if (mounted) {
      setState(() {});
    }
  }

  // ignore: unused_element
  Future<void> _refreshLanguageProgress() async {
    if (_session.dbId == 0) return;

    // Fetch fresh profile data to get updated language progress
    final result = await ApiService.getProfile(_session.dbId);
    if (result.success && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = context.clBg;
    final bgCard = context.clBgCard;
    final border = context.clBorder;
    final txtMut = context.clTextMuted;
    final txtSec = context.clTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App bar ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                        // Tappable search button
                        GestureDetector(
                          onTap: () {
                            final shell =
                                context.dependOnInheritedWidgetOfExactType<
                                    ShellNavigator>();
                            if (shell != null) {
                              showSiklabSearch(context,
                                  onNavigate: shell.setIndex);
                            }
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: bgCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: border),
                            ),
                            child: Icon(Icons.search, color: txtSec, size: 20),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const SiklabHamburgerMenu(),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Greeting ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ListenableBuilder(
                  listenable: UserSession(),
                  builder: (context, _) {
                    final session = UserSession();
                    final txtPri = context.clTextPrimary;

                    debugPrint(
                        'HomeScreen: Building greeting - UserSession state:');
                    debugPrint('HomeScreen: - dbId: ${session.dbId}');
                    debugPrint(
                        'HomeScreen: - displayName: "${session.displayName}"');
                    debugPrint(
                        'HomeScreen: - firstName: "${session.firstName}"');
                    debugPrint('HomeScreen: - email: "${session.email}"');
                    debugPrint('HomeScreen: - userId: "${session.userId}"');

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                    color: SiklabColors.success,
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Text('SYSTEM ONLINE',
                                  style: GoogleFonts.sourceCodePro(
                                      color: txtSec,
                                      fontSize: 10,
                                      letterSpacing: 1.5)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.spaceGrotesk(
                                color: txtPri,
                                fontSize: 30,
                                fontWeight: FontWeight.w700),
                            children: [
                              const TextSpan(text: 'Hello, '),
                              TextSpan(
                                text: '${session.firstName}.',
                                style:
                                    const TextStyle(color: SiklabColors.cyan),
                              ),
                            ],
                          ),
                        ),
                        Text('Ready to code?',
                            style: GoogleFonts.spaceGrotesk(
                                color: txtMut, fontSize: 16)),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
              ),
            ),

            // ── Streak card ───────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _RealTimeStreakCard(),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ── Recommended Topics ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _RecommendedCard(),
              ),
            ),

            // ── Module list ───────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ListenableBuilder(
                      listenable: UserSession(),
                      builder: (context, _) =>
                          _ModuleCard(module: _allModules[i]),
                    ),
                  ),
                  childCount: _allModules.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: _HomeOverallCertificate(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

// ─── Real-Time Streak Card ────────────────────────────────────────────────────

class _RealTimeStreakCard extends StatefulWidget {
  const _RealTimeStreakCard();

  @override
  State<_RealTimeStreakCard> createState() => _RealTimeStreakCardState();
}

class _RealTimeStreakCardState extends State<_RealTimeStreakCard> {
  Timer? _uiUpdateTimer;

  @override
  void initState() {
    super.initState();
    // Update UI every 1 second for real-time display
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _uiUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = UserSession();
    final bgCard = context.clBgCard;
    final border = context.clBorder;
    final txtSec = context.clTextSecondary;
    final txtMut = context.clTextMuted;

    final isTimerRunning = session.isTimerRunning;
    final realTimeSeconds = session.realTimeActiveSeconds;

    debugPrint(
        'HomeScreen: _RealTimeStreakCard building - seconds: $realTimeSeconds, timer running: $isTimerRunning');

    // Format display value and unit based on seconds
    String displayValue;
    String displayUnit;

    if (realTimeSeconds < 60) {
      final s = realTimeSeconds;
      displayValue = s.toString();
      displayUnit = s == 1 ? 'second active' : 'seconds active';
    } else if (realTimeSeconds < 3600) {
      final m = (realTimeSeconds ~/ 60);
      displayValue = m.toString();
      displayUnit = m == 1 ? 'minute active' : 'minutes active';
    } else if (realTimeSeconds < 86400) {
      final h = (realTimeSeconds ~/ 3600);
      displayValue = h.toString();
      displayUnit = h == 1 ? 'hour active' : 'hours active';
    } else {
      final d = (realTimeSeconds ~/ 86400);
      displayValue = d.toString();
      displayUnit = d == 1 ? 'day active' : 'days active';
    }

    // Calculate filled segments (10 minutes = 1 segment, 7 total)
    const totalSegments = 7;
    final minutes = (realTimeSeconds / 60).clamp(0.0, 70.0);
    final filled = ((minutes / 10).clamp(0.0, 7.0)).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ACTIVE NOW',
                    style: GoogleFonts.sourceCodePro(
                        color: txtMut, fontSize: 10, letterSpacing: 1.5)),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.spaceGrotesk(
                        color: SiklabColors.cyan,
                        fontSize: 32,
                        fontWeight: FontWeight.w700),
                    children: [
                      TextSpan(text: displayValue),
                      TextSpan(
                          text: ' $displayUnit',
                          style: GoogleFonts.spaceGrotesk(
                              color: txtSec,
                              fontSize: 16,
                              fontWeight: FontWeight.w400)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(
                    totalSegments,
                    (i) => Expanded(
                      child: Container(
                        height: 3,
                        margin: EdgeInsets.only(
                            right: i < totalSegments - 1 ? 4 : 0),
                        decoration: BoxDecoration(
                          color: i < filled ? SiklabColors.cyan : border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Lightning bolt — cyan when running, muted when stopped
          Icon(
            Icons.bolt,
            color: isTimerRunning ? SiklabColors.cyan : txtMut,
            size: 36,
          ),
        ],
      ),
    );
  }
}

// ─── Module Card ──────────────────────────────────────────────────────────────

class _ModuleCard extends StatelessWidget {
  final _Module module;
  const _ModuleCard({required this.module});

  @override
  Widget build(BuildContext context) {
    final bgCard = context.clBgCard;
    final bgElevated = context.clBgElevated;
    final border = context.clBorder;
    final txtPri = context.clTextPrimary;
    final txtMut = context.clTextMuted;
    final progress = UserSession().getLanguageProgress(module.title);
    final hasProgress = progress > 0;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ModulesScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: hasProgress
                          ? module.color.withValues(alpha: 0.2)
                          : bgElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: hasProgress ? module.color : border,
                          width: hasProgress ? 2 : 1)),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(module.icon,
                            color: hasProgress ? module.color : txtMut,
                            size: 22),
                      ),
                      if (hasProgress)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: SiklabColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: bgCard, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                ListenableBuilder(
                  listenable: UserSession(),
                  builder: (context, _) {
                    final progress =
                        UserSession().getLanguageProgress(module.title);
                    final hasProgress = progress > 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasProgress
                            ? module.color.withValues(alpha: 0.2)
                            : module.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: hasProgress
                            ? Border.all(color: module.color, width: 1)
                            : null,
                      ),
                      child: Text(
                        hasProgress
                            ? '${UserSession().getLanguageProgressPercent(module.title)}% ✓'
                            : '${UserSession().getLanguageProgressPercent(module.title)}% complete',
                        style: GoogleFonts.sourceCodePro(
                            color: module.color,
                            fontSize: hasProgress ? 12 : 11,
                            fontWeight: FontWeight.w700),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(module.title,
                style: GoogleFonts.spaceGrotesk(
                    color: txtPri, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(module.desc,
                style: GoogleFonts.spaceGrotesk(
                    color: txtMut, fontSize: 13, height: 1.5)),
            const SizedBox(height: 14),
            ListenableBuilder(
              listenable: UserSession(),
              builder: (context, _) {
                final progress =
                    UserSession().getLanguageProgress(module.title);
                return ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: border,
                    valueColor: AlwaysStoppedAnimation(module.color),
                    minHeight: 3,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            FutureBuilder<CompletionStatus>(
              future: CertificateService.getStatus(language: module.title),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    'Could not load ${module.title} certificate status.',
                    style: GoogleFonts.spaceGrotesk(
                      color: context.clTextMuted,
                      fontSize: 12,
                    ),
                  );
                }
                final status = snapshot.data;
                if (status == null) {
                  return const LinearProgressIndicator(minHeight: 2);
                }
                return _CertificateActionButton(
                  label: status.isComplete
                      ? 'VIEW ${module.title.toUpperCase()} CERTIFICATE'
                      : '${module.title.toUpperCase()} CERTIFICATE · '
                          '${status.percent}% COMPLETE',
                  isUnlocked: status.isComplete,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CertificateScreen(language: module.title),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Module {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  const _Module(this.icon, this.title, this.desc, this.color);
}

class _HomeOverallCertificate extends StatelessWidget {
  const _HomeOverallCertificate();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserSession(),
      builder: (context, _) => FutureBuilder<Map<String, CompletionStatus>>(
        future: CertificateService.getLanguageStatuses(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(
              'Could not load overall certificate status.',
              style: GoogleFonts.spaceGrotesk(
                color: context.clTextMuted,
                fontSize: 12,
              ),
            );
          }
          final statuses = snapshot.data;
          final overall = statuses == null
              ? null
              : CertificateService.combine(statuses.values);
          final progress = overall?.percent ?? 0;
          final unlocked = overall?.isComplete ?? false;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR CERTIFICATES',
                style: GoogleFonts.sourceCodePro(
                  color: SiklabColors.cyan,
                  fontSize: 11,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _CertificateActionButton(
                label: unlocked
                    ? 'VIEW OVERALL CERTIFICATE'
                    : 'OVERALL CERTIFICATE · $progress% COMPLETE',
                isUnlocked: unlocked,
                onPressed: snapshot.connectionState == ConnectionState.done
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const CertificateScreen(),
                          ),
                        )
                    : null,
              ),
              if (!unlocked) ...[
                const SizedBox(height: 7),
                Text(
                  'Complete all five languages to unlock your overall certificate.',
                  style: GoogleFonts.spaceGrotesk(
                    color: context.clTextMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CertificateActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isUnlocked;

  const _CertificateActionButton({
    required this.label,
    required this.onPressed,
    this.isUnlocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          isUnlocked ? Icons.workspace_premium_outlined : Icons.lock_outline,
          size: 18,
        ),
        label: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor:
              isUnlocked ? SiklabColors.success : context.clTextMuted,
          side: BorderSide(
            color: isUnlocked
                ? SiklabColors.success.withValues(alpha: 0.6)
                : context.clBorder,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// ─── Recommended Topics Card ──────────────────────────────────────────────────

class _RecommendedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final profile = UserProfile();
    final bgCard = context.clBgCard;
    final bgElev = context.clBgElevated;
    final border = context.clBorder;
    final txtPri = context.clTextPrimary;
    final txtSec = context.clTextSecondary;

    final level = profile.experienceLevel;
    final Color headerColor;
    final String headerLabel;
    final String subLabel;
    switch (level) {
      case 'expert':
        headerColor = SiklabColors.purple;
        headerLabel = 'ADVANCED PATH';
        subLabel = 'Picked for your expertise level.';
      case 'intermediate':
        headerColor = SiklabColors.cyan;
        headerLabel = 'INTERMEDIATE PATH';
        subLabel = 'Topics matched to your experience.';
      case 'beginner':
        headerColor = SiklabColors.success;
        headerLabel = 'BEGINNER PATH';
        subLabel = 'Start strong with these fundamentals.';
      default:
        headerColor = SiklabColors.orange;
        headerLabel = 'RECOMMENDED FOR YOU';
        subLabel = 'Tap any topic to start practicing.';
    }

    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: headerColor.withValues(alpha: 0.07),
              border: Border(bottom: BorderSide(color: border)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: headerColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.auto_awesome, color: headerColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(headerLabel,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.sourceCodePro(
                                  color: headerColor,
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: headerColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text('REC',
                              style: GoogleFonts.sourceCodePro(
                                  color: headerColor,
                                  fontSize: 7,
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ]),
                      const SizedBox(height: 2),
                      Text(subLabel,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                              color: txtSec, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: ListenableBuilder(
              listenable: UserSession(),
              builder: (context, _) {
                final userId = UserSession().dbId;
                if (userId == 0) {
                  final topics = profile.recommendedTopics;
                  return Column(
                    children: topics
                        .asMap()
                        .entries
                        .map((e) => _localRecTile(
                              context: context,
                              bgElev: bgElev,
                              txtPri: txtPri,
                              txtSec: txtSec,
                              border: border,
                              topic: e.value,
                              isLast: e.key == topics.length - 1,
                            ))
                        .toList(),
                  );
                }

                return FutureBuilder(
                  future: _fetchBackendRecommendations(userId),
                  builder: (context, snap) {
                    final data = snap.data;
                    if (snap.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: CircularProgressIndicator(
                              color: SiklabColors.cyan),
                        ),
                      );
                    }
                    if (data == null || data.isEmpty) {
                      final topics = profile.recommendedTopics;
                      return Column(
                        children: topics
                            .asMap()
                            .entries
                            .map((e) => _localRecTile(
                                  context: context,
                                  bgElev: bgElev,
                                  txtPri: txtPri,
                                  txtSec: txtSec,
                                  border: border,
                                  topic: e.value,
                                  isLast: e.key == topics.length - 1,
                                ))
                            .toList(),
                      );
                    }

                    return Column(
                      children: data.asMap().entries.map((e) {
                        final isLast = e.key == data.length - 1;
                        final r = e.value;
                        final title =
                            (r['recommended_language'] as String?) ?? 'Lesson';
                        final sub =
                            '${r['recommended_level']} • ${r['recommended_topic']}';
                        return Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ModulesScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: bgElev,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: border),
                                ),
                                child: Row(children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: SiklabColors.cyan
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.auto_awesome,
                                        color: SiklabColors.cyan),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(title,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.spaceGrotesk(
                                                color: txtPri,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 3),
                                        Text(sub,
                                            style: GoogleFonts.spaceGrotesk(
                                                color: txtSec,
                                                fontSize: 12,
                                                height: 1.4)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: SiklabColors.cyan
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.arrow_forward_ios,
                                        color: SiklabColors.cyan, size: 12),
                                  ),
                                ]),
                              ),
                            ),
                            if (!isLast) const SizedBox(height: 8),
                          ],
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ),
          GestureDetector(
            onTap: () => ShellNavigator.goModules(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: headerColor.withValues(alpha: 0.05),
                border: Border(top: BorderSide(color: border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.code_outlined, color: headerColor, size: 16),
                  const SizedBox(width: 8),
                  Text('OPEN MODULES →',
                      style: GoogleFonts.sourceCodePro(
                          color: headerColor,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _guessLanguage(String topicTitle) {
    final t = topicTitle.toLowerCase();
    if (t == 'java' ||
        t == 'python' ||
        t == 'c#' ||
        t == 'javascript' ||
        t == 'sql') {
      return topicTitle;
    }
    if (t.contains('algorithm') ||
        t.contains('oop') ||
        t.contains('structure')) {
      return 'Java';
    }
    if (t.contains('debug') ||
        t.contains('variable') ||
        t.contains('condition')) {
      return 'Python';
    }
    if (t.contains('what is programming') || t.contains('simple output')) {
      return 'Python';
    }
    return null;
  }

  Widget _localRecTile({
    required BuildContext context,
    required Color bgElev,
    required Color txtPri,
    required Color txtSec,
    required Color border,
    required RecommendedTopic topic,
    required bool isLast,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            final language = _guessLanguage(topic.title);
            if (language != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ModulesScreen(),
                ),
              );
            } else {
              ShellNavigator.goPractice(context);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bgElev,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: topic.color.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: topic.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(topic.icon, color: topic.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(topic.title,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                                color: txtPri,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: topic.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(topic.tag,
                            style: GoogleFonts.sourceCodePro(
                                color: topic.color,
                                fontSize: 8,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w700)),
                      ),
                    ]),
                    const SizedBox(height: 3),
                    Text(topic.desc,
                        style: GoogleFonts.spaceGrotesk(
                            color: txtSec, fontSize: 12, height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: topic.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(Icons.arrow_forward_ios, color: topic.color, size: 12),
              ),
            ]),
          ),
        ),
        if (!isLast) const SizedBox(height: 8),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _fetchBackendRecommendations(
      int userId) async {
    try {
      final res = await http
          .get(Uri.parse('${ApiService.baseUrl()}/recommendations/$userId'));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['success'] == true && body['recommendations'] is List) {
        return (body['recommendations'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
