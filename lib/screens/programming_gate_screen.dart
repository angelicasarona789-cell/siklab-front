import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../models/user_profile.dart';
import '../models/user_session.dart';
import '../services/api_service.dart';
import 'main_shell.dart';

/// Shown once after login — asks the user about their programming background.
class ProgrammingGateScreen extends StatefulWidget {
  const ProgrammingGateScreen({super.key});
  @override
  State<ProgrammingGateScreen> createState() => _ProgrammingGateScreenState();
}

class _ProgrammingGateScreenState extends State<ProgrammingGateScreen> {
  int _step = 0;
  final Map<String, int> _answers = {};

  @override
  void initState() {
    super.initState();
    _checkIfAssessmentCompleted();
  }

  Future<void> _checkIfAssessmentCompleted() async {
    // Wait a moment for UserSession to be properly initialized
    await Future.delayed(const Duration(milliseconds: 100));

    final userId = UserSession().dbId;
    debugPrint('ProgrammingGate: Checking assessment for userId: $userId');

    if (userId > 0) {
      // Double-check: load assessment completion status from SharedPreferences directly
      final prefs = await SharedPreferences.getInstance();
      final hasCompleted =
          prefs.getBool('assessment_completed_$userId') ?? false;

      debugPrint(
          'ProgrammingGate: Assessment completed status: $hasCompleted for user: $userId');

      // Also update UserSession with the loaded status
      UserSession().assessmentCompleted = hasCompleted;

      if (hasCompleted && mounted) {
        debugPrint(
            'ProgrammingGate: Assessment already completed, going to main shell');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      } else {
        debugPrint(
            'ProgrammingGate: Assessment not completed, showing questions');
      }
    } else {
      debugPrint('ProgrammingGate: No user ID found, showing assessment');
    }
  }

  static const _questions = <_AssessmentQuestion>[
    _AssessmentQuestion(
      id: 'experience',
      prompt: 'How much coding experience do you have?',
      options: [
        _Option(
            label: 'I code regularly.',
            sub: 'Comfortable solving problems daily.',
            icon: Icons.terminal_outlined,
            color: SiklabColors.success,
            score: 4),
        _Option(
            label: 'I know the basics.',
            sub: 'I can write simple programs.',
            icon: Icons.psychology_outlined,
            color: SiklabColors.cyan,
            score: 3),
        _Option(
            label: 'I have tried a little.',
            sub: 'I am still very early in learning.',
            icon: Icons.hearing_outlined,
            color: SiklabColors.orange,
            score: 2),
        _Option(
            label: 'I am completely new.',
            sub: 'This is my first time.',
            icon: Icons.school_outlined,
            color: SiklabColors.purple,
            score: 1),
      ],
    ),
    _AssessmentQuestion(
      id: 'logic',
      prompt: 'How confident are you in solving logic problems?',
      options: [
        _Option(
            label: 'Very confident',
            sub: 'I can break problems into steps.',
            icon: Icons.auto_graph,
            color: SiklabColors.success,
            score: 4),
        _Option(
            label: 'Somewhat confident',
            sub: 'I solve easier problems.',
            icon: Icons.trending_up,
            color: SiklabColors.cyan,
            score: 3),
        _Option(
            label: 'Not confident yet',
            sub: 'I need guided examples.',
            icon: Icons.help_outline,
            color: SiklabColors.orange,
            score: 2),
        _Option(
            label: 'I do not know where to start',
            sub: 'I need beginner support.',
            icon: Icons.explore_outlined,
            color: SiklabColors.purple,
            score: 1),
      ],
    ),
    _AssessmentQuestion(
      id: 'goal',
      prompt: 'What is your primary learning goal?',
      options: [
        _Option(
            label: 'Software development career',
            sub: 'Build strong fundamentals for jobs.',
            icon: Icons.work_outline,
            color: SiklabColors.cyan,
            score: 4),
        _Option(
            label: 'School projects',
            sub: 'Improve grades and assignments.',
            icon: Icons.school_outlined,
            color: SiklabColors.success,
            score: 3),
        _Option(
            label: 'Personal projects',
            sub: 'Create apps or automations.',
            icon: Icons.lightbulb_outline,
            color: SiklabColors.orange,
            score: 2),
        _Option(
            label: 'Just exploring',
            sub: 'I am trying coding for the first time.',
            icon: Icons.travel_explore,
            color: SiklabColors.purple,
            score: 1),
      ],
    ),
    _AssessmentQuestion(
      id: 'time',
      prompt: 'How much time can you practice each week?',
      options: [
        _Option(
            label: '8+ hours',
            sub: 'I can commit heavily.',
            icon: Icons.timer_outlined,
            color: SiklabColors.success,
            score: 4),
        _Option(
            label: '4-7 hours',
            sub: 'Steady weekly progress.',
            icon: Icons.schedule,
            color: SiklabColors.cyan,
            score: 3),
        _Option(
            label: '1-3 hours',
            sub: 'Light but consistent.',
            icon: Icons.timelapse,
            color: SiklabColors.orange,
            score: 2),
        _Option(
            label: '< 1 hour',
            sub: 'Very limited schedule.',
            icon: Icons.hourglass_bottom,
            color: SiklabColors.purple,
            score: 1),
      ],
    ),
  ];

