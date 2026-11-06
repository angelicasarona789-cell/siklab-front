import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/code_answer_field.dart';
import '../widgets/secure_text_field.dart';
import '../models/quiz_data.dart';
import '../models/navigation_intents.dart';
import '../models/user_session.dart';
import '../services/api_service.dart';
import '../widgets/ai_reliance_feedback_dialog.dart';
import '../services/ai_feedback_service.dart';
import '../widgets/recommendation_card.dart';
import '../services/recommendation_service.dart';
import '../services/practice_timing_service.dart';
import '../services/practice_timer_sound_service.dart';
import '../navigation/shell_navigator.dart';

// ═════════════════════════════════════════════════════════════════════════════
// ROOT CONTROLLER
// ═════════════════════════════════════════════════════════════════════════════

class PracticeScreen extends StatefulWidget {
  final String? initialLanguage;
  final String? categorySubtitle;
  final bool moduleMode;
  const PracticeScreen({
    super.key,
    this.initialLanguage,
    this.categorySubtitle,
    this.moduleMode = false,
  });
  @override
  PracticeScreenState createState() => PracticeScreenState();
}

class PracticeScreenState extends State<PracticeScreen> {
  static const _requiredModuleTopics = 5;

  LanguageQuiz? _lang;
  QuizCategory? _category;
  int _qIndex = -1; // -1 = not in a question
  int _topicIndex = -1;
  bool _showTimeout = false;
  final NavigationIntents _intents = NavigationIntents();
  Future<int>? _moduleCompletionFuture;

  void refreshUnlockStatus() {
    final language = _lang?.name;
    if (!widget.moduleMode && language != null && mounted) {
      setState(() {
        _moduleCompletionFuture =
            ApiService.getModuleTopicCompletionCount(language);
      });
    }
  }

  List<QuizQuestion> get _activeQuestions {
    final questions = _lang!.categories[_category]!;
    if (widget.moduleMode) return questions;
    return questions.map((question) => question.forPractice()).toList(
          growable: false,
        );
  }

  @override
  void initState() {
    super.initState();

    // If initialLanguage is provided, set it directly
    if (widget.initialLanguage != null) {
      for (final quiz in languageQuizzes) {
        if (quiz.name == widget.initialLanguage) {
          _lang = quiz;
          _moduleCompletionFuture =
              ApiService.getModuleTopicCompletionCount(quiz.name);
          break;
        }
      }
    }

    _intents.addListener(_consumeNavigationIntent);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _consumeNavigationIntent());
  }

  @override
  void dispose() {
    _intents.removeListener(_consumeNavigationIntent);
    super.dispose();
  }

  void _consumeNavigationIntent() {
    final language = _intents.consumePracticeLanguage();
    if (language == null) return;
    LanguageQuiz? match;
    for (final quiz in languageQuizzes) {
      if (quiz.name == language) {
        match = quiz;
        break;
      }
    }
    if (match != null && mounted) {
      setState(() {
        _lang = match;
        _category = null;
        _qIndex = -1;
        _moduleCompletionFuture =
            ApiService.getModuleTopicCompletionCount(match!.name);
      });
    }
  }

  // nav helpers
  void _pickLang(LanguageQuiz l) => setState(() {
        _lang = l;
        _category = null;
        _qIndex = -1;
        _moduleCompletionFuture =
            ApiService.getModuleTopicCompletionCount(l.name);
      });
  Future<void> _pickCategory(QuizCategory c) async {
    final language = _lang;
    if (language == null || widget.moduleMode) {
      setState(() {
        _category = c;
        _qIndex = -1;
        _topicIndex = -1;
      });
      return;
    }

    final cooldownUntil =
        await PracticeTimingService.getCooldown(language.name, c);
    if (!mounted) return;
    if (cooldownUntil != null) {
      setState(() {
        _category = c;
        _qIndex = -1;
        _topicIndex = -1;
        _showTimeout = true;
      });
      return;
    }
    setState(() {
      _category = c;
      _qIndex = -1;
      _topicIndex = -1;
    });
  }

  void _openQuestion(int i) => setState(() => _qIndex = i);
  void _openTopic(int i) => setState(() => _topicIndex = i);
  void _backToLangPicker() => setState(() {
        _lang = null;
        _category = null;
        _qIndex = -1;
        _moduleCompletionFuture = null;
      });
  void _backToCategoryPicker() => setState(() {
        _category = null;
        _qIndex = -1;
      });

  void _handlePracticeTimeout() {
    if (!mounted) return;
    setState(() {
      _qIndex = -1;
      _showTimeout = true;
    });
  }

  void _leaveTimedOutPractice() {
    setState(() {
      _showTimeout = false;
      _category = null;
      _qIndex = -1;
    });
    ShellNavigator.goModules(context);
  }

  void _backToQuestionList() => setState(() => _qIndex = -1);

  void _nextOrFinish() {
    final questions = _activeQuestions;
    final next = _qIndex + 1;
    if (next < questions.length) {
      setState(() => _qIndex = next);
    } else {
      _backToQuestionList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildPracticeContent(context);
  }

  Widget _buildPracticeContent(BuildContext context) {
    // ── 1. Language picker ──
    if (_lang == null) {
      return _LanguagePickerScreen(onPick: _pickLang);
    }
    if (!widget.moduleMode) {
      final completionFuture = _moduleCompletionFuture ??=
          ApiService.getModuleTopicCompletionCount(_lang!.name);
      return FutureBuilder<int>(
        future: completionFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _PracticeLockedScreen(
              language: _lang!.name,
              completedTopics: 0,
              requiredTopics: _requiredModuleTopics,
              error: 'Could not load module progress: ${snapshot.error}',
              onRetry: refreshUnlockStatus,
              onChangeLanguage: _backToLangPicker,
            );
          }
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.data! < _requiredModuleTopics) {
            return _PracticeLockedScreen(
              language: _lang!.name,
              completedTopics: snapshot.data!,
              requiredTopics: _requiredModuleTopics,
              onChangeLanguage: _backToLangPicker,
            );
          }
          return _buildSelectedLanguageContent(context);
        },
      );
    }
    return _buildSelectedLanguageContent(context);
  }

  Widget _buildSelectedLanguageContent(BuildContext context) {
    if (_showTimeout && _category != null) {
      return _PracticeTimeoutScreen(
        language: _lang!.name,
        category: _category!,
        onReturnToModule: _leaveTimedOutPractice,
        onReturnToPractice: () => setState(() {
          _showTimeout = false;
          _category = null;
        }),
      );
    }

    // ── 2. Category picker ──
    if (_category == null) {
      return _CategoryPickerScreen(
        lang: _lang!,
        onBack: widget.moduleMode
            ? () => Navigator.of(context).pop()
            : _backToLangPicker,
        onPick: _pickCategory,
        subtitle: widget.categorySubtitle,
        moduleMode: widget.moduleMode,
      );
    }
    if (widget.moduleMode) {
      final topics = _lang!.categories[_category] ?? const <QuizQuestion>[];
      if (_topicIndex == -1) {
        return _ModuleTopicListScreen(
          lang: _lang!,
          category: _category!,
          topics: topics,
          onBack: _backToCategoryPicker,
          onSelect: _openTopic,
        );
      }
      return _ModuleTopicDetailScreen(
        lang: _lang!,
        category: _category!,
        topic: topics[_topicIndex],
        topicNumber: _topicIndex + 1,
        total: topics.length,
        onBack: () => setState(() => _topicIndex = -1),
        onNext: _topicIndex < topics.length - 1
            ? () => setState(() => _topicIndex++)
            : null,
      );
    }
    // ── 3. Question list ──
    if (_qIndex == -1) {
      return _QuestionListScreen(
        lang: _lang!,
        category: _category!,
        questions: _activeQuestions,
        onBack: _backToCategoryPicker,
        onSelect: _openQuestion,
      );
    }
    // ── 4. Active challenge ──
    final questions = _activeQuestions;
    return _ChallengeFlow(
      key: ValueKey('${_lang!.name}_${_category!.name}_$_qIndex'),
      lang: _lang!,
      category: _category!,
      question: questions[_qIndex],
      questionNumber: _qIndex + 1,
      total: questions.length,
      onBack: _backToQuestionList,
      onNextOrFinish: _nextOrFinish,
      onTimeExpired: _handlePracticeTimeout,
      isLast: _qIndex == questions.length - 1,
    );
  }
}

class _PracticeTimeoutScreen extends StatefulWidget {
  final String language;
  final QuizCategory category;
  final VoidCallback onReturnToModule;
  final VoidCallback onReturnToPractice;

  const _PracticeTimeoutScreen({
    required this.language,
    required this.category,
    required this.onReturnToModule,
    required this.onReturnToPractice,
  });

  @override
  State<_PracticeTimeoutScreen> createState() => _PracticeTimeoutScreenState();
}

class _PracticeTimeoutScreenState extends State<_PracticeTimeoutScreen> {
  DateTime? _cooldownUntil;
  Timer? _timer;
  int _remainingSeconds = PracticeTimingService.cooldownDuration.inSeconds;

