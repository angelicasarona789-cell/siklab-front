import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bg = context.clBg;
    final bgElev = context.clBgElevated;
    final border = context.clBorder;
    final txtPri = context.clTextPrimary;
    final txtSec = context.clTextSecondary;
    final txtMut = context.clTextMuted;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // PRO MODE top bar
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
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
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      '// PROCESS_COMPLETED',
                      style: GoogleFonts.sourceCodePro(
                        color: txtMut,
                        fontSize: 11,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Score
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFE066FF), Color(0xFFB57BFF)],
                      ).createShader(bounds),
                      child: Text(
                        '90/100',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 72,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Logic execution successful.',
                      style: GoogleFonts.spaceGrotesk(
                        color: txtSec,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Accuracy card
                    _MetricCard(
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
                                    'Accuracy',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: txtPri,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Precision Metrics',
                                    style: GoogleFonts.sourceCodePro(
                                      color: txtMut,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(Icons.verified_outlined,
                                  color: SiklabColors.cyan, size: 22),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                '92%',
                                style: GoogleFonts.spaceGrotesk(
                                  color: txtPri,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '+4.2% from last session',
                                style: GoogleFonts.sourceCodePro(
                                  color: SiklabColors.success,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: 0.92,
                              backgroundColor: border,
                              valueColor: const AlwaysStoppedAnimation(
                                  SiklabColors.cyan),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Execution time
                    _MetricCard(
                      child: Column(
                        children: [
                          const Icon(Icons.monitor_heart_outlined,
                              color: SiklabColors.orange, size: 28),
                          const SizedBox(height: 8),
                          Text(
                            'Execution Time',
                            style: GoogleFonts.spaceGrotesk(
                              color: SiklabColors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '04:22',
                            style: GoogleFonts.spaceGrotesk(
                              color: txtPri,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'OPTIMAL RANGE REACHED',
                            style: GoogleFonts.sourceCodePro(
                              color: txtMut,
                              fontSize: 10,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Stats row
                    _MetricCard(
                      child: Column(
                        children: [
                          _statRow(context, Icons.code, 'Lines: 142'),
                          const SizedBox(height: 10),
                          _statRow(context, Icons.bug_report_outlined,
                              'Bugs Fixed: 0'),
                          const SizedBox(height: 10),
                          _statRow(context, Icons.bolt, 'Complexity: O(n)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // XP card
                    _MetricCard(
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: SiklabColors.purple, width: 3),
                              color: bgElev,
                            ),
                            child: Center(
                              child: Text(
                                'LV\n14',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.spaceGrotesk(
                                  color: txtPri,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ALGORITHM MASTERY',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: txtPri,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '240 XP until next module unlock',
                                  style: GoogleFonts.sourceCodePro(
                                    color: txtMut,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: 0.65,
                                    backgroundColor: border,
                                    valueColor: const AlwaysStoppedAnimation(
                                        SiklabColors.purple),
                                    minHeight: 4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    CyanButton(
                      label: 'Continue',
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 12),
                    CyanButton(
                      label: 'Review Code',
                      onTap: () => Navigator.pop(context),
                      outlined: true,
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: context.clTextMuted, size: 18),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.sourceCodePro(
            color: context.clTextSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final Widget child;
  const _MetricCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.clBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.clBorder),
      ),
      child: child,
    );
  }
}
