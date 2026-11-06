import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/quiz_data.dart';
import '../services/ai_feedback_service.dart';
import '../theme/app_theme.dart';

/// AI-reliance check-in on the Practice page. It appears after the learner has
/// answered 10 practice questions correctly (and again at 20, 30 ...).
/// The first answered check-in is the learner's baseline; later ones are
/// compared against it. [correctCount] is the milestone just reached.
Future<void> showAiRelianceFeedback(
  BuildContext context, {
  required LanguageQuiz lang,
  required QuizCategory category,
  required int userId,
  required int correctCount,
}) async {
  final hasBaseline = await AiFeedbackService.getBaselineIndex(userId) != null;
  if (!context.mounted) return;

  final accent = category.color;
  final answers = await showDialog<List<int>>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    builder: (_) => _QuestionnaireDialog(
      accent: accent,
      tag: '// CHECK_IN',
      title: '$correctCount correct answers!',
      intro: hasBaseline
          ? 'Nice work! Thinking about how you work with AI now, please '
              'answer the same short questions again.'
          : 'Great start! Please answer a few honest questions about how you '
              'usually use AI when learning or writing code. You will see '
              'these same questions after every $correctCount more correct '
              'answers, so you can see how your habits change.',
    ),
  );

  final outcome = await AiFeedbackService.saveCheckpoint(
    userId: userId,
    correctCount: correctCount,
    language: lang.name,
    categoryLabel: category.label,
    answers: answers,
  );

  final index = outcome.index;
  if (index == null) return; // skipped
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    builder: (_) => _ResultDialog(
      accent: accent,
      index: index,
      baseline: outcome.baseline,
      isBaseline: outcome.isBaseline,
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// Questionnaire (one question per step)
// ═════════════════════════════════════════════════════════════════════════════

class _QuestionnaireDialog extends StatefulWidget {
  final Color accent;
  final String tag;
  final String title;
  final String intro;
  const _QuestionnaireDialog({
    required this.accent,
    required this.tag,
    required this.title,
    required this.intro,
  });

  @override
  State<_QuestionnaireDialog> createState() => _QuestionnaireDialogState();
}

class _QuestionnaireDialogState extends State<_QuestionnaireDialog> {
  final List<int?> _answers =
      List<int?>.filled(AiFeedbackService.questions.length, null);
  int _step = -1; // -1 = intro screen, 0..3 = questions

  bool get _isLast => _step == AiFeedbackService.questions.length - 1;

  void _next() {
    if (_isLast) {
      Navigator.of(context).pop(_answers.map((a) => a!).toList());
    } else {
      setState(() => _step++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.accent;
    final bgCard = context.clBgCard;
    final border = context.clBorder;
    final txtPri = context.clTextPrimary;
    final txtSec = context.clTextSecondary;
    final txtMut = context.clTextMuted;
    final total = AiFeedbackService.questions.length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: c.withValues(alpha: 0.15),
                blurRadius: 40,
                spreadRadius: 4),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.tag,
                  style: GoogleFonts.sourceCodePro(
                      color: txtMut, fontSize: 10, letterSpacing: 1.5)),
              const SizedBox(height: 2),
              Text(widget.title,
                  style: GoogleFonts.spaceGrotesk(
                      color: txtPri,
                      fontSize: 19,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              if (_step == -1) ..._introContent(txtSec, c) else ..._questionContent(
                  total, c, txtPri, txtSec, txtMut, border),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _introContent(Color txtSec, Color c) {
    return [
      Text(widget.intro,
          style: GoogleFonts.spaceGrotesk(
              color: txtSec, fontSize: 13.5, height: 1.5)),
      const SizedBox(height: 8),
      Text(
        'It takes about 30 seconds: ${AiFeedbackService.questions.length} '
        'short questions. There are no right or wrong answers.',
        style: GoogleFonts.spaceGrotesk(
            color: txtSec, fontSize: 12.5, height: 1.5),
      ),
      const SizedBox(height: 20),
      _PrimaryButton(
          label: 'START', accent: c, enabled: true, onTap: () => setState(() => _step = 0)),
      const SizedBox(height: 10),
      _SecondaryButton(
        label: 'SKIP',
        onTap: () => Navigator.of(context).pop(),
      ),
    ];
  }

  List<Widget> _questionContent(int total, Color c, Color txtPri, Color txtSec,
      Color txtMut, Color border) {
    final q = AiFeedbackService.questions[_step];
    final selected = _answers[_step];

    return [
      Row(children: [
        Text('QUESTION ${_step + 1} OF $total',
            style: GoogleFonts.sourceCodePro(
                color: c, fontSize: 11, letterSpacing: 1.5)),
        const Spacer(),
        if (_step > 0)
          GestureDetector(
            onTap: () => setState(() => _step--),
            child: Text('BACK',
                style: GoogleFonts.sourceCodePro(
                    color: txtSec, fontSize: 11, letterSpacing: 1.5)),
          ),
      ]),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: (_step + 1) / total,
          minHeight: 4,
          backgroundColor: border,
          valueColor: AlwaysStoppedAnimation<Color>(c),
        ),
      ),
      const SizedBox(height: 18),
      Text(q.text,
          style: GoogleFonts.spaceGrotesk(
              color: txtPri,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.4)),
      const SizedBox(height: 14),
      for (var i = 0; i < q.scale.length; i++)
        _OptionTile(
          level: i + 1,
          label: q.scale[i],
          selected: selected == i + 1,
          accent: c,
          onTap: () => setState(() => _answers[_step] = i + 1),
        ),
      const SizedBox(height: 14),
      _PrimaryButton(
        label: _isLast ? 'SUBMIT' : 'NEXT',
        accent: c,
        enabled: selected != null,
        onTap: _next,
      ),
      const SizedBox(height: 10),
      _SecondaryButton(
        label: 'SKIP',
        onTap: () => Navigator.of(context).pop(),
      ),
    ];
  }
}

class _OptionTile extends StatelessWidget {
  final int level;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  const _OptionTile({
    required this.level,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.12)
                : context.clBgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : context.clBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? accent : context.clTextMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.spaceGrotesk(
                      color: context.clTextPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600)),
            ),
            Text('$level',
                style: GoogleFonts.sourceCodePro(
                    color: context.clTextMuted, fontSize: 11)),
          ]),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final Color accent;
  final bool enabled;
  final VoidCallback onTap;
  const _PrimaryButton({
    required this.label,
    required this.accent,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1 : 0.4,
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            gradient:
                LinearGradient(colors: [accent, accent.withValues(alpha: 0.7)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8)),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SecondaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 46,
        decoration: BoxDecoration(
          color: context.clBgElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.clBorder),
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.spaceGrotesk(
                  color: context.clTextSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8)),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Result – current score vs. baseline
// ═════════════════════════════════════════════════════════════════════════════

class _ResultDialog extends StatelessWidget {
  final Color accent;
  final double index;
  final double? baseline;
  final bool isBaseline;
  const _ResultDialog({
    required this.accent,
    required this.index,
    required this.baseline,
    required this.isBaseline,
  });

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final txtPri = context.clTextPrimary;
    final txtSec = context.clTextSecondary;
    final txtMut = context.clTextMuted;
    final change = baseline == null ? null : index - baseline!;

    String summary;
    Color changeColor = txtSec;
    if (isBaseline) {
      summary = 'This is your starting point. SIKLAB will compare your next '
          'check-ins with it.';
    } else if (change == null) {
      summary = 'No baseline was recorded, so there is nothing to compare yet.';
    } else if (change < -0.05) {
      summary = 'Your self-reported AI reliance is lower than at your baseline.';
      changeColor = SiklabColors.success;
    } else if (change > 0.05) {
      summary = 'Your self-reported AI reliance is higher than at your baseline.';
      changeColor = SiklabColors.orange;
    } else {
      summary = 'Your self-reported AI reliance is the same as at your baseline.';
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.clBgCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('// YOUR_AI_RELIANCE',
                style: GoogleFonts.sourceCodePro(
                    color: txtMut, fontSize: 10, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_fmt(index),
                  style: GoogleFonts.spaceGrotesk(
                      color: txtPri,
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      height: 1)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('/ 100',
                    style: GoogleFonts.spaceGrotesk(
                        color: txtMut, fontSize: 14)),
              ),
            ]),
            const SizedBox(height: 4),
            Text('Lower score = less reliance on AI',
                style: GoogleFonts.spaceGrotesk(color: txtMut, fontSize: 12)),
            const SizedBox(height: 16),
            if (baseline != null) ...[
              Text(
                'Baseline: ${_fmt(baseline!)}   |   Change: '
                '${change! > 0 ? '+' : ''}${_fmt(change)}',
                style: GoogleFonts.sourceCodePro(
                    color: changeColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
            ],
            Text(summary,
                style: GoogleFonts.spaceGrotesk(
                    color: txtSec, fontSize: 13, height: 1.45)),
            const SizedBox(height: 8),
            Text(
              'This is based on your own answers and shows change over time, '
              'not what caused it.',
              style: GoogleFonts.spaceGrotesk(
                  color: txtMut, fontSize: 11.5, height: 1.45),
            ),
            const SizedBox(height: 20),
            _PrimaryButton(
              label: 'CONTINUE',
              accent: accent,
              enabled: true,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