  @override
  void initState() {
    super.initState();
    _loadCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadCooldown() async {
    final until = await PracticeTimingService.getCooldown(
      widget.language,
      widget.category,
    );
    if (!mounted) return;
    _cooldownUntil = until;
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(_updateRemaining);
    });
  }

  void _updateRemaining() {
    final until = _cooldownUntil;
    _remainingSeconds = until == null
        ? 0
        : until.difference(DateTime.now()).inSeconds.clamp(0, 300);
    if (_remainingSeconds == 0) _timer?.cancel();
  }

  String get _countdown {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final cooldownActive = _remainingSeconds > 0;
    return Scaffold(
      backgroundColor: context.clBg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: context.clBgCard,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: SiklabColors.error.withValues(alpha: 0.6)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_off_rounded,
                    color: SiklabColors.error,
                    size: 54,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "Time's up!",
                    style: GoogleFonts.spaceGrotesk(
                      color: context.clTextPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You ran out of time for this ${widget.category.label} '
                    '${widget.language} exercise. Return to the '
                    '${widget.language} module and try again after the '
                    '5-minute cooldown.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      color: context.clTextSecondary,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  if (cooldownActive) ...[
                    const SizedBox(height: 20),
                    Text(
                      _countdown,
                      style: GoogleFonts.sourceCodePro(
                        color: SiklabColors.error,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    CyanButton(
                      label: 'RETURN TO MODULE',
                      icon: Icons.menu_book_outlined,
                      onTap: widget.onReturnToModule,
                    ),
                  ] else ...[
                    const SizedBox(height: 22),
                    CyanButton(
                      label: 'RETURN TO PRACTICE',
                      icon: Icons.refresh_rounded,
                      onTap: widget.onReturnToPractice,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PracticeLockedScreen extends StatelessWidget {
  final String language;
  final int completedTopics;
  final int requiredTopics;
  final String? error;
  final VoidCallback? onRetry;
  final VoidCallback onChangeLanguage;

  const _PracticeLockedScreen({
    required this.language,
    required this.completedTopics,
    required this.requiredTopics,
    required this.onChangeLanguage,
    this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    const accent = SiklabColors.cyan;
    return Scaffold(
      backgroundColor: context.clBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.clBgCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.clBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      color: accent, size: 42),
                  const SizedBox(height: 14),
                  Text(
                    'PRACTICE LOCKED',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sourceCodePro(
                      color: accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Complete $requiredTopics $language module topics correctly to unlock the $language quiz.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      color: context.clTextSecondary,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$completedTopics of $requiredTopics topics completed',
                    style: GoogleFonts.sourceCodePro(
                      color: context.clTextPrimary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (error != null) ...[
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        color: SiklabColors.error,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CyanButton(
                      label: 'RETRY',
                      icon: Icons.refresh,
                      onTap: onRetry,
                    ),
                  ] else
                    CyanButton(
                      label: 'CHANGE LANGUAGE',
                      icon: Icons.language,
                      onTap: onChangeLanguage,
                    ),
                  TextButton.icon(
                    onPressed: () => ShellNavigator.goModules(context),
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('GO TO MODULES'),
                  ),
                  if (error != null)
                    TextButton.icon(
                      onPressed: onChangeLanguage,
                      icon: const Icon(Icons.language),
                      label: const Text('CHANGE LANGUAGE'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 1. LANGUAGE PICKER
// ═════════════════════════════════════════════════════════════════════════════

class _LanguagePickerScreen extends StatelessWidget {
  final ValueChanged<LanguageQuiz> onPick;
  const _LanguagePickerScreen({required this.onPick});

  @override
  Widget build(BuildContext context) {
    final bg = context.clBg;
    final txt = context.clTextMuted;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 28),
            Text('SELECT_LANGUAGE',
                style: GoogleFonts.sourceCodePro(
                    color: SiklabColors.cyan, fontSize: 11, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text('Choose your\nprogramming language.',
                style: GoogleFonts.spaceGrotesk(
                    color: context.clTextPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.2)),
            const SizedBox(height: 8),
            Text('3 difficulty levels • 10 questions each',
                style: GoogleFonts.spaceGrotesk(
                    color: txt, fontSize: 14, height: 1.5)),
            const SizedBox(height: 28),
            ...languageQuizzes.map(
              (lang) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _LangCard(lang: lang, onTap: () => onPick(lang)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _LangCard extends StatelessWidget {
  final LanguageQuiz lang;
  final VoidCallback onTap;
  const _LangCard({required this.lang, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgCard = context.clBgCard;
    final border = context.clBorder;
    final txtPri = context.clTextPrimary;
    final txtMut = context.clTextMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: lang.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: lang.color.withValues(alpha: 0.3)),
              ),
              child: Icon(lang.icon, color: lang.color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                        child: Text(lang.name,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                                color: txtPri,
                                fontSize: 20,
                                fontWeight: FontWeight.w700))),
                    const SizedBox(width: 8),
                    _badge(lang.tag, lang.color),
                  ]),
                  const SizedBox(height: 6),
                  // 3 level dots
                  Row(children: [
                    _dot(SiklabColors.success),
                    const SizedBox(width: 4),
                    _dot(SiklabColors.cyan),
                    const SizedBox(width: 4),
                    _dot(SiklabColors.purple),
                    const SizedBox(width: 8),
                    Text('3 levels',
                        style: GoogleFonts.sourceCodePro(
                            color: txtMut, fontSize: 10)),
                  ]),
                  const SizedBox(height: 2),
                  Text('30 questions total',
                      style: GoogleFonts.sourceCodePro(
                          color: txtMut, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: lang.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_forward_ios, color: lang.color, size: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color c) => Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

// ═════════════════════════════════════════════════════════════════════════════
// 2. CATEGORY PICKER
// ═════════════════════════════════════════════════════════════════════════════

class _CategoryPickerScreen extends StatefulWidget {
  final LanguageQuiz lang;
  final VoidCallback onBack;
  final ValueChanged<QuizCategory> onPick;
  final String? subtitle;
  final bool moduleMode;
  const _CategoryPickerScreen({
    required this.lang,
    required this.onBack,
    required this.onPick,
    this.subtitle,
    this.moduleMode = false,
  });

  @override
  State<_CategoryPickerScreen> createState() => _CategoryPickerScreenState();
}

class _CategoryPickerScreenState extends State<_CategoryPickerScreen> {
  late Future<Map<QuizCategory, DateTime?>> _cooldownsFuture;
  late Future<Set<String>> _progressFuture;
  Map<QuizCategory, DateTime?> _cooldowns = const {};
  Timer? _cooldownRefreshTimer;

  LanguageQuiz get lang => widget.lang;
  VoidCallback get onBack => widget.onBack;
  ValueChanged<QuizCategory> get onPick => widget.onPick;
  String? get subtitle => widget.subtitle;
  bool get moduleMode => widget.moduleMode;

  @override
  void initState() {
    super.initState();
    _cooldownsFuture = Future.value(_cooldowns);
    _progressFuture = _loadProgress();
    _refreshCooldowns();
  }

  @override
  void didUpdateWidget(covariant _CategoryPickerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lang.name != widget.lang.name ||
        oldWidget.moduleMode != widget.moduleMode) {
      _progressFuture = _loadProgress();
      _refreshCooldowns();
    }
  }

  Future<Set<String>> _loadProgress() => widget.moduleMode
      ? ApiService.getCompletedModuleTopicIds(widget.lang.name)
      : ApiService.getAnsweredQuestionIds(widget.lang.name);

  Future<void> _refreshCooldowns() async {
    final cooldowns =
        await PracticeTimingService.getCooldowns(widget.lang.name);
    if (!mounted) return;
    _cooldowns = cooldowns;
    setState(() => _cooldownsFuture = Future.value(cooldowns));
    final hasCooldown = !widget.moduleMode &&
        cooldowns.values.any(
          (until) => until != null && until.isAfter(DateTime.now()),
        );
    if (hasCooldown) {
      _cooldownRefreshTimer ??= Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          if (!mounted) return;
          final stillCoolingDown = _cooldowns.values.any(
            (until) => until != null && until.isAfter(DateTime.now()),
          );
          if (stillCoolingDown) {
            setState(() {});
          } else {
            _cooldownRefreshTimer?.cancel();
            _cooldownRefreshTimer = null;
            _refreshCooldowns();
          }
        },
      );
    } else {
      _cooldownRefreshTimer?.cancel();
      _cooldownRefreshTimer = null;
    }
  }

  @override
  void dispose() {
    _cooldownRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = context.clBg;
    final bgCard = context.clBgCard;
    final border = context.clBorder;
    final txtPri = context.clTextPrimary;
    final txtSec = context.clTextSecondary;
    final txtMut = context.clTextMuted;

    final totalQuestions = ApiService.getTotalPracticeQuestionCount(lang.name);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: FutureBuilder<Map<QuizCategory, DateTime?>>(
          future: _cooldownsFuture,
          builder: (context, cooldownSnapshot) => FutureBuilder<Set<String>>(
            future: _progressFuture,
            initialData: const <String>{},
            builder: (context, snapshot) {
              final cooldowns =
                  cooldownSnapshot.data ?? const <QuizCategory, DateTime?>{};
              final answered = snapshot.data ?? const <String>{};
              final answeredCount = answered.length > totalQuestions
                  ? totalQuestions
                  : answered.length;
              final overallPercent =
                  ApiService.calculatePracticeProgress(lang.name, answered);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── top bar ──
                    Row(children: [
                      _backBtn(onBack, bgCard, border, txtSec),
                      const SizedBox(width: 14),
                      const SiklabLogo(),
                    ]),
                    const SizedBox(height: 24),
                    // ── lang header ──
                    // FIX 1: Wrapped Column in Expanded to prevent right overflow
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: lang.color.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: lang.color.withValues(alpha: 0.25)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: lang.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(lang.icon, color: lang.color, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          // <-- FIX 1: was missing, caused overflow for all languages
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(lang.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.spaceGrotesk(
                                        color: txtPri,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700)),
                                Text(subtitle ?? 'SELECT DIFFICULTY LEVEL',
                                    style: GoogleFonts.sourceCodePro(
                                        color: lang.color,
                                        fontSize: 10,
                                        letterSpacing: 1.5)),
                              ]),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    _OverallProgressCard(
                      percent: overallPercent,
                      answered: answeredCount,
                      total: totalQuestions,
                      color: lang.color,
                    ),
                    const SizedBox(height: 28),
                    Text('CHOOSE CATEGORY',
                        style: GoogleFonts.sourceCodePro(
                            color: txtMut, fontSize: 10, letterSpacing: 2)),
                    const SizedBox(height: 16),
                    // ── 3 category cards ──
                    ...QuizCategory.values.map((cat) {
                      final catQuestions = lang.categories[cat] ?? const [];
                      final cooldownUntil = moduleMode ? null : cooldowns[cat];
                      final cooldownRemaining =
                          cooldownUntil?.difference(DateTime.now());
                      final onCooldown = cooldownRemaining != null &&
                          cooldownRemaining > Duration.zero;
                      final prerequisite = switch (cat) {
                        QuizCategory.beginner => null,
                        QuizCategory.intermediate => QuizCategory.beginner,
                        QuizCategory.upperIntermediate =>
                          QuizCategory.intermediate,
                      };
                      final prerequisiteQuestions = prerequisite == null
                          ? const <QuizQuestion>[]
                          : lang.categories[prerequisite] ?? const [];
                      final prerequisiteName = prerequisite?.name ?? '';
                      final prerequisiteCompleted =
                          prerequisiteQuestions.isNotEmpty &&
                              List.generate(
                                prerequisiteQuestions.length,
                                (i) => answered
                                    .contains('${prerequisiteName}_${i + 1}'),
                              ).every((isAnswered) => isAnswered);
                      final isLocked =
                          prerequisite != null && !prerequisiteCompleted;
                      final catAnswered = List.generate(catQuestions.length,
                              (i) => answered.contains('${cat.name}_${i + 1}'))
                          .where((done) => done)
                          .length;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _CategoryCard(
                          cat: cat,
                          langColor: lang.color,
                          bgCard: bgCard,
                          border: border,
                          txtPri: txtPri,
                          txtSec: txtSec,
                          answeredCount: catAnswered,
                          totalCount: catQuestions.length,
                          countLabel: moduleMode ? 'topics' : 'questions',
                          isLocked: isLocked || onCooldown,
                          lockedMessage: onCooldown
                              ? 'Available after the 5-minute cooldown.'
                              : prerequisite == null
                                  ? null
                                  : 'Complete ${prerequisite.label} difficulty to unlock.',
                          totalTime: moduleMode
                              ? null
                              : PracticeTimingService.categoryDuration(
                                  cat,
                                  catQuestions.length,
                                ),
                          perQuestionTime: moduleMode
                              ? null
                              : PracticeTimingService.questionDuration(cat),
                          onTap: () => onPick(cat),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ModuleTopicListScreen extends StatefulWidget {
  final LanguageQuiz lang;
  final QuizCategory category;
  final List<QuizQuestion> topics;
  final VoidCallback onBack;
  final ValueChanged<int> onSelect;

  const _ModuleTopicListScreen({
    required this.lang,
    required this.category,
    required this.topics,
    required this.onBack,
    required this.onSelect,
  });

  @override
  State<_ModuleTopicListScreen> createState() => _ModuleTopicListScreenState();
}

class _ModuleTopicListScreenState extends State<_ModuleTopicListScreen> {
  late Future<Set<String>> _completedTopicsFuture;

  @override
  void initState() {
    super.initState();
    _completedTopicsFuture =
        ApiService.getCompletedModuleTopicIds(widget.lang.name);
  }

  @override
  void didUpdateWidget(covariant _ModuleTopicListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lang.name != widget.lang.name) {
      _completedTopicsFuture =
          ApiService.getCompletedModuleTopicIds(widget.lang.name);
    }
  }

  String _topicLabel(QuizQuestion topic) =>
      topic.module.replaceFirst(RegExp(r'^Q\d+\s*//\s*'), '').trim();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.clBg,
      appBar: AppBar(
        backgroundColor: context.clBg,
        foregroundColor: context.clTextPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Text(
          '${widget.lang.name} • ${widget.category.label}',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<Set<String>>(
        future: _completedTopicsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Could not load completed topics: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        color: SiklabColors.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CyanButton(
                      label: 'RETRY',
                      icon: Icons.refresh,
                      onTap: () => setState(() {
                        _completedTopicsFuture =
                            ApiService.getCompletedModuleTopicIds(
                          widget.lang.name,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final completedTopicIds = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'TOPICS',
                style: GoogleFonts.sourceCodePro(
                  color: widget.category.color,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Learn ${widget.category.label}',
                style: GoogleFonts.spaceGrotesk(
                  color: context.clTextPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose a topic to view its lesson.',
                style: GoogleFonts.spaceGrotesk(color: context.clTextSecondary),
              ),
              const SizedBox(height: 20),
              ...List.generate(widget.topics.length, (index) {
                final topic = widget.topics[index];
                final isCompleted = completedTopicIds
                    .contains('${widget.category.name}_${index + 1}');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: context.clBgCard,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => widget.onSelect(index),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCompleted
                                ? SiklabColors.success.withValues(alpha: 0.55)
                                : context.clBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: (isCompleted
                                        ? SiklabColors.success
                                        : widget.category.color)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isCompleted
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.menu_book_outlined,
                                color: isCompleted
                                    ? SiklabColors.success
                                    : widget.category.color,
                                size: 21,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _topicLabel(topic),
                                    style: GoogleFonts.sourceCodePro(
                                      color: widget.category.color,
                                      fontSize: 10,
                                      letterSpacing: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    topic.title,
                                    style: GoogleFonts.spaceGrotesk(
                                      color: context.clTextPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    topic.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.spaceGrotesk(
                                      color: context.clTextSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isCompleted) ...[
                              const SizedBox(width: 8),
                              Text(
                                'DONE',
                                style: GoogleFonts.sourceCodePro(
                                  color: SiklabColors.success,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ] else
                              Icon(Icons.chevron_right,
                                  color: context.clTextMuted),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _JavaIntroductionCard extends StatelessWidget {
  final Color color;

  const _JavaIntroductionCard({required this.color});

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.spaceGrotesk(
      color: context.clTextSecondary,
      fontSize: 13,
      height: 1.5,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.clBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.clBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INTRODUCTION TO JAVA',
            style: GoogleFonts.sourceCodePro(
              color: color,
              fontSize: 10,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Java is a general-purpose programming language designed to help developers build reliable applications. First released in 1995, it is known for its readable structure, strong type system, and broad ecosystem.',
            style: textStyle,
          ),
          const SizedBox(height: 12),
          Text(
            'How Java runs',
            style: GoogleFonts.spaceGrotesk(
              color: context.clTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Java source code is compiled into bytecode, which runs on a Java Virtual Machine (JVM). JVMs are available for many operating systems, so the same compiled program can often run on different platforms.',
            style: textStyle,
          ),
          const SizedBox(height: 12),
          Text(
            'What Java is used for',
            style: GoogleFonts.spaceGrotesk(
              color: context.clTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Java is used in backend services, enterprise software, desktop tools, Android development, and large-scale data systems. Its libraries and community make it useful for projects of many sizes.',
            style: textStyle,
          ),
          const SizedBox(height: 12),
          Text(
            'What you will learn',
            style: GoogleFonts.spaceGrotesk(
              color: context.clTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start with output, variables, and data types, then build toward decisions, loops, methods, collections, and object-oriented programming. These basics help you read, write, and organize Java programs.',
            style: textStyle,
          ),
        ],
      ),
    );
  }
}

class _ModuleTopicDetailScreen extends StatefulWidget {
  final LanguageQuiz lang;
  final QuizCategory category;
  final QuizQuestion topic;
  final int topicNumber;
  final int total;
  final VoidCallback onBack;
  final VoidCallback? onNext;

  const _ModuleTopicDetailScreen({
    required this.lang,
    required this.category,
    required this.topic,
    required this.topicNumber,
    required this.total,
    required this.onBack,
    required this.onNext,
  });

  @override
  State<_ModuleTopicDetailScreen> createState() =>
      _ModuleTopicDetailScreenState();
}

class _ModuleTopicDetailScreenState extends State<_ModuleTopicDetailScreen> {
  late TextEditingController _practiceController;
  final FocusNode _practiceFocusNode = FocusNode();
  bool? _practiceCorrect;
  String? _practiceSaveError;

  QuizQuestion get _practiceQuestion =>
      widget.topic.forModuleCasePractice(widget.lang.name);

  @override
  void initState() {
    super.initState();
    _practiceController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant _ModuleTopicDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.topic != widget.topic || oldWidget.lang != widget.lang) {
      _practiceController.clear();
      _practiceCorrect = null;
      _practiceSaveError = null;
    }
  }

  @override
  void dispose() {
    _practiceController.dispose();
    _practiceFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkPracticeAnswer() async {
    FocusScope.of(context).unfocus();
    final isCorrect = checkModuleCaseAnswer(
      _practiceController.text,
      _practiceQuestion,
      language: widget.lang.name,
    );
    setState(() {
      _practiceCorrect = isCorrect;
      _practiceSaveError = null;
    });

    await ApiService.recordLocalExerciseAttempt(
      widget.lang.name,
      'module_${widget.category.name}_${widget.topicNumber}',
    );

    if (!isCorrect) return;

    try {
      final completedBefore =
          await ApiService.getModuleTopicCompletionCount(widget.lang.name);
      await ApiService.markModuleTopicCompleted(
        language: widget.lang.name,
        topicId: '${widget.category.name}_${widget.topicNumber}',
      );
      final completedAfter =
          await ApiService.getModuleTopicCompletionCount(widget.lang.name);
      if (completedBefore < 5 && completedAfter >= 5 && mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Practice unlocked!'),
            content: Text(
              'Questions 1–5 in ${widget.lang.name} practice mode are now unlocked.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('GOT IT'),
              ),
            ],
          ),
        );
      }
    } on Exception catch (error) {
      debugPrint('Could not save module topic completion: $error');
      if (!mounted) return;
      setState(() {
        _practiceSaveError =
            'Correct answer, but module progress could not be saved or checked. Please try again.';
      });
    }
  }

  void _resetPractice() {
    setState(() {
      _practiceController.clear();
      _practiceCorrect = null;
      _practiceSaveError = null;
    });
  }

  String get _topicLabel =>
      widget.topic.module.replaceFirst(RegExp(r'^Q\d+\s*//\s*'), '').trim();

  String get _topicDefinition {
    final label = _topicLabel.toUpperCase();
    if (label.contains('DEBUG')) {
      return 'Debugging is the process of finding and correcting mistakes in a program.';
    }
    if (label.contains('PRINT') || label.contains('OUTPUT')) {
      return 'Output instructions display text or values produced by a program.';
    }
    if (label.contains('VARIABLE')) {
      return 'A variable is a named place in a program for storing a value.';
    }
    if (label.contains('STRING')) {
      return 'A string is a sequence of characters used to represent text.';
    }
    if (label.contains('ARITHMETIC')) {
      return 'Arithmetic uses operators to calculate with numeric values.';
    }
    if (label.contains('IF') || label.contains('CONDITION')) {
      return 'Conditional statements let a program choose actions based on a test.';
    }
    if (label.contains('SWITCH')) {
      return 'A switch selects one action from several possible cases.';
    }
    if (label.contains('FOR LOOP') ||
        label.contains('WHILE') ||
        label == 'LOOP') {
      return 'A loop repeats a block of instructions while a rule allows it.';
    }
    if (label.contains('ARRAY') || label.contains('LIST')) {
      return 'An array or list stores multiple values together in an ordered collection.';
    }
    if (label.contains('FILE')) {
      return 'File handling lets a program read data from or write data to files.';
    }
    if (label.contains('OOP') ||
        label.contains('CLASS') ||
        label.contains('OBJECT')) {
      return 'Object-oriented programming organizes code around objects created from classes.';
    }
    if (label.contains('PROBLEM SOLVING')) {
      return 'Problem solving breaks a task into clear steps that a program can perform.';
    }
    if (label.contains('SELECT')) {
      return 'SELECT is the SQL command used to retrieve data from database tables.';
    }
    if (label.contains('INSERT')) {
      return 'INSERT is the SQL command used to add new rows to a database table.';
    }
    if (label.contains('UPDATE')) {
      return 'UPDATE is the SQL command used to change values in existing rows.';
    }
    if (label.contains('DELETE')) {
      return 'DELETE is the SQL command used to remove rows from a database table.';
    }
    if (label.contains('JOIN')) {
      return 'A JOIN combines related rows from two or more database tables.';
    }
    if (label.contains('GROUP')) {
      return 'GROUP BY collects rows with matching values into summary groups.';
    }
    if (label.contains('HAVING')) {
      return 'HAVING filters grouped results after aggregate calculations are made.';
    }
    if (label.contains('ORDER')) {
      return 'ORDER BY sorts query results using one or more columns.';
    }
    if (label.contains('LIMIT')) {
      return 'LIMIT restricts how many rows a query returns.';
    }
    if (label.contains('COUNT') || label.contains('AGGREGATE')) {
      return 'Aggregate functions calculate a summary value from a set of rows.';
    }
    if (label.contains('SUBQUERY')) {
      return 'A subquery is a query nested inside another SQL statement.';
    }
    if (label.contains('CASE')) {
      return 'A CASE expression evaluates conditions and returns a matching value.';
    }
    if (label.contains('WINDOW') || label.contains('PARTITION')) {
      return 'Window functions calculate values across related rows without combining them into one row.';
    }
    if (label.contains('CTE')) {
      return 'A common table expression (CTE) is a named temporary result used within a query.';
    }
    if (label.contains('STORED PROC')) {
      return 'A stored procedure is a reusable group of SQL statements saved in a database.';
    }
    if (label.contains('TRIGGER')) {
      return 'A trigger is database logic that runs automatically when a specified event occurs.';
    }
    if (label.contains('TRANSACTION')) {
      return 'A transaction groups database operations into one unit of work.';
    }
    if (label.contains('METHOD') || label.contains('FUNCTION')) {
      return 'A function or method is a reusable block of code that performs a task.';
    }
    return '$_topicLabel is a core programming concept used when writing ${widget.lang.name} programs.';
  }

  String get _topicPurpose {
    final label = _topicLabel.toUpperCase();
    if (label.contains('DEBUG')) {
      return 'It helps make code behave as intended and prevents errors from affecting results.';
    }
    if (label.contains('PRINT') || label.contains('OUTPUT')) {
      return 'It lets a program show results, messages, or other useful information to a user.';
    }
    if (label.contains('VARIABLE')) {
      return 'It keeps data available so the program can use or update it as it runs.';
    }
    if (label.contains('STRING')) {
      return 'It allows programs to store, display, compare, and transform text.';
    }
    if (label.contains('ARITHMETIC')) {
      return 'It is used to calculate totals, differences, averages, and other numeric results.';
    }
    if (label.contains('IF') ||
        label.contains('CONDITION') ||
        label.contains('SWITCH')) {
      return 'It makes program behavior respond to input or changing conditions.';
    }
    if (label.contains('LOOP') || label.contains('WHILE')) {
      return 'It avoids repeating the same instructions manually and processes repeated work.';
    }
    if (label.contains('ARRAY') || label.contains('LIST')) {
      return 'It makes collections of related data easier to access, update, and process.';
    }
    if (label.contains('FILE')) {
      return 'It allows programs to load information and save results beyond a single run.';
    }
    if (label.contains('OOP') ||
        label.contains('CLASS') ||
        label.contains('OBJECT')) {
      return 'It helps structure larger programs into reusable components that model related data and behavior.';
    }
    if (label.contains('PROBLEM SOLVING')) {
      return 'It helps turn a larger challenge into manageable steps and a reliable solution.';
    }
    if (label.contains('SELECT')) {
      return 'It retrieves the specific information an application or user needs.';
    }
    if (label.contains('INSERT')) {
      return 'It saves new information in a database.';
    }
    if (label.contains('UPDATE')) {
      return 'It keeps stored information accurate as data changes.';
    }
    if (label.contains('DELETE')) {
      return 'It removes records that are no longer needed.';
    }
    if (label.contains('JOIN')) {
      return 'It answers questions that depend on related data stored across tables.';
    }
    if (label.contains('GROUP') ||
        label.contains('HAVING') ||
        label.contains('AGGREGATE') ||
        label.contains('COUNT')) {
      return 'It summarizes data so patterns and totals are easier to understand.';
    }
    if (label.contains('ORDER')) {
      return 'It presents results in a useful order, such as newest first or highest to lowest.';
    }
    if (label.contains('LIMIT')) {
      return 'It returns only the requested number of results, which is useful for previews and pages.';
    }
    if (label.contains('SUBQUERY') || label.contains('CTE')) {
      return 'It breaks complex queries into smaller parts that are easier to read and reuse.';
    }
    if (label.contains('CASE')) {
      return 'It creates conditional values directly in query results.';
    }
    if (label.contains('WINDOW') || label.contains('PARTITION')) {
      return 'It supports rankings and comparisons while keeping each result row available.';
    }
    if (label.contains('STORED PROC')) {
      return 'It packages common database tasks so they can be run consistently and reused.';
    }
    if (label.contains('TRIGGER')) {
      return 'It automates follow-up actions and helps enforce rules when data changes.';
    }
    if (label.contains('TRANSACTION')) {
      return 'It helps keep related database changes consistent, succeeding or rolling back together.';
    }
    if (label.contains('METHOD') || label.contains('FUNCTION')) {
      return 'It reduces duplicated code and lets a task be called wherever it is needed.';
    }
    return 'It helps build clear, maintainable solutions to common ${widget.lang.name} programming tasks.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.clBg,
      appBar: AppBar(
        backgroundColor: context.clBg,
        foregroundColor: context.clTextPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Text(
          '${widget.lang.name} • ${widget.category.label}',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'TOPIC ${widget.topicNumber} OF ${widget.total}',
            style: GoogleFonts.sourceCodePro(
              color: widget.category.color,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _topicLabel,
            style: GoogleFonts.spaceGrotesk(
              color: context.clTextPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (widget.lang.name == 'Java' &&
              widget.category == QuizCategory.beginner &&
              widget.topic.title == 'Hello World') ...[
            const SizedBox(height: 12),
            _JavaIntroductionCard(color: widget.category.color),
          ],
          const SizedBox(height: 12),
          _TopicExplanationCard(
            categoryColor: widget.category.color,
            definition: _topicDefinition,
            purpose: _topicPurpose,
          ),
          const SizedBox(height: 16),
          Text(
            widget.topic.title,
            style: GoogleFonts.spaceGrotesk(
              color: context.clTextPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.clBgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.clBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.topic.description,
                  style: GoogleFonts.spaceGrotesk(
                    color: context.clTextSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.topic.explanation,
                  style: GoogleFonts.spaceGrotesk(
                    color: context.clTextSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                CodeBlock(
                  filename: widget.topic.filename,
                  code: widget.topic.correctAnswer,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildCasePractice(context),
          const SizedBox(height: 16),
          if (widget.onNext != null)
            CyanButton(
              label: 'NEXT TOPIC',
              icon: Icons.arrow_forward,
              onTap: widget.onNext!,
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCasePractice(BuildContext context) {
    final color = widget.category.color;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.clBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.code_rounded, color: color, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'CASE PRACTICE • ${widget.lang.name.toUpperCase()}',
                  style: GoogleFonts.sourceCodePro(
                    color: color,
                    fontSize: 11,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _practiceQuestion.description,
            style: GoogleFonts.spaceGrotesk(
              color: context.clTextSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _ProblemPreviewCard(
            sampleData: _practiceQuestion.sampleData,
            expectedOutput: _practiceQuestion.expectedOutput,
            accentColor: color,
          ),
          const SizedBox(height: 12),
          _CodeEditorWidget(
            ctrl: _practiceController,
            focusNode: _practiceFocusNode,
            filename: _practiceQuestion.filename,
            accentColor: color,
            language: widget.lang.name,
          ),
          const SizedBox(height: 12),
          _LiveOutputPreview(
            controller: _practiceController,
            language: widget.lang.name,
            question: _practiceQuestion,
            accentColor: color,
          ),
          if (_practiceCorrect != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_practiceCorrect!
                        ? SiklabColors.success
                        : SiklabColors.error)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (_practiceCorrect!
                          ? SiklabColors.success
                          : SiklabColors.error)
                      .withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                _practiceCorrect!
                    ? 'Correct! Your ${widget.lang.name} solution matches the case.'
                    : 'Not quite yet. Review the case and try again.',
                style: GoogleFonts.spaceGrotesk(
                  color: _practiceCorrect!
                      ? SiklabColors.success
                      : SiklabColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_practiceCorrect!) ...[
              if (_practiceSaveError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _practiceSaveError!,
                  style: GoogleFonts.spaceGrotesk(
                    color: SiklabColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'SAMPLE SOLUTION',
                style: GoogleFonts.sourceCodePro(
                  color: context.clTextMuted,
                  fontSize: 10,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              CodeBlock(
                filename: _practiceQuestion.filename,
                code: _practiceQuestion.correctAnswer,
              ),
            ],
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CyanButton(
                  label: 'CHECK ANSWER',
                  icon: Icons.check_circle_outline,
                  onTap: _checkPracticeAnswer,
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Reset answer',
                onPressed: _resetPractice,
                icon: Icon(Icons.refresh, color: context.clTextSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopicExplanationCard extends StatelessWidget {
  final Color categoryColor;
  final String definition;
  final String purpose;

  const _TopicExplanationCard({
    required this.categoryColor,
    required this.definition,
    required this.purpose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.clBgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.clBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHAT IT IS',
            style: GoogleFonts.sourceCodePro(
              color: categoryColor,
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            definition,
            style: GoogleFonts.spaceGrotesk(
              color: context.clTextSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'WHAT IT\'S FOR',
            style: GoogleFonts.sourceCodePro(
              color: categoryColor,
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            purpose,
            style: GoogleFonts.spaceGrotesk(
              color: context.clTextSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Overall language progress card ───────────────────────────────────────────

class _OverallProgressCard extends StatelessWidget {
  final double percent; // 0.0 – 1.0
  final int answered;
  final int total;
  final Color color;
  const _OverallProgressCard({
    required this.percent,
    required this.answered,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (percent * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.clBgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.clBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('YOUR PROGRESS',
                  style: GoogleFonts.sourceCodePro(
                      color: context.clTextMuted,
                      fontSize: 10,
                      letterSpacing: 2)),
              Text('$pct%',
                  style: GoogleFonts.spaceGrotesk(
                      color: color, fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: context.clBorder,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Text('$answered of $total exercises answered',
              style: GoogleFonts.spaceGrotesk(
                  color: context.clTextMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

// ─── Category card (with per-category progress) ────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final QuizCategory cat;
  final Color langColor;
  final Color bgCard, border, txtPri, txtSec;
  final int answeredCount;
  final int totalCount;
  final String countLabel;
  final bool isLocked;
  final String? lockedMessage;
  final Duration? totalTime;
  final Duration? perQuestionTime;
  final VoidCallback onTap;
  const _CategoryCard({
    required this.cat,
    required this.langColor,
    required this.bgCard,
    required this.border,
    required this.txtPri,
    required this.txtSec,
    required this.answeredCount,
    required this.totalCount,
    required this.countLabel,
    required this.isLocked,
    this.lockedMessage,
    this.totalTime,
    this.perQuestionTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = cat.color;
    final percent =
        totalCount == 0 ? 0.0 : (answeredCount / totalCount).clamp(0.0, 1.0);
    final pct = (percent * 100).round();
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isLocked ? bgCard.withValues(alpha: 0.65) : bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: isLocked ? 0.06 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: c.withValues(alpha: isLocked ? 0.15 : 0.3)),
                ),
                child: Icon(
                  isLocked ? Icons.lock_outline : cat.icon,
                  color: isLocked ? txtSec : c,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                            child: Text(cat.label,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.spaceGrotesk(
                                    color: isLocked ? txtSec : txtPri,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700))),
                        const SizedBox(width: 8),
                        _badge(cat.tag, c),
                      ]),
                      const SizedBox(height: 4),
                      Text(
                          lockedMessage ??
                              (isLocked
                                  ? 'Complete Beginner difficulty to unlock.'
                                  : cat.description),
                          style: GoogleFonts.spaceGrotesk(
                              color: txtSec, fontSize: 12, height: 1.4)),
                      if (totalTime != null && perQuestionTime != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          '${PracticeTimingService.formatDuration(totalTime!)} total · '
                          '${perQuestionTime!.inMinutes} min/question',
                          style: GoogleFonts.sourceCodePro(
                            color: isLocked ? txtSec : c,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                          '$answeredCount/$totalCount $countLabel • $pct% done',
                          style: GoogleFonts.sourceCodePro(
                              color: isLocked ? txtSec : c,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ]),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: isLocked ? 0.05 : 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  isLocked ? Icons.lock : Icons.arrow_forward_ios,
                  color: isLocked ? txtSec : c,
                  size: 13,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 5,
                backgroundColor: border,
                valueColor:
                    AlwaysStoppedAnimation<Color>(isLocked ? txtSec : c),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 3. QUESTION LIST
// ═════════════════════════════════════════════════════════════════════════════

class _QuestionListScreen extends StatelessWidget {
  final LanguageQuiz lang;
  final QuizCategory category;
  final List<QuizQuestion> questions;
  final VoidCallback onBack;
  final ValueChanged<int> onSelect;
  const _QuestionListScreen({
    required this.lang,
    required this.category,
    required this.questions,
    required this.onBack,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bg = context.clBg;
    final bgCard = context.clBgCard;
    final border = context.clBorder;
    final txtPri = context.clTextPrimary;
    final txtSec = context.clTextSecondary;
    final txtMut = context.clTextMuted;
    final cat = category;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: FutureBuilder<List<Set<String>>>(
          future: Future.wait([
            ApiService.getAnsweredQuestionIds(lang.name),
            ApiService.getCompletedModuleTopicIds(lang.name),
          ]),
          initialData: const [<String>{}, <String>{}],
          builder: (context, snapshot) {
            final answered = snapshot.data?[0] ?? const <String>{};
            final completedModuleTopics = snapshot.data?[1] ?? const <String>{};
            final answeredFlags = List.generate(
              questions.length,
              (i) => answered.contains('${cat.name}_${i + 1}'),
            );
            final hasFiveCompletedTopics = completedModuleTopics.length >= 5;
            final allLanguageTopicsCompleted = () {
              for (final entry in lang.categories.entries) {
                for (var i = 0; i < entry.value.length; i++) {
                  if (!completedModuleTopics
                      .contains('${entry.key.name}_${i + 1}')) {
                    return false;
                  }
                }
              }
              return true;
            }();
            final unlockedFlags = List.generate(questions.length, (i) {
              if (answeredFlags[i]) return true;
              if (i < 5) return hasFiveCompletedTopics;
              return allLanguageTopicsCompleted;
            });
            final answeredCount = answeredFlags.where((d) => d).length;
            final percent = questions.isEmpty
                ? 0.0
                : (answeredCount / questions.length).clamp(0.0, 1.0);
            final pct = (percent * 100).round();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          _backBtn(onBack, bgCard, border, txtSec),
                          const SizedBox(width: 14),
                          const SiklabLogo(),
                        ]),
                        const SizedBox(height: 20),
                        // combined lang + category header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: cat.color.withValues(alpha: 0.3)),
                          ),
                          child: Row(children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: lang.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child:
                                  Icon(lang.icon, color: lang.color, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  // FIX 2: Added Flexible so long lang name + badge don't overflow
                                  Flexible(
                                    child: Text(lang.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.spaceGrotesk(
                                            color: txtPri,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                  const SizedBox(width: 8),
                                  _badge(cat.label, cat.color),
                                ]),
                                Text(
                                    '${questions.length} QUESTIONS  •  ${cat.tag}',
                                    style: GoogleFonts.sourceCodePro(
                                        color: cat.color,
                                        fontSize: 10,
                                        letterSpacing: 1.5)),
                              ],
                            )),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        // ── progress card ──
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('YOUR PROGRESS',
                                      style: GoogleFonts.sourceCodePro(
                                          color: txtMut,
                                          fontSize: 10,
                                          letterSpacing: 2)),
                                  Text('$pct%',
                                      style: GoogleFonts.spaceGrotesk(
                                          color: cat.color,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: percent,
                                  minHeight: 7,
                                  backgroundColor: border,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(cat.color),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                  '$answeredCount of ${questions.length} answered',
                                  style: GoogleFonts.spaceGrotesk(
                                      color: txtMut, fontSize: 11)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Rule-based recommendation for this topic
                        RecommendationCard(lang: lang, category: category),
                        const SizedBox(height: 20),
                        Text('SELECT A QUESTION',
                            style: GoogleFonts.sourceCodePro(
                                color: txtMut, fontSize: 10, letterSpacing: 2)),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _QTile(
                          index: i,
                          question: questions[i],
                          lang: lang,
                          category: category,
                          answered: answeredFlags[i],
                          unlocked: unlockedFlags[i],
                          onTap: () => onSelect(i),
                        ),
                      ),
                      childCount: questions.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QTile extends StatelessWidget {
  final int index;
  final QuizQuestion question;
  final LanguageQuiz lang;
  final QuizCategory category;
  final bool answered;
  final bool unlocked;
  final VoidCallback onTap;
  const _QTile({
    required this.index,
    required this.question,
    required this.lang,
    required this.category,
    required this.answered,
    required this.unlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgCard = context.clBgCard;
    final border = context.clBorder;
    final txtPri = context.clTextPrimary;
    final c = category.color;
    final isLocked = !unlocked;

    return GestureDetector(
      onTap: isLocked
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Complete question $index first to unlock this one.',
                    style: GoogleFonts.sourceCodePro(fontSize: 12),
                  ),
                  backgroundColor: SiklabColors.error,
                ),
              );
            }
          : onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: answered
                  ? SiklabColors.success.withValues(alpha: 0.4)
                  : isLocked
                      ? border.withValues(alpha: 0.7)
                      : border),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: answered
                  ? SiklabColors.success.withValues(alpha: 0.12)
                  : isLocked
                      ? context.clTextMuted.withValues(alpha: 0.08)
                      : c.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: answered
                  ? const Icon(Icons.check_rounded,
                      color: SiklabColors.success, size: 20)
                  : isLocked
                      ? const Icon(Icons.lock_rounded,
                          color: Colors.white54, size: 18)
                      : Text((index + 1).toString().padLeft(2, "0"),
                          style: GoogleFonts.spaceGrotesk(
                              color: c,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(question.module,
                  style: GoogleFonts.sourceCodePro(
                      color: isLocked ? context.clTextMuted : c,
                      fontSize: 10,
                      letterSpacing: 1.2)),
              const SizedBox(height: 2),
              Text(question.title,
                  style: GoogleFonts.spaceGrotesk(
                      color: isLocked ? context.clTextMuted : txtPri,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ],
          )),
          if (answered)
            _badge('DONE', SiklabColors.success)
          else if (isLocked)
            _badge('LOCKED', context.clTextMuted)
          else
            Icon(Icons.chevron_right, color: context.clTextMuted, size: 20),
        ]),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 4. CHALLENGE FLOW  (editor → correction → confirm → next)
// ═════════════════════════════════════════════════════════════════════════════

class _ChallengeFlow extends StatefulWidget {
  final LanguageQuiz lang;
  final QuizCategory category;
  final QuizQuestion question;
  final int questionNumber;
  final int total;
  final VoidCallback onBack;
  final VoidCallback onNextOrFinish;
  final VoidCallback onTimeExpired;
  final bool isLast;

  const _ChallengeFlow({
    super.key,
    required this.lang,
    required this.category,
    required this.question,
    required this.questionNumber,
    required this.total,
    required this.onBack,
    required this.onNextOrFinish,
    required this.onTimeExpired,
    required this.isLast,
  });

  @override
  State<_ChallengeFlow> createState() => _ChallengeFlowState();
}

class _ChallengeFlowState extends State<_ChallengeFlow> {
  bool _submitted = false;
  int _recoVersion = 0; // bumped after an attempt is recorded → card reloads
  bool _isCorrect = false;
  bool _showHint = false;
  late final TextEditingController _ctrl;
  final _focusNode = FocusNode();
  Timer? _timer;
  DateTime? _deadline;
  int _remainingSeconds = 0;
  bool _timerReady = false;
  bool _timedOut = false;
  bool _timeoutHandling = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    _initializeTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeTimer() async {
    late final DateTime deadline;
    try {
      deadline = await PracticeTimingService.startOrResumeQuestion(
        language: widget.lang.name,
        category: widget.category,
        questionNumber: widget.questionNumber,
      );
    } on StateError {
      if (!mounted) return;
      setState(() {
        _timerReady = true;
        _timedOut = true;
      });
      widget.onTimeExpired();
      return;
    }
    if (!mounted) return;
    _deadline = deadline;
    _timerReady = true;
    if (!deadline.isAfter(DateTime.now())) {
      _expireQuestion();
      return;
    }
    _refreshRemainingTime();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshRemainingTime(),
    );
    setState(() {});
  }

  void _refreshRemainingTime() {
    final deadline = _deadline;
    if (deadline == null || _timedOut || _submitted) return;
    final difference = deadline.difference(DateTime.now());
    if (difference <= Duration.zero) {
      _timer?.cancel();
      _expireQuestion();
      return;
    }
    final remaining = (difference.inMilliseconds + 999) ~/ 1000;
    if (remaining != _remainingSeconds && mounted) {
      setState(() => _remainingSeconds = remaining);
      if (remaining <= 10) {
        unawaited(PracticeTimerSoundService.playCountdownTick());
      }
    }
  }

  Future<void> _expireQuestion() async {
    if (_timeoutHandling) return;
    _timeoutHandling = true;
    _timer?.cancel();
    unawaited(PracticeTimerSoundService.playTimeoutRing());
    await PracticeTimingService.expireQuestion(
      language: widget.lang.name,
      category: widget.category,
      questionNumber: widget.questionNumber,
    );
    if (!mounted) return;
    setState(() => _timedOut = true);
    widget.onTimeExpired();
  }

  int _elapsedSeconds() {
    final deadline = _deadline;
    if (deadline == null) return 1;
    final limit =
        PracticeTimingService.questionDuration(widget.category).inSeconds;
    return (limit - deadline.difference(DateTime.now()).inSeconds)
        .clamp(1, limit);
  }

  void _submit() {
    if (!_timerReady ||
        _timedOut ||
        _remainingSeconds <= 0 ||
        _deadline == null ||
        !_deadline!.isAfter(DateTime.now())) {
      if (_timerReady) _expireQuestion();
      return;
    }
    final content = _ctrl.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please provide an answer before submitting.',
            style: GoogleFonts.sourceCodePro(fontSize: 12),
          ),
          backgroundColor: SiklabColors.error,
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    _timer?.cancel();
    setState(() {
      _submitted = true;
      _isCorrect = checkAnswer(_ctrl.text, widget.question.correctAnswer,
          language: widget.lang.name);
    });
    _recordAttempt(_isCorrect);
  }

  Future<void> _recordAttempt(bool isCorrect) async {
    await PracticeTimingService.recordQuestionTime(
      language: widget.lang.name,
      category: widget.category,
      questionNumber: widget.questionNumber,
      elapsedSeconds: _elapsedSeconds(),
    );
    final userId = UserSession().dbId;
    if (userId == 0) return;

    // Recommendation engine, STEP 1: record the exercise result (learner,
    // language, topic, exercise, correctness, submission time).
    await AttemptHistory.record(
      userId: userId,
      language: widget.lang.name,
      category: widget.category.name,
      questionId: '${widget.category.name}_${widget.questionNumber}',
      isCorrect: isCorrect,
    );
    if (mounted) setState(() => _recoVersion++);

    await ApiService.submitQuizAttempt(
      userId: userId,
      language: widget.lang.name,
      category: widget.category.label,
      questionId: '${widget.category.name}_${widget.questionNumber}',
      topicName: widget.question.title,
      isCorrect: isCorrect,
      timeTakenSeconds: _elapsedSeconds(),
    );

    // Refresh profile to get updated statistics (runs while the user may be
    // answering the feedback question below, so it never delays the dialog).
    final profileRefresh = ApiService.getProfile(userId);

    // Every 10 correct answers, ask the AI-reliance check-in questions.
    if (isCorrect) await _maybeAskAiFeedback(userId);

    await profileRefresh;
  }

  /// AI-reliance check-in: appears after the learner has answered 10 practice
  /// questions correctly (and again at 20, 30 ...).
  Future<void> _maybeAskAiFeedback(int userId) async {
    final milestone = await AiFeedbackService.registerCorrectAnswer(
      userId: userId,
      language: widget.lang.name,
      questionId: '${widget.category.name}_${widget.questionNumber}',
    );
    if (milestone == null || !mounted) return;

    await showAiRelianceFeedback(
      context,
      lang: widget.lang,
      category: widget.category,
      userId: userId,
      correctCount: milestone,
    );
  }

  void _onContinue() => _showConfirmDialog();

  void _onRetry() {
    if (_deadline == null || !_deadline!.isAfter(DateTime.now())) {
      _expireQuestion();
      return;
    }
    setState(() {
      _submitted = false;
      _isCorrect = false;
      _showHint = false;
      _ctrl.clear();
    });
    _resumeQuestionTimer();
  }

  void _onBackToEditor() {
    if (_deadline == null || !_deadline!.isAfter(DateTime.now())) {
      _expireQuestion();
      return;
    }
    setState(() => _submitted = false);
    _resumeQuestionTimer();
  }

  void _resumeQuestionTimer() {
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshRemainingTime(),
    );
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (_) => _ConfirmDialog(
        lang: widget.lang,
        category: widget.category,
        isLast: widget.isLast,
        onConfirm: () async {
          await PracticeTimingService.completeQuestion(
            language: widget.lang.name,
            category: widget.category,
            questionNumber: widget.questionNumber,
          );
          if (!mounted) return;
          Navigator.of(context).pop();
          widget.onNextOrFinish();
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => !_timerReady
      ? const Scaffold(body: Center(child: CircularProgressIndicator()))
      : _timedOut
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _submitted
              ? _CorrectionScreen(
                  lang: widget.lang,
                  category: widget.category,
                  question: widget.question,
                  userAnswer: _ctrl.text,
                  isCorrect: _isCorrect,
                  questionNumber: widget.questionNumber,
                  total: widget.total,
                  recoVersion: _recoVersion,
                  onBack: _onBackToEditor,
                  onRetry: _onRetry,
                  onContinue: _onContinue,
                  isLast: widget.isLast,
                )
              : _EditorScreen(
                  lang: widget.lang,
                  category: widget.category,
                  question: widget.question,
                  questionNumber: widget.questionNumber,
                  total: widget.total,
                  ctrl: _ctrl,
                  focusNode: _focusNode,
                  showHint: _showHint,
                  onToggleHint: () => setState(() => _showHint = !_showHint),
                  onBack: widget.onBack,
                  onSubmit: _submit,
                  remainingSeconds: _remainingSeconds,
                );
}

class _ProblemPreviewCard extends StatelessWidget {
  final String sampleData;
  final String expectedOutput;
  final Color accentColor;

  const _ProblemPreviewCard({
    required this.sampleData,
    required this.expectedOutput,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SAMPLE DATA',
            style: GoogleFonts.sourceCodePro(
              color: accentColor,
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sampleData,
            style: GoogleFonts.spaceGrotesk(
              color: context.clTextSecondary,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'EXPECTED OUTPUT',
            style: GoogleFonts.sourceCodePro(
              color: accentColor,
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            expectedOutput,
            style: GoogleFonts.sourceCodePro(
              color: context.clTextPrimary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Editor ───────────────────────────────────────────────────────────────────

class _EditorScreen extends StatelessWidget {
  final LanguageQuiz lang;
  final QuizCategory category;
  final QuizQuestion question;
  final int questionNumber, total;
  final TextEditingController ctrl;
  final FocusNode focusNode;
  final bool showHint;
  final int remainingSeconds;
  final VoidCallback onToggleHint, onBack, onSubmit;

  const _EditorScreen({
    required this.lang,
    required this.category,
    required this.question,
    required this.questionNumber,
    required this.total,
    required this.ctrl,
    required this.focusNode,
    required this.showHint,
    required this.remainingSeconds,
    required this.onToggleHint,
    required this.onBack,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final bg = context.clBg;
    final bgCard = context.clBgCard;
    final border = context.clBorder;
    final txtPri = context.clTextPrimary;
    final txtSec = context.clTextSecondary;
    final txtMut = context.clTextMuted;
    final cat = category;
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    final isFinalMinute = remainingSeconds <= 60;
    final timerColor = isFinalMinute ? SiklabColors.error : cat.color;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(children: [
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: CustomScrollView(slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FIX 3: FittedBox(scaleDown) lets the logo shrink proportionally
                      // when space is tight — no overflow, no clipping, design intact.
                      Row(children: [
                        _backBtn(onBack, bgCard, border, txtSec),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: FittedBox(
                            alignment: Alignment.centerLeft,
                            fit: BoxFit.scaleDown,
                            child: SiklabLogo(),
                          ),
                        ),
                        _badge(lang.tag, lang.color),
                        const SizedBox(width: 6),
                        _badge(cat.tag, cat.color),
                        const SizedBox(width: 8),
                        const SiklabHamburgerMenu(),
                      ]),
                      const SizedBox(height: 16),
                      // progress
                      _progressBar(context, questionNumber, total, cat.color),
                      const SizedBox(height: 7),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('QUESTION $questionNumber OF $total',
                              style: GoogleFonts.sourceCodePro(
                                  color: txtMut,
                                  fontSize: 10,
                                  letterSpacing: 1.2)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'TIME LEFT',
                                style: GoogleFonts.sourceCodePro(
                                  color: timerColor,
                                  fontSize: isFinalMinute ? 10 : 9,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 180),
                                style: GoogleFonts.sourceCodePro(
                                  color: timerColor,
                                  fontSize: remainingSeconds <= 10
                                      ? 34
                                      : isFinalMinute
                                          ? 26
                                          : 12,
                                  fontWeight: FontWeight.w800,
                                ),
                                child: Text('$minutes:$seconds'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      CodeTag(text: question.module, color: cat.color),
                      const SizedBox(height: 10),
                      Text(question.title,
                          style: GoogleFonts.spaceGrotesk(
                              color: txtPri,
                              fontSize: 24,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      // description card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: border),
                        ),
                        child: Text(question.description,
                            style: GoogleFonts.spaceGrotesk(
                                color: txtSec, fontSize: 14, height: 1.55)),
                      ),
                      const SizedBox(height: 12),
                      _ProblemPreviewCard(
                        sampleData: question.sampleData,
                        expectedOutput: question.expectedOutput,
                        accentColor: cat.color,
                      ),
                      const SizedBox(height: 18),
                      // code editor
                      _CodeEditorWidget(
                        ctrl: ctrl,
                        focusNode: focusNode,
                        filename: question.filename,
                        accentColor: cat.color,
                        language: lang.name,
                      ),
                      const SizedBox(height: 12),
                      _LiveOutputPreview(
                        controller: ctrl,
                        language: lang.name,
                        question: question,
                        accentColor: cat.color,
                      ),
                      // hint
                      if (showHint) ...[
                        const SizedBox(height: 14),
                        _HintBox(
                          text: question.hint,
                          category: cat,
                          language: lang.name,
                          questionTitle: question.title,
                        ),
                      ],
                      const SizedBox(height: 110),
                    ],
                  ),
                ),
              ),
            ]),
          ),
          // sticky bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomBar(
              accentColor: cat.color,
              showHint: showHint,
              onToggleHint: onToggleHint,
              onSubmit: onSubmit,
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Code Editor ──────────────────────────────────────────────────────────────

class _CodeEditorWidget extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focusNode;
  final String filename;
  final Color accentColor;
  final String language;
  const _CodeEditorWidget({
    required this.ctrl,
    required this.focusNode,
    required this.filename,
    required this.accentColor,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1821),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.clBorder),
        boxShadow: [
          BoxShadow(color: accentColor.withValues(alpha: 0.07), blurRadius: 20)
        ],
      ),
      child: Column(children: [
        // title bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.clBorder))),
          child: Row(children: [
            _macDot(const Color(0xFFFF5F56)),
            const SizedBox(width: 5),
            _macDot(const Color(0xFFFFBD2E)),
            const SizedBox(width: 5),
            _macDot(const Color(0xFF27C93F)),
            const Spacer(),
            Text(filename,
                style: GoogleFonts.sourceCodePro(
                    color: context.clTextMuted, fontSize: 11)),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Copying is disabled in this app',
                      style: GoogleFonts.sourceCodePro(fontSize: 12)),
                  backgroundColor: context.clBgElevated,
                  duration: const Duration(seconds: 1),
                ));
              },
              child: Icon(Icons.copy_outlined,
                  color: context.clTextMuted, size: 15),
            ),
          ]),
        ),
        // editable area
        Padding(
          padding: const EdgeInsets.all(14),
          child: CodeAnswerField(
            controller: ctrl,
            focusNode: focusNode,
            language: language,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            style: GoogleFonts.sourceCodePro(
                color: context.clTextSecondary, fontSize: 13, height: 1.7),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              filled: false,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _macDot(Color c) => Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

class _LiveOutputPreview extends StatefulWidget {
  final TextEditingController controller;
  final String language;
  final QuizQuestion question;
  final Color accentColor;

  const _LiveOutputPreview({
    required this.controller,
    required this.language,
    required this.question,
    required this.accentColor,
  });

  @override
  State<_LiveOutputPreview> createState() => _LiveOutputPreviewState();
}

class _LiveOutputPreviewState extends State<_LiveOutputPreview> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onCodeChanged);
  }

  @override
  void didUpdateWidget(covariant _LiveOutputPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onCodeChanged);
      widget.controller.addListener(_onCodeChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onCodeChanged);
    super.dispose();
  }

  void _onCodeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final output = simulateCodeOutput(
      widget.controller.text,
      language: widget.language,
      question: widget.question,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1821),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.accentColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.play_arrow_rounded,
                  color: widget.accentColor, size: 16),
              const SizedBox(width: 6),
              Text(
                'LIVE OUTPUT',
                style: GoogleFonts.sourceCodePro(
                  color: widget.accentColor,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'SIMULATED',
                style: GoogleFonts.sourceCodePro(
                  color: context.clTextMuted,
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            output,
            style: GoogleFonts.sourceCodePro(
              color: context.clTextPrimary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Correction Screen ────────────────────────────────────────────────────────

class _CorrectionScreen extends StatelessWidget {
  final LanguageQuiz lang;
  final QuizCategory category;
  final QuizQuestion question;
  final String userAnswer;
  final bool isCorrect;
  final int questionNumber, total;
  final int recoVersion;
  final VoidCallback onBack, onRetry, onContinue;
  final bool isLast;

  const _CorrectionScreen({
    required this.lang,
    required this.category,
    required this.question,
    required this.userAnswer,
    required this.isCorrect,
    required this.questionNumber,
    required this.total,
    required this.recoVersion,
    required this.onBack,
    required this.onRetry,
    required this.onContinue,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final bg = context.clBg;
    final bgCard = context.clBgCard;
    final border = context.clBorder;
    final txtSec = context.clTextSecondary;
    final resultColor = isCorrect ? SiklabColors.success : SiklabColors.error;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(children: [
          CustomScrollView(slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FIX 3 (CorrectionScreen): same FittedBox scaleDown fix
                    Row(children: [
                      _backBtn(onBack, bgCard, border, txtSec),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: FittedBox(
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.scaleDown,
                          child: SiklabLogo(),
                        ),
                      ),
                      _badge(lang.tag, lang.color),
                      const SizedBox(width: 6),
                      _badge(category.tag, category.color),
                      const SizedBox(width: 8),
                      const SiklabHamburgerMenu(),
                    ]),
                    const SizedBox(height: 20),
                    // progress
                    _progressBar(
                        context, questionNumber, total, category.color),
                    const SizedBox(height: 5),
                    Text('QUESTION $questionNumber OF $total',
                        style: GoogleFonts.sourceCodePro(
                            color: context.clTextMuted,
                            fontSize: 10,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 20),

                    // ── Result banner ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: resultColor.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: resultColor.withValues(alpha: 0.4),
                            width: 1.5),
                      ),
                      child: Column(children: [
                        Icon(isCorrect ? Icons.check_circle : Icons.cancel,
                            color: resultColor, size: 50),
                        const SizedBox(height: 10),
                        Text(isCorrect ? 'CORRECT' : 'INCORRECT',
                            style: GoogleFonts.spaceGrotesk(
                                color: resultColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3)),
                        const SizedBox(height: 6),
                        Text(
                          isCorrect
                              ? 'Well done! Your logic is solid.'
                              : 'Not quite — check your work and try again.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                              color: txtSec, fontSize: 14, height: 1.4),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // ── Rule-based recommendation (STEP 5: display) ──
                    RecommendationCard(
                      lang: lang,
                      category: category,
                      version: recoVersion,
                      showTopic: true,
                    ),
                    const SizedBox(height: 22),

                    // ── Question recap ──
                    _label(context, 'QUESTION'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      child: Text(question.description,
                          style: GoogleFonts.spaceGrotesk(
                              color: txtSec, fontSize: 13, height: 1.5)),
                    ),
                    const SizedBox(height: 20),

                    // ── Your answer ──
                    _label(context, 'YOUR ANSWER'),
                    const SizedBox(height: 8),
                    _AnswerBlock(
                      code: userAnswer,
                      filename: question.filename,
                      borderColor:
                          isCorrect ? SiklabColors.success : SiklabColors.error,
                      isCorrect: isCorrect,
                    ),
                    const SizedBox(height: 20),

                    if (isCorrect) ...[
                      // ── Correct answer ──
                      _label(context, 'CORRECT ANSWER'),
                      const SizedBox(height: 8),
                      _AnswerBlock(
                        code: question.correctAnswer,
                        filename: question.filename,
                        borderColor: SiklabColors.success,
                        isCorrect: true,
                        showCheckIcon: true,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Explanation ──
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: SiklabColors.purple.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: SiklabColors.purple.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.auto_stories_outlined,
                                color: SiklabColors.purple, size: 16),
                            const SizedBox(width: 8),
                            Text('EXPLANATION',
                                style: GoogleFonts.sourceCodePro(
                                    color: SiklabColors.purple,
                                    fontSize: 10,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w700)),
                          ]),
                          const SizedBox(height: 10),
                          Text(question.explanation,
                              style: GoogleFonts.spaceGrotesk(
                                  color: txtSec, fontSize: 13, height: 1.6)),
                        ],
                      ),
                    ),
                    // Extra bottom padding — incorrect shows 2 buttons (taller bar)
                    SizedBox(height: isCorrect ? 110 : 160),
                  ],
                ),
              ),
            ),
          ]),
          // ── Bottom CTA ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: bg,
                border: Border(top: BorderSide(color: context.clBorder)),
              ),
              child: isCorrect
                  // ── CORRECT: show Continue / Finish ──
                  ? CyanButton(
                      label: isLast ? 'FINISH  ✓' : 'CONTINUE  →',
                      onTap: onContinue,
                    )
                  // ── INCORRECT: show Retry + back-to-list ──
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Primary — Retry
                        GestureDetector(
                          onTap: onRetry,
                          child: Container(
                            width: double.infinity,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  SiklabColors.error,
                                  Color(0xFFCC3A3A),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: SiklabColors.error
                                      .withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.refresh_rounded,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'TRY AGAIN',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Secondary — back to question list
                        GestureDetector(
                          onTap: onBack,
                          child: Container(
                            width: double.infinity,
                            height: 46,
                            decoration: BoxDecoration(
                              color: context.clBgElevated,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: context.clBorder),
                            ),
                            child: Center(
                              child: Text(
                                'BACK TO QUESTIONS',
                                style: GoogleFonts.spaceGrotesk(
                                  color: context.clTextSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Answer block (read-only) ─────────────────────────────────────────────────

class _AnswerBlock extends StatelessWidget {
  final String code, filename;
  final Color borderColor;
  final bool isCorrect;
  final bool showCheckIcon;
  const _AnswerBlock({
    required this.code,
    required this.filename,
    required this.borderColor,
    required this.isCorrect,
    this.showCheckIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1821),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: borderColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: borderColor.withValues(alpha: 0.08),
            border: Border(
                bottom: BorderSide(color: borderColor.withValues(alpha: 0.3))),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(children: [
            Icon(
                showCheckIcon
                    ? Icons.check_circle_outline
                    : Icons.person_outline,
                color: borderColor,
                size: 14),
            const SizedBox(width: 6),
            Text(filename,
                style: GoogleFonts.sourceCodePro(
                    color: borderColor, fontSize: 11)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: SizedBox(
            width: double.infinity,
            child: SecureSelectableText(code.trim(),
                style: GoogleFonts.sourceCodePro(
                    color: context.clTextSecondary, fontSize: 12, height: 1.7)),
          ),
        ),
      ]),
    );
  }
}

// ─── Confirm Dialog ───────────────────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  final LanguageQuiz lang;
  final QuizCategory category;
  final bool isLast;
  final VoidCallback onConfirm, onCancel;
  const _ConfirmDialog({
    required this.lang,
    required this.category,
    required this.isLast,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final c = category.color;
    final bgCard = context.clBgCard;
    final border = context.clBorder;
    final txtPri = context.clTextPrimary;
    final txtMut = context.clTextMuted;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: bgCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: c.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: c.withValues(alpha: 0.15),
                    blurRadius: 40,
                    spreadRadius: 4)
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: c.withValues(alpha: 0.35), width: 2),
                ),
                child: Icon(isLast ? Icons.flag_outlined : Icons.arrow_forward,
                    color: c, size: 28),
              ),
              const SizedBox(height: 18),
              Text(isLast ? 'Finish Quiz?' : 'Next Question?',
                  style: GoogleFonts.spaceGrotesk(
                      color: txtPri,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(
                isLast
                    ? 'You\'ve completed all 10 questions. Ready to finish?'
                    : 'Are you sure you want to proceed to the next question?',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                    color: txtMut, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              // Confirm
              GestureDetector(
                onTap: onConfirm,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient:
                        LinearGradient(colors: [c, c.withValues(alpha: 0.7)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: c.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Center(
                      child: Text(
                    isLast ? 'YES, FINISH' : 'YES, PROCEED',
                    style: GoogleFonts.spaceGrotesk(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8),
                  )),
                ),
              ),
              const SizedBox(height: 12),
              // Cancel
              GestureDetector(
                onTap: onCancel,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: context.clBgElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border),
                  ),
                  child: Center(
                      child: Text(
                    'STAY HERE',
                    style: GoogleFonts.spaceGrotesk(
                        color: context.clTextSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8),
                  )),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Bottom bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final Color accentColor;
  final bool showHint;
  final VoidCallback onToggleHint, onSubmit;
  const _BottomBar({
    required this.accentColor,
    required this.showHint,
    required this.onToggleHint,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: context.clBg,
        border: Border(top: BorderSide(color: context.clBorder)),
      ),
      child: Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: onSubmit,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [accentColor, accentColor.withValues(alpha: 0.7)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: accentColor.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Center(
                  child: Text('SUBMIT SOLUTION →',
                      style: GoogleFonts.spaceGrotesk(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5))),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onToggleHint,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: showHint ? SiklabColors.purple : context.clBgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: showHint ? SiklabColors.purple : context.clBorder),
            ),
            child: Icon(Icons.lightbulb_outline,
                color: showHint ? Colors.white : context.clTextMuted, size: 22),
          ),
        ),
      ]),
    );
  }
}

// ─── Hint box ─────────────────────────────────────────────────────────────────

class _HintBox extends StatelessWidget {
  final String text;
  final QuizCategory category;
  final String language;
  final String questionTitle;

  const _HintBox({
    required this.text,
    required this.category,
    required this.language,
    required this.questionTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SiklabColors.purple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SiklabColors.purple.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: SiklabColors.purple,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${category.label.toUpperCase()} • ${language.toUpperCase()} HINT',
                  style: GoogleFonts.sourceCodePro(
                    color: SiklabColors.purple,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  questionTitle,
                  style: GoogleFonts.spaceGrotesk(
                    color: context.clTextPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text.trim(),
                  softWrap: true,
                  style: GoogleFonts.sourceCodePro(
                    color: context.clTextSecondary,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

Widget _badge(String t, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(t,
          style: GoogleFonts.sourceCodePro(
              color: c,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1)),
    );

Widget _backBtn(VoidCallback onTap, Color bg, Color border, Color icon) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Icon(Icons.arrow_back, color: icon, size: 18),
      ),
    );

Widget _progressBar(
        BuildContext context, int current, int total, Color color) =>
    Row(
      children: List.generate(total, (i) {
        final done = i < current - 1;
        final active = i == current - 1;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 3),
            height: 4,
            decoration: BoxDecoration(
              color: done
                  ? color
                  : active
                      ? color.withValues(alpha: 0.45)
                      : context.clBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );

Widget _label(BuildContext context, String t) => Text(t,
    style: GoogleFonts.sourceCodePro(
        color: context.clTextMuted,
        fontSize: 10,
        letterSpacing: 2,
        fontWeight: FontWeight.w600));
