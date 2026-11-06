import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/api_service.dart';
import 'auth_screen.dart';
import 'main_shell.dart';
import 'programming_gate_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _current = 0;

  // 3 orientation slides only
  static const int _totalSlides = 3;

  bool get _isFinalSlide => _current == _totalSlides - 1;
  bool get _canAdvance => true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Check if user is already logged in
    final savedId = await ApiService.getSavedUserId();
    if (savedId != null && savedId > 0) {
      debugPrint('OnboardingScreen: User already logged in with ID: $savedId');
      // Try to load user data
      final result = await ApiService.getProfile(savedId);
      if (result.success && mounted) {
        final needsAssessment =
            await ApiService.requiresInitialAssessment(savedId);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => needsAssessment
                ? const ProgrammingGateScreen()
                : const MainShell(),
          ),
        );
      } else if (mounted) {
        // Be very conservative about clearing saved ID - only clear on explicit auth failures
        final isAuthError = result.message.toLowerCase().contains('invalid') ||
            result.message.toLowerCase().contains('unauthorized') ||
            result.message.toLowerCase().contains('not found') ||
            result.message.toLowerCase().contains('expired');

        if (isAuthError) {
          debugPrint(
              'OnboardingScreen: Clearing saved ID due to auth error: ${result.message}');
          await ApiService.logout();
        } else {
          // Network/server error - proceed to main shell anyway
          debugPrint(
              'OnboardingScreen: Network/server error, keeping saved ID: ${result.message}');
          final needsAssessment =
              await ApiService.requiresInitialAssessment(savedId);
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => needsAssessment
                  ? const ProgrammingGateScreen()
                  : const MainShell(),
            ),
          );
        }
      }
    }
  }

  void _next() {
    if (!_canAdvance) return;
    if (_isFinalSlide) {
      _goToAuth();
    } else {
      _controller.nextPage(
          duration: const Duration(milliseconds: 380), curve: Curves.easeInOut);
    }
  }

  void _goToAuth() => Navigator.of(context)
      .pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SiklabColors.bg,
      body: Stack(
        children: [
          CustomPaint(painter: _GridPainter(), size: Size.infinite),
          SafeArea(
            child: Column(
              children: [
                // ── top bar ──
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SiklabLogo(tappable: false),
                      GestureDetector(
                        onTap: _goToAuth,
                        child: Text(
                          'SKIP',
                          style: GoogleFonts.sourceCodePro(
                              color: SiklabColors.textMuted,
                              fontSize: 12,
                              letterSpacing: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── pages ──
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (i) => setState(() {
                      _current = i;
                    }),
                    children: const [
                      _InfoPage(slide: _slide0),
                      _InfoPage(slide: _slide1),
                      _InfoPage(slide: _slide2),
                    ],
                  ),
                ),
                // ── dots + CTA ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_totalSlides, (i) {
                          final active = i == _current;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 22 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: active
                                  ? SiklabColors.cyan
                                  : SiklabColors.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 18),
                      _isFinalSlide
                          ? CyanButton(label: 'Get Started', onTap: _next)
                          : CyanButton(label: 'NEXT STEP →', onTap: _next),
                    ],
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

// ─── Slide data ───────────────────────────────────────────────────────────────

const _slide0 = _Slide(
  tag: 'SLIDE 1 OF 3 — INTRODUCTION',
  title: 'Practice programming fundamentals',
  accent: 'programming\nfundamentals',
  body:
      'Strengthen your core logic with interactive exercises designed for technical precision.',
  visual: _CodeVisual(),
);

const _slide1 = _Slide(
  tag: 'SLIDE 2 OF 3 — ANALYSIS',
  title: 'Identify weak areas and improve.',
  accent: 'and improve.',
  body:
      'Track your growth across different topics and focus on what matters most for your career.',
  visual: _AnalyticsVisual(),
  topVisual: true,
  bullets: [
    'Real-time skill proficiency mapping',
    'Personalized daily focus recommendations',
    'Career-aligned growth benchmarking',
  ],
);

const _slide2 = _Slide(
  tag: 'SLIDE 3 OF 3 — PHILOSOPHY',
  title: 'Think, do not rely on generated code.',
  accent: 'generated code.',
  body:
      'Master the logic behind the code. Build deep understanding through hands-on practice.',
  visual: _ThinkVisual(),
  quote:
      '/* The most powerful tool in your tech stack is your own mental model. */',
);

class _Slide {
  final String tag;
  final String title;
  final String accent;
  final String body;
  final Widget visual;
  final List<String>? bullets;
  final String? quote;
  final bool topVisual;
  const _Slide({
    required this.tag,
    required this.title,
    required this.accent,
    required this.body,
    required this.visual,
    this.bullets,
    this.quote,
    this.topVisual = false,
  });
}

// ─── Info page ────────────────────────────────────────────────────────────────

class _InfoPage extends StatelessWidget {
  final _Slide slide;
  const _InfoPage({required this.slide});

  @override
  Widget build(BuildContext context) {
    final visualH = MediaQuery.of(context).size.height * 0.30;
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: slide.topVisual ? 4 : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: slide.topVisual
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          SizedBox(height: slide.topVisual ? 0 : 12),
          SizedBox(
            height: visualH,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: slide.visual,
            ),
          ),
          const SizedBox(height: 24),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.spaceGrotesk(
                  color: SiklabColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1.25),
              children: _buildTitle(slide.title, slide.accent),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
                color: SiklabColors.textSecondary, fontSize: 14, height: 1.6),
          ),
          if (slide.bullets != null) ...[
            const SizedBox(height: 16),
            ...slide.bullets!.map((b) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                            color: SiklabColors.purple.withValues(alpha: 0.2),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.check,
                            color: SiklabColors.purple, size: 12),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(b,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceGrotesk(
                                color: SiklabColors.textSecondary,
                                fontSize: 13)),
                      ),
                    ],
                  ),
                )),
          ],
          if (slide.quote != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SiklabColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: SiklabColors.cyan.withValues(alpha: 0.35)),
              ),
              child: Text(
                slide.quote!,
                textAlign: TextAlign.center,
                style: GoogleFonts.sourceCodePro(
                    color: SiklabColors.textMuted, fontSize: 12, height: 1.6),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(slide.tag,
              textAlign: TextAlign.center,
              style: GoogleFonts.sourceCodePro(
                  color: SiklabColors.textMuted,
                  fontSize: 10,
                  letterSpacing: 1.5)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  List<TextSpan> _buildTitle(String title, String accent) {
    final idx = title.indexOf(accent);
    if (idx < 0) return [TextSpan(text: title)];
    return [
      if (idx > 0) TextSpan(text: title.substring(0, idx)),
      TextSpan(
          text: accent,
          style: GoogleFonts.spaceGrotesk(
              color: SiklabColors.cyan,
              fontSize: 26,
              fontWeight: FontWeight.w700)),
      if (idx + accent.length < title.length)
        TextSpan(text: title.substring(idx + accent.length)),
    ];
  }
}

// ─── Question Page ────────────────────────────────────────────────────────────
// ignore: unused_element
class _QuestionPage extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  const _QuestionPage({required this.selected, required this.onSelect});

  static const _options = [
    _Option('Yes, I know the basics.', Icons.thumb_up_outlined,
        SiklabColors.success),
    _Option('A little bit.', Icons.psychology_outlined, SiklabColors.cyan),
    _Option('I\'ve heard of it.', Icons.hearing_outlined, SiklabColors.orange),
    _Option('No idea — I\'m starting fresh.', Icons.school_outlined,
        SiklabColors.purple),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          // Visual
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.22,
            decoration: BoxDecoration(
              color: SiklabColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SiklabColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: SiklabColors.cyan.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: SiklabColors.cyan.withValues(alpha: 0.35),
                        width: 2),
                  ),
                  child: const Icon(Icons.help_outline,
                      color: SiklabColors.cyan, size: 30),
                ),
                const SizedBox(height: 12),
                Text('// INIT_ASSESSMENT',
                    style: GoogleFonts.sourceCodePro(
                        color: SiklabColors.textMuted,
                        fontSize: 11,
                        letterSpacing: 2)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          // Question
          Text(
            'Do you have any idea about\nwhat programming is?',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
                color: SiklabColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1.25),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us personalise your\nlearning experience.',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
                color: SiklabColors.textMuted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 22),
          // Options
          ..._options.map((opt) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OptionTile(
                  option: opt,
                  isSelected: selected == opt.label,
                  onTap: () => onSelect(opt.label),
                ),
              )),
          if (selected == null) ...[
            const SizedBox(height: 6),
            Text('Select an option to continue',
                style: GoogleFonts.sourceCodePro(
                    color: SiklabColors.textMuted,
                    fontSize: 11,
                    letterSpacing: 1)),
          ],
          const SizedBox(height: 8),
          Text('SLIDE 4 OF 4 — INIT_ASSESSMENT',
              style: GoogleFonts.sourceCodePro(
                  color: SiklabColors.textMuted,
                  fontSize: 10,
                  letterSpacing: 1.5)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Option {
  final String label;
  final IconData icon;
  final Color color;
  const _Option(this.label, this.icon, this.color);
}

class _OptionTile extends StatelessWidget {
  final _Option option;
  final bool isSelected;
  final VoidCallback onTap;
  const _OptionTile(
      {required this.option, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? option.color.withValues(alpha: 0.1)
              : SiklabColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? option.color.withValues(alpha: 0.7)
                : SiklabColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: option.color.withValues(alpha: 0.15),
                      blurRadius: 12,
                      spreadRadius: 1)
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: option.color.withValues(alpha: isSelected ? 0.2 : 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(option.icon, color: option.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                option.label,
                style: GoogleFonts.spaceGrotesk(
                  color: isSelected ? option.color : SiklabColors.textSecondary,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? Icon(Icons.check_circle,
                      color: option.color, size: 20, key: const ValueKey(1))
                  : const Icon(Icons.radio_button_unchecked,
                      color: SiklabColors.border, size: 20, key: ValueKey(0)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Conditional Next Button (disabled until answered) ───────────────────────
// ignore: unused_element
class _NextBtn extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _NextBtn(
      {required this.label, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFF00CFFF), Color(0xFF0099CC)])
              : null,
          color: enabled ? null : SiklabColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: enabled ? null : Border.all(color: SiklabColors.border),
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
              color: enabled ? SiklabColors.bg : SiklabColors.textMuted,
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

// ─── Visuals ──────────────────────────────────────────────────────────────────

class _CodeVisual extends StatelessWidget {
  const _CodeVisual();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: SiklabColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SiklabColors.border),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // code snippet label above icon
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: SiklabColors.bgElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: SiklabColors.border),
                ),
                child: Text('while (logic = true) {',
                    style: GoogleFonts.sourceCodePro(
                        color: SiklabColors.cyan, fontSize: 10)),
              ),
              const SizedBox(height: 14),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    color: SiklabColors.cyan,
                    borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.code, color: Colors.black, size: 34),
              ),
              const SizedBox(height: 12),
              Text('system.initialize();',
                  style: GoogleFonts.sourceCodePro(
                      color: SiklabColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              Container(
                width: 70,
                height: 2,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [SiklabColors.cyan, Colors.transparent]),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsVisual extends StatelessWidget {
  const _AnalyticsVisual();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SiklabColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SiklabColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('// PERFORMANCE_METRICS',
              style: GoogleFonts.sourceCodePro(
                  color: SiklabColors.purple, fontSize: 9, letterSpacing: 1.5)),
          Text('Growth Velocity',
              style: GoogleFonts.spaceGrotesk(
                  color: SiklabColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [60.0, 75.0, 55.0, 100.0, 80.0, 70.0, 85.0]
                  .map((v) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Container(
                            decoration: BoxDecoration(
                              color: v == 100
                                  ? SiklabColors.purple
                                  : SiklabColors.bgElevated,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            height: (v / 100) * 60,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            _stat('LOGIC FLOW', '92%', '+4.2%', SiklabColors.cyan),
            const SizedBox(width: 10),
            _stat('SYNTAX', '64%', '-1.5%', SiklabColors.orange),
          ]),
        ],
      ),
    );
  }

  Widget _stat(String l, String v, String d, Color c) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              border: Border(left: BorderSide(color: c, width: 2))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l,
                style: GoogleFonts.sourceCodePro(
                    color: SiklabColors.textMuted,
                    fontSize: 8,
                    letterSpacing: 1)),
            Row(children: [
              Text(v,
                  style: GoogleFonts.spaceGrotesk(
                      color: SiklabColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              Text(d,
                  style: GoogleFonts.sourceCodePro(
                      color: SiklabColors.textMuted, fontSize: 9)),
            ]),
          ]),
        ),
      );
}

