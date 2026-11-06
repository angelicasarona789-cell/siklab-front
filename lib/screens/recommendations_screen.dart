import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/quiz_data.dart';
import '../models/user_session.dart';
import '../services/recommendation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/recommendation_card.dart';

/// Lists the rule-based recommendation for every language and level.
class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  late final Future<Map<String, Recommendation>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, Recommendation>> _load() async {
    final userId = UserSession().dbId;
    final out = <String, Recommendation>{};
    for (final lang in languageQuizzes) {
      for (final cat in lang.categories.keys) {
        out['${lang.name}|${cat.name}'] = await RecommendationEngine.forTopic(
            userId: userId, lang: lang, category: cat);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.clBg,
      appBar: AppBar(
        backgroundColor: context.clBgCard,
        foregroundColor: context.clTextPrimary,
        elevation: 0,
        title: Text('Learning Recommendations',
            style: GoogleFonts.spaceGrotesk(
                color: context.clTextPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
      ),
      body: FutureBuilder<Map<String, Recommendation>>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Based on up to 5 recent submitted answers in each topic. '
                'Each retry counts as a separate attempt. '
                'Below 60% → review the lesson, 60-79% → practice more, '
                '80% or higher → move on. Fewer than 5 attempts → keep '
                'practicing first.',
                style: GoogleFonts.spaceGrotesk(
                    color: context.clTextSecondary,
                    fontSize: 12.5,
                    height: 1.5),
              ),
              const SizedBox(height: 20),
              for (final lang in languageQuizzes) ...[
                Row(children: [
                  Icon(lang.icon, color: lang.color, size: 20),
                  const SizedBox(width: 8),
                  Text(lang.name,
                      style: GoogleFonts.spaceGrotesk(
                          color: context.clTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 10),
                for (final cat in lang.categories.keys) ...[
                  RecommendationPanel(
                    reco: data['${lang.name}|${cat.name}']!,
                    topicLabel: cat.label,
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 14),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Summary card for the Analytics page
// ═════════════════════════════════════════════════════════════════════════════

class _TopicReco {
  final LanguageQuiz lang;
  final QuizCategory category;
  final Recommendation reco;
  const _TopicReco(this.lang, this.category, this.reco);
}

Future<List<_TopicReco>> _loadAllTopicRecos(int userId) async {
  final out = <_TopicReco>[];
  for (final lang in languageQuizzes) {
    for (final cat in lang.categories.keys) {
      out.add(_TopicReco(
        lang,
        cat,
        await RecommendationEngine.forTopic(
            userId: userId, lang: lang, category: cat),
      ));
    }
  }
  return out;
}

/// Compact "Learning Recommendations" card for the Analytics page: shows the
/// topics that most need attention (Rule 1 first, then Rule 2, then Rule 3)
/// and links to the full list. Change [version] to make it reload.
class RecommendationsSummaryCard extends StatelessWidget {
  final int version;
  const RecommendationsSummaryCard({super.key, this.version = 0});

  static const int _maxShown = 3;

  @override
  Widget build(BuildContext context) {
    final userId = UserSession().dbId;
    final txtPri = context.clTextPrimary;
    final txtSec = context.clTextSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.clBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.clBorder),
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
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: SiklabColors.cyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.insights_outlined,
                  color: SiklabColors.cyan, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Learning Recommendations',
                      style: GoogleFonts.spaceGrotesk(
                          color: txtPri,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('What to review, practice or tackle next',
                      style: GoogleFonts.sourceCodePro(
                          color: txtSec, fontSize: 12, letterSpacing: 0.5)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),
          if (userId <= 0)
            _note(context, 'Log in to see your recommendations.')
          else
            FutureBuilder<List<_TopicReco>>(
              key: ValueKey('reco_summary_$version'),
              future: _loadAllTopicRecos(userId),
              builder: (context, snapshot) {
                final all = snapshot.data;
                if (all == null) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: SiklabColors.cyan),
                      ),
                    ),
                  );
                }

                // Topics that already have a performance-based result, most
                // urgent first (Rule 1, Rule 2, Rule 3; lowest accuracy first).
                final ready = all
                    .where((t) =>
                        t.reco.rule != RecommendationRule.insufficientData)
                    .toList()
                  ..sort((a, b) {
                    final byRule =
                        a.reco.rule.index.compareTo(b.reco.rule.index);
                    if (byRule != 0) return byRule;
                    return (a.reco.accuracy ?? 0)
                        .compareTo(b.reco.accuracy ?? 0);
                  });

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ready.isEmpty)
                      _note(
                        context,
                        'Complete at least 5 exercises in a topic (a language '
                        'and level, like Java - Beginner) and SIKLAB will '
                        'recommend what to do next.',
                      )
                    else
                      for (final t in ready.take(_maxShown)) ...[
                        RecommendationPanel(
                          reco: t.reco,
                          topicLabel: '${t.lang.name} · ${t.category.label}',
                        ),
                        const SizedBox(height: 10),
                      ],
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const RecommendationsScreen()),
                      ),
                      child: Container(
                        width: double.infinity,
                        height: 46,
                        decoration: BoxDecoration(
                          color: context.clBgElevated,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.clBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('VIEW ALL RECOMMENDATIONS',
                                style: GoogleFonts.spaceGrotesk(
                                    color: txtPri,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8)),
                            const SizedBox(width: 6),
                            Icon(Icons.chevron_right,
                                color: context.clTextMuted, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _note(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text,
            style: GoogleFonts.spaceGrotesk(
                color: context.clTextSecondary, fontSize: 13, height: 1.5)),
      );
}