  Future<void> _proceed() async {
    final gateQuestion = _questions.first;
    final gateScore = _answers[gateQuestion.id] ?? 1;
    final gateLabel = gateScore >= 4
        ? 'Yes — I code regularly.'
        : gateScore >= 3
            ? 'A little — I know the basics.'
            : gateScore >= 2
                ? 'I\'ve heard of it.'
                : 'No idea — completely new.';
    UserProfile()
      ..setGateAnswer(gateLabel)
      ..setAssessmentAnswers(_answers);

    final userId = UserSession().dbId;
    if (userId != 0) {
      await UserProfile().saveAssessment(userId);
      final exp = _answers['experience'] ?? 0;
      final logic = _answers['logic'] ?? 0;
      final goalScore = _answers['goal'] ?? 0;
      final time = _answers['time'] ?? 0;
      final goalLabel = goalScore >= 4
          ? 'Software development career'
          : goalScore >= 3
              ? 'School projects'
              : goalScore >= 2
                  ? 'Personal projects'
                  : 'Just exploring';
      await ApiService.saveAssessment(
        userId: userId,
        experienceLevelScore: exp,
        logicConfidenceScore: logic,
        learningGoal: goalLabel,
        weeklyTimeScore: time,
      );
      // Mark assessment as completed both in session and local storage
      UserSession().assessmentCompleted = true;
      await UserSession().saveAssessmentCompleted();
      await ApiService.markAssessmentCompleted(userId);
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  Future<void> _skipAssessment() async {
    // Mark assessment as completed WITHOUT saving answers
    final userId = UserSession().dbId;
    if (userId != 0) {
      UserSession().assessmentCompleted = true;
      await UserSession().saveAssessmentCompleted();
      await ApiService.markAssessmentCompleted(userId);
      debugPrint('ProgrammingGate: Assessment skipped for user: $userId');
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = context.clBg;
    final border = context.clBorder;
    final txtPri = context.clTextPrimary;
    final txtMut = context.clTextMuted;

    final question = _questions[_step];
    final selected = _answers[question.id];

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Logo + Menu ──
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SiklabLogo(tappable: false),
                        SiklabHamburgerMenu(),
                      ],
                    ),
                    const SizedBox(height: 36),

                    // ── Icon badge ──
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: SiklabColors.cyan.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: SiklabColors.cyan.withValues(alpha: 0.35),
                              width: 2),
                          boxShadow: [
                            BoxShadow(
                                color:
                                    SiklabColors.cyan.withValues(alpha: 0.15),
                                blurRadius: 24,
                                spreadRadius: 4),
                          ],
                        ),
                        child: const Icon(Icons.code_outlined,
                            color: SiklabColors.cyan, size: 34),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        '// INIT_ASSESSMENT',
                        style: GoogleFonts.sourceCodePro(
                            color: txtMut, fontSize: 11, letterSpacing: 2),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Question ──
                    Text(
                      question.prompt,
                      style: GoogleFonts.spaceGrotesk(
                        color: txtPri,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This helps us personalise your learning path.',
                      style: GoogleFonts.spaceGrotesk(
                          color: txtMut, fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 28),

                    // ── Options ──
                    ...question.options.map((opt) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _OptionTile(
                            option: opt,
                            isSelected: selected == opt.score,
                            onTap: () => setState(
                                () => _answers[question.id] = opt.score),
                            border: border,
                          ),
                        )),

                    const Spacer(),

                    // ── CTA ──
                    if (selected == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Center(
                          child: Text(
                            'Select an option to continue',
                            style: GoogleFonts.sourceCodePro(
                                color: txtMut, fontSize: 11, letterSpacing: 1),
                          ),
                        ),
                      ),
                    _ProceedBtn(
                      enabled: selected != null,
                      label: _step == _questions.length - 1
                          ? 'ENTER DASHBOARD →'
                          : 'NEXT QUESTION →',
                      onTap: selected == null
                          ? null
                          : () {
                              if (_step == _questions.length - 1) {
                                _proceed();
                              } else {
                                setState(() => _step += 1);
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    // ── Skip Assessment Button ──
                    GestureDetector(
                      onTap: _skipAssessment,
                      child: Center(
                        child: Text(
                          'SKIP FOR NOW',
                          style: GoogleFonts.sourceCodePro(
                            color: txtMut,
                            fontSize: 11,
                            letterSpacing: 1.5,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Option data ──────────────────────────────────────────────────────────────

class _Option {
  final String label;
  final String sub;
  final IconData icon;
  final Color color;
  final int score;
  const _Option({
    required this.label,
    required this.sub,
    required this.icon,
    required this.color,
    required this.score,
  });
}

class _AssessmentQuestion {
  final String id;
  final String prompt;
  final List<_Option> options;
  const _AssessmentQuestion({
    required this.id,
    required this.prompt,
    required this.options,
  });
}

// ─── Option tile ──────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final _Option option;
  final bool isSelected;
  final VoidCallback onTap;
  final Color border;
  const _OptionTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final bgCard = context.clBgCard;
    final txtPri = context.clTextPrimary;
    final txtSec = context.clTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? option.color.withValues(alpha: 0.08) : bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? option.color.withValues(alpha: 0.65) : border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: option.color.withValues(alpha: 0.12),
                      blurRadius: 14,
                      spreadRadius: 1)
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: option.color.withValues(alpha: isSelected ? 0.18 : 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(option.icon, color: option.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: GoogleFonts.spaceGrotesk(
                      color: isSelected ? option.color : txtPri,
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    option.sub,
                    style: GoogleFonts.spaceGrotesk(
                        color: txtSec, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? Icon(Icons.check_circle,
                      color: option.color, size: 22, key: const ValueKey(1))
                  : Icon(Icons.radio_button_unchecked,
                      color: border, size: 22, key: const ValueKey(0)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Proceed button ───────────────────────────────────────────────────────────

class _ProceedBtn extends StatelessWidget {
  final bool enabled;
  final String label;
  final VoidCallback? onTap;
  const _ProceedBtn({
    required this.enabled,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFF00CFFF), Color(0xFF0099CC)])
              : null,
          color: enabled ? null : context.clBgCard,
          borderRadius: BorderRadius.circular(14),
          border: enabled ? null : Border.all(color: context.clBorder),
          boxShadow: enabled
              ? [
                  BoxShadow(
                      color: SiklabColors.cyan.withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 5))
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: enabled ? context.clBg : context.clTextMuted,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
