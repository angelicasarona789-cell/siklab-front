import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/quiz_data.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

/// "About Siklab" – explains what the app is and how it works.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String version = '2.4.0-stable';

  @override
  Widget build(BuildContext context) {
    final txtPri = context.clTextPrimary;
    final txtSec = context.clTextSecondary;
    final txtMut = context.clTextMuted;

    final languageCount = languageQuizzes.length;
    final levelCount = QuizCategory.values.length;
    var exerciseCount = 0;
    for (final lang in languageQuizzes) {
      for (final list in lang.categories.values) {
        exerciseCount += list.length;
      }
    }

    return Scaffold(
      backgroundColor: context.clBg,
      appBar: AppBar(
        backgroundColor: context.clBgCard,
        foregroundColor: txtPri,
        elevation: 0,
        title: Text('About Siklab',
            style: GoogleFonts.spaceGrotesk(
                color: txtPri, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          // ── Hero ──
          const Center(child: SiklabLogo(size: 28, tappable: false)),
          const SizedBox(height: 10),
          Center(
            child: Text('Interactive Programming Learning System',
                textAlign: TextAlign.center,
                style: GoogleFonts.sourceCodePro(
                    color: txtMut, fontSize: 11.5, letterSpacing: 1.2)),
          ),
          const SizedBox(height: 22),
          _card(
            context,
            child: Text(
              'Siklab is a mobile app that helps you learn programming by '
              'doing. You study short lessons, then practice by writing and '
              'fixing real code - with instant checking, hints and '
              'explanations - so you build the skills to read, write and '
              'correct code on your own.',
              style: GoogleFonts.spaceGrotesk(
                  color: txtPri, fontSize: 14, height: 1.6),
            ),
          ),
          const SizedBox(height: 14),

          // ── Quick numbers ──
          Row(children: [
            _stat(context, '$languageCount', 'LANGUAGES'),
            const SizedBox(width: 10),
            _stat(context, '$levelCount', 'LEVELS'),
            const SizedBox(width: 10),
            _stat(context, '$exerciseCount', 'EXERCISES'),
          ]),
          const SizedBox(height: 24),

          // ── What you can learn ──
          _heading(context, 'WHAT YOU CAN LEARN'),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final lang in languageQuizzes)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: lang.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: lang.color.withValues(alpha: 0.35)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(lang.icon, color: lang.color, size: 16),
                  const SizedBox(width: 6),
                  Text(lang.name,
                      style: GoogleFonts.spaceGrotesk(
                          color: txtPri,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
          ]),
          const SizedBox(height: 12),
          for (final level in QuizCategory.values) ...[
            _card(
              context,
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(level.icon, color: level.color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(level.label,
                          style: GoogleFonts.spaceGrotesk(
                              color: txtPri,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(level.description,
                          style: GoogleFonts.spaceGrotesk(
                              color: txtSec, fontSize: 12.5, height: 1.4)),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),

          // ── How it works ──
          _heading(context, 'HOW IT WORKS'),
          const SizedBox(height: 10),
          _step(context, 1, Icons.menu_book_outlined, 'Learn',
              'Go through short module lessons that explain each topic.'),
          _step(context, 2, Icons.code, 'Practice',
              'Solve hands-on coding exercises. Get instant feedback, hints '
                  'and explanations - and retry until it clicks.'),
          _step(context, 3, Icons.bar_chart_rounded, 'Track',
              'See your skill level, topic mastery, weak areas, coding '
                  'velocity and milestones on the Analytics page.'),
          _step(context, 4, Icons.insights_outlined, 'Get guidance',
              'After 5 attempts in a topic, Siklab recommends what to do '
                  'next: review the lesson, practice more, or move on.'),
          _step(context, 5, Icons.workspace_premium_outlined, 'Earn certificates',
              'Finish a language to earn its certificate, or finish every '
                  'language for the overall Certificate of Completion. '
                  'Download or print them from Settings.'),
          const SizedBox(height: 16),

          // ── Purpose ──
          _heading(context, 'OUR GOAL'),
          const SizedBox(height: 10),
          _card(
            context,
            child: Text(
              'Siklab is built to grow your independence as a programmer: '
              'understanding code, solving problems and fixing mistakes '
              'yourself. A short questionnaire that appears after every 10 '
              'correct practice answers helps track how much you rely on AI '
              'tools while you learn.',
              style: GoogleFonts.spaceGrotesk(
                  color: txtSec, fontSize: 13.5, height: 1.6),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('Siklab  |  Version $version',
                style: GoogleFonts.sourceCodePro(
                    color: txtMut, fontSize: 11, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _heading(BuildContext context, String text) => Text(text,
      style: GoogleFonts.sourceCodePro(
          color: context.clTextMuted, fontSize: 10, letterSpacing: 2));

  Widget _card(BuildContext context, {required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.clBgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.clBorder),
        ),
        child: child,
      );

  Widget _stat(BuildContext context, String value, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: context.clBgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.clBorder),
          ),
          child: Column(children: [
            Text(value,
                style: GoogleFonts.spaceGrotesk(
                    color: SiklabColors.cyan,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.sourceCodePro(
                    color: context.clTextMuted,
                    fontSize: 9.5,
                    letterSpacing: 1.5)),
          ]),
        ),
      );

  Widget _step(BuildContext context, int n, IconData icon, String title,
      String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _card(
        context,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: SiklabColors.cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: SiklabColors.cyan, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$n. $title',
                    style: GoogleFonts.spaceGrotesk(
                        color: context.clTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(text,
                    style: GoogleFonts.spaceGrotesk(
                        color: context.clTextSecondary,
                        fontSize: 12.5,
                        height: 1.45)),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
