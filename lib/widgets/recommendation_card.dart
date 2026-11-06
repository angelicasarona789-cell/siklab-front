import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/quiz_data.dart';
import '../models/user_session.dart';
import '../services/recommendation_service.dart';
import '../theme/app_theme.dart';

Color recommendationColor(RecommendationRule rule) {
  switch (rule) {
    case RecommendationRule.needsImprovement:
      return SiklabColors.error;
    case RecommendationRule.moderatePerformance:
      return SiklabColors.orange;
    case RecommendationRule.goodPerformance:
      return SiklabColors.success;
    case RecommendationRule.insufficientData:
      return SiklabColors.cyan;
  }
}

IconData recommendationIcon(RecommendationRule rule) {
  switch (rule) {
    case RecommendationRule.needsImprovement:
      return Icons.menu_book_outlined;
    case RecommendationRule.moderatePerformance:
      return Icons.fitness_center_outlined;
    case RecommendationRule.goodPerformance:
      return Icons.trending_up_rounded;
    case RecommendationRule.insufficientData:
      return Icons.hourglass_empty_rounded;
  }
}

/// STEP 5 – displays the recommendation for one language + level.
/// Change [version] to make the card reload (e.g. after a new attempt).
class RecommendationCard extends StatelessWidget {
  final LanguageQuiz lang;
  final QuizCategory category;
  final int version;
  final bool showTopic; // show "Java · Beginner" above the message
  const RecommendationCard({
    super.key,
    required this.lang,
    required this.category,
    this.version = 0,
    this.showTopic = false,
  });

  @override
  Widget build(BuildContext context) {
    final userId = UserSession().dbId;
    if (userId <= 0) return const SizedBox.shrink();

    return FutureBuilder<Recommendation>(
      key: ValueKey('reco_${lang.name}_${category.name}_$version'),
      future: RecommendationEngine.forTopic(
          userId: userId, lang: lang, category: category),
      builder: (context, snapshot) {
        final reco = snapshot.data;
        if (reco == null) return const SizedBox.shrink();
        return RecommendationPanel(
          reco: reco,
          topicLabel: showTopic ? '${lang.name} · ${category.label}' : null,
        );
      },
    );
  }
}

class RecommendationPanel extends StatelessWidget {
  final Recommendation reco;
  final String? topicLabel;
  const RecommendationPanel({super.key, required this.reco, this.topicLabel});

  @override
  Widget build(BuildContext context) {
    final c = recommendationColor(reco.rule);
    final txtSec = context.clTextSecondary;
    final txtMut = context.clTextMuted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(recommendationIcon(reco.rule), color: c, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text('// RECOMMENDATION',
                  style: GoogleFonts.sourceCodePro(
                      color: txtMut, fontSize: 10, letterSpacing: 2)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(reco.rule.status,
                  style: GoogleFonts.sourceCodePro(
                      color: c,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
            ),
          ]),
          if (topicLabel != null) ...[
            const SizedBox(height: 10),
            Text(topicLabel!,
                style: GoogleFonts.spaceGrotesk(
                    color: context.clTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 10),
          Text(reco.message,
              style: GoogleFonts.spaceGrotesk(
                  color: context.clTextPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.45)),
          const SizedBox(height: 12),
          Row(children: [
            // Up to 5 most recent submissions, oldest → newest.
            for (var i = 0; i < RecommendationEngine.windowSize; i++)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _dot(context, i),
              ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                reco.accuracy == null
                    ? '${reco.attempts}/${RecommendationEngine.windowSize} submissions'
                    : 'Latest ${reco.attempts} submissions: '
                        '${reco.correct}/${reco.attempts} '
                        'correct (${reco.accuracy!.round()}%)',
                style: GoogleFonts.sourceCodePro(color: txtSec, fontSize: 11),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            'Based on up to ${RecommendationEngine.windowSize} recent '
            'submissions for this topic. Retries count as separate attempts.',
            style: GoogleFonts.spaceGrotesk(color: txtMut, fontSize: 10.5),
          ),
          const SizedBox(height: 6),
          Text(reco.rule.label,
              style: GoogleFonts.spaceGrotesk(color: txtMut, fontSize: 10.5)),
        ],
      ),
    );
  }

  Widget _dot(BuildContext context, int slot) {
    // reco.recent is newest-first; show oldest on the left.
    final oldestFirst = reco.recent.reversed.toList();
    final offset = RecommendationEngine.windowSize - oldestFirst.length;
    final idx = slot - offset;
    Color color;
    if (idx < 0) {
      color = context.clBorder;
    } else {
      color = oldestFirst[idx] ? SiklabColors.success : SiklabColors.error;
    }
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