class _ThinkVisual extends StatelessWidget {
  const _ThinkVisual();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: SiklabColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SiklabColors.border),
      ),
      child: Stack(
        children: [
          // hex badge top-right
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: SiklabColors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SiklabColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('0x1F4A1',
                      style: GoogleFonts.sourceCodePro(
                          color: SiklabColors.textSecondary, fontSize: 10)),
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: SiklabColors.pink, shape: BoxShape.circle),
                  ),
                ],
              ),
            ),
          ),
          // centred brain icon
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: SiklabColors.bgElevated,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: SiklabColors.cyan.withValues(alpha: 0.3),
                          width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: SiklabColors.cyan.withValues(alpha: 0.1),
                            blurRadius: 20,
                            spreadRadius: 4)
                      ],
                    ),
                    child: const Icon(Icons.psychology_outlined,
                        color: SiklabColors.cyan, size: 36),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: SiklabColors.bgElevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: SiklabColors.border),
                    ),
                    child: Text('// Think_Deep',
                        style: GoogleFonts.sourceCodePro(
                            color: SiklabColors.textSecondary, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _TerminalVisual extends StatelessWidget {
  const _TerminalVisual();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1821),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SiklabColors.border),
      ),
      // ── Use mainAxisSize.min so Column never tries to be taller than its
      //    children; no Spacer — use fixed SizedBox gaps instead. ──
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title bar
          Row(children: [
            _dot(const Color(0xFFFF5F56)),
            const SizedBox(width: 5),
            _dot(const Color(0xFFFFBD2E)),
            const SizedBox(width: 5),
            _dot(const Color(0xFF27C93F)),
            const Spacer(),
            Flexible(
                child: Text('ENGINE_INIT.SH',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sourceCodePro(
                        color: SiklabColors.textMuted, fontSize: 9))),
          ]),
          const SizedBox(height: 10),
          // command line — use overflow ellipsis to be safe
          Text(
            r'$ siklab --deploy --env production',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.sourceCodePro(
                color: SiklabColors.textPrimary, fontSize: 11),
          ),
          const SizedBox(height: 3),
          Text(
            'Initializing core logic sequence...',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.sourceCodePro(
                color: SiklabColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 14),
          // rocket centred
          const Center(
            child:
                Icon(Icons.rocket_launch, color: SiklabColors.cyan, size: 34),
          ),
          const SizedBox(height: 14),
          // SUCCESS line — Expanded text so it never wraps outside the box
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SUCCESS: ',
                style: GoogleFonts.sourceCodePro(
                    color: SiklabColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: Text(
                  'System primed. Ready for ignition.',
                  softWrap: true,
                  style: GoogleFonts.sourceCodePro(
                      color: SiklabColors.textSecondary, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // cursor
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text('_',
                style: GoogleFonts.sourceCodePro(
                    color: SiklabColors.textPrimary, fontSize: 13)),
            Container(
                width: 9,
                height: 15,
                color: SiklabColors.cyan.withValues(alpha: 0.8)),
          ]),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

// ─── Background grid ──────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SiklabColors.border.withValues(alpha: 0.35)
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
