// lib/screens/settings_screen.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/secure_text_field.dart';
import '../models/user_session.dart';
import '../models/quiz_data.dart';
import '../services/api_service.dart';
import '../services/certificate_service.dart';
import '../services/fullscreen_interruption_service.dart';
import 'certificate_screen.dart';
import 'about_screen.dart';
import 'auth_screen.dart';
import 'feedback_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = SiklabThemeScope.of(context);
    final isDark = themeNotifier.isDark;
    final bg = context.clBg;
    final bgCard = context.clBgCard;
    final border = context.clBorder;
    final txtPri = context.clTextPrimary;
    final txtSec = context.clTextSecondary;
    final txtMut = context.clTextMuted;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 24),
              Row(children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: SiklabColors.cyan, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('SYSTEM CONFIG',
                    style: GoogleFonts.sourceCodePro(
                        color: SiklabColors.cyan,
                        fontSize: 11,
                        letterSpacing: 2)),
              ]),
              const SizedBox(height: 6),
              Text('System Settings',
                  style: GoogleFonts.spaceGrotesk(
                      color: txtPri,
                      fontSize: 28,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 28),

              // ── VISUAL INTERFACE ──────────────────────────────
              _sectionLabel('VISUAL INTERFACE', txtMut),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => themeNotifier.toggle(),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border),
                  ),
                  child: Row(children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: SiklabColors.purple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isDark
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                        color: SiklabColors.purple,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isDark ? 'Dark Mode' : 'Light Mode',
                              style: GoogleFonts.spaceGrotesk(
                                  color: txtPri,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                          Text(
                            isDark
                                ? 'Optimized for low-light environments'
                                : 'Optimized for bright environments',
                            style: GoogleFonts.spaceGrotesk(
                                color: txtMut, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isDark,
                      onChanged: (v) => themeNotifier.setDark(v),
                      activeThumbColor: SiklabColors.cyan,
                      activeTrackColor:
                          SiklabColors.cyan.withValues(alpha: 0.3),
                      inactiveThumbColor: SiklabColors.orange,
                      inactiveTrackColor:
                          SiklabColors.orange.withValues(alpha: 0.2),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 20),

              // ── USER IDENTITY ─────────────────────────────────
              _sectionLabel('USER IDENTITY', txtMut),
              const SizedBox(height: 10),
              _SettingsTile(
                icon: Icons.person_outline,
                iconColor: SiklabColors.pink,
                title: 'Edit Profile',
                subtitle: 'Update display name, email or password',
                trailing: Icon(Icons.chevron_right, color: txtMut, size: 20),
                bgCard: bgCard,
                border: border,
                txtPri: txtPri,
                txtMut: txtMut,
                onTap: () => _showEditProfile(context, bgCard, border),
              ),
              const SizedBox(height: 20),

              // ── FEEDBACK ──────────────────────────────────────
              _sectionLabel('FEEDBACK', txtMut),
              const SizedBox(height: 10),
              _SettingsTile(
                icon: Icons.feedback_outlined,
                iconColor: SiklabColors.cyan,
                title: 'Send Feedback',
                subtitle: 'Share an opinion or report an issue',
                trailing: Icon(Icons.chevron_right, color: txtMut, size: 20),
                bgCard: bgCard,
                border: border,
                txtPri: txtPri,
                txtMut: txtMut,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                ),
              ),
              const SizedBox(height: 20),

              // ── SESSION INTEGRITY ─────────────────────────────
              if (defaultTargetPlatform == TargetPlatform.windows) ...[
                _sectionLabel('SESSION INTEGRITY', txtMut),
                const SizedBox(height: 10),
                _SettingsTile(
                  icon: Icons.fullscreen_exit,
                  iconColor: SiklabColors.orange,
                  title: 'Fullscreen Event Log',
                  subtitle: 'Review local focus-loss warnings',
                  trailing: Icon(Icons.chevron_right, color: txtMut, size: 20),
                  bgCard: bgCard,
                  border: border,
                  txtPri: txtPri,
                  txtMut: txtMut,
                  onTap: () => _showFullscreenInterruptionLog(context),
                ),
                const SizedBox(height: 20),
              ],

              // ── ACHIEVEMENTS ──────────────────────────────────
              _sectionLabel('ACHIEVEMENTS', txtMut),
              const SizedBox(height: 10),
              _CertificatesSection(
                bgCard: bgCard,
                border: border,
                txtPri: txtPri,
                txtMut: txtMut,
              ),
              const SizedBox(height: 20),

              // ── DATA MANAGEMENT ───────────────────────────────
              _sectionLabel('DATA MANAGEMENT', txtMut),
              const SizedBox(height: 10),
              _SettingsTile(
                icon: Icons.storage_outlined,
                iconColor: SiklabColors.orange,
                title: 'Reset Progress',
                subtitle: 'Clear practice history and stats on this device',
                trailing: Icon(Icons.refresh, color: txtMut, size: 20),
                bgCard: bgCard,
                border: border,
                txtPri: txtPri,
                txtMut: txtMut,
                onTap: () =>
                    _showResetProgressConfirm(context, bgCard, txtPri, txtSec),
              ),
              const SizedBox(height: 10),
              _SettingsTile(
                icon: Icons.open_in_new_outlined,
                iconColor: SiklabColors.cyan,
                title: 'Export Questions',
                subtitle: 'Copy all quiz questions as JSON',
                trailing:
                    Icon(Icons.download_outlined, color: txtMut, size: 20),
                bgCard: bgCard,
                border: border,
                txtPri: txtPri,
                txtMut: txtMut,
                onTap: () => _exportQuestions(
                    context, bgCard, border, txtPri, txtSec, txtMut),
              ),
              const SizedBox(height: 20),

              // ── PLATFORM ─────────────────────────────────────
              _sectionLabel('PLATFORM', txtMut),
              const SizedBox(height: 10),
              _SettingsTile(
                icon: Icons.info_outline,
                iconColor: SiklabColors.cyan,
                title: 'About Siklab',
                subtitle: 'What Siklab is all about | Version 2.4.0-stable',
                trailing: Icon(Icons.chevron_right, color: txtMut, size: 20),
                bgCard: bgCard,
                border: border,
                txtPri: txtPri,
                txtMut: txtMut,
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AboutScreen())),
              ),
              const SizedBox(height: 28),

              // ── Sign out ──────────────────────────────────────
              GestureDetector(
                onTap: () => _showSignOutConfirm(
                    context, bgCard, border, txtPri, txtSec),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: SiklabColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout,
                          color: SiklabColors.error, size: 20),
                      const SizedBox(width: 10),
                      Text('Sign out',
                          style: GoogleFonts.spaceGrotesk(
                              color: SiklabColors.error,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showFullscreenInterruptionLog(BuildContext context) async {
    final events = await FullscreenInterruptionService.getInterruptions(
      UserSession().dbId,
    );
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fullscreen Event Log'),
        content: SizedBox(
          width: 420,
          child: events.isEmpty
              ? const Text('No focus-loss events have been recorded.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) => ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.warning_amber_rounded,
                      color: SiklabColors.orange,
                    ),
                    title: const Text('Fullscreen focus lost'),
                    subtitle: Text(
                      events[index].toLocal().toString().split('.').first,
                    ),
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ── Edit Profile bottom sheet ─────────────────────────────────────────────
  void _showEditProfile(BuildContext context, Color bgCard, Color border) {
    final session = UserSession();
    final nameCtrl = TextEditingController(text: session.displayName);
    final emailCtrl = TextEditingController(text: session.email);
    final passCtrl = TextEditingController();
    bool obscure = true;
    bool loading = false;
    String errorMsg = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Future<void> save() async {
            if (session.dbId == 0) return;
            setSheet(() {
              loading = true;
              errorMsg = '';
            });

            final fields = <String, dynamic>{};
            final newName = nameCtrl.text.trim();
            final newEmail = emailCtrl.text.trim();
            final newPass = passCtrl.text.trim();

            if (newName.isNotEmpty && newName != session.displayName) {
              fields['full_name'] = newName;
            }
            if (newEmail.isNotEmpty && newEmail != session.email) {
              fields['email'] = newEmail;
            }
            if (newPass.isNotEmpty) {
              fields['password'] = newPass;
            }

            if (fields.isEmpty) {
              setSheet(() {
                loading = false;
                errorMsg = 'No changes to save.';
              });
              return;
            }

            final result = await ApiService.updateProfile(session.dbId, fields);
            setSheet(() => loading = false);

            if (result.success) {
              if (ctx.mounted) Navigator.of(ctx).pop();
            } else {
              setSheet(() => errorMsg = result.message);
            }
          }

          return Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: bgCard,
                border: Border(
                  top: BorderSide(color: border),
                  left: BorderSide(color: border),
                  right: BorderSide(color: border),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: border,
                            borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Header
                    Row(children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: SiklabColors.pink.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.person_outline,
                            color: SiklabColors.pink, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('EDIT PROFILE',
                                style: GoogleFonts.sourceCodePro(
                                    color: SiklabColors.pink,
                                    fontSize: 10,
                                    letterSpacing: 1.5)),
                            Text('Update your account details',
                                style: GoogleFonts.spaceGrotesk(
                                    color: const Color(0xFFAAAAAC),
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    _sheetLabel('DISPLAY NAME'),
                    const SizedBox(height: 6),
                    _sheetField(
                        nameCtrl, 'Your full name', Icons.person_outline),
                    const SizedBox(height: 14),

                    _sheetLabel('EMAIL'),
                    const SizedBox(height: 6),
                    _sheetField(
                        emailCtrl, 'your@email.com', Icons.alternate_email,
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 14),

                    _sheetLabel('NEW PASSWORD (leave blank to keep current)'),
                    const SizedBox(height: 6),
                    StatefulBuilder(builder: (_, setSuffix) {
                      return SecureTextField(
                        controller: passCtrl,
                        obscureText: obscure,
                        style: GoogleFonts.sourceCodePro(
                            color: const Color(0xFFE8E8F0), fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: GoogleFonts.sourceCodePro(
                              color: const Color(0xFF3A4F63), fontSize: 13),
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: SiklabColors.textMuted, size: 18),
                          suffixIcon: GestureDetector(
                            onTap: () => setSuffix(() => obscure = !obscure),
                            child: Icon(
                                obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: SiklabColors.textMuted,
                                size: 18),
                          ),
                        ),
                      );
                    }),

                    if (errorMsg.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: SiklabColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: SiklabColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: SiklabColors.error, size: 15),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(errorMsg,
                                  style: GoogleFonts.sourceCodePro(
                                      color: SiklabColors.error, fontSize: 11)),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(ctx).pop(),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: border),
                            ),
                            child: Center(
                              child: Text('CANCEL',
                                  style: GoogleFonts.spaceGrotesk(
                                      color: const Color(0xFFAAAAAC),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: loading ? null : save,
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00CFFF), Color(0xFF0099CC)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          color: Colors.black, strokeWidth: 2))
                                  : Text('SAVE CHANGES',
                                      style: GoogleFonts.spaceGrotesk(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Export Questions ──────────────────────────────────────────────────────
  void _exportQuestions(BuildContext context, Color bgCard, Color border,
      Color txtPri, Color txtSec, Color txtMut) {
    // Build flat list from all languages → categories → questions
    final questions = <Map<String, dynamic>>[];
    for (final lang in languageQuizzes) {
      for (final entry in lang.categories.entries) {
        for (final q in entry.value) {
          questions.add({
            'language': lang.name,
            'category': entry.key.label,
            'title': q.title,
            'module': q.module,
            'description': q.description,
            'filename': q.filename,
            'hint': q.hint,
          });
        }
      }
    }

    final jsonStr = const JsonEncoder.withIndent('  ').convert(questions);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: bgCard,
          border: Border(
            top: BorderSide(color: border),
            left: BorderSide(color: border),
            right: BorderSide(color: border),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: SiklabColors.cyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.open_in_new_outlined,
                    color: SiklabColors.cyan, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EXPORT QUESTIONS',
                      style: GoogleFonts.sourceCodePro(
                          color: SiklabColors.cyan,
                          fontSize: 10,
                          letterSpacing: 1.5)),
                  Text('${questions.length} questions ready',
                      style: GoogleFonts.spaceGrotesk(
                          color: txtSec, fontSize: 12)),
                ],
              ),
            ]),
            const SizedBox(height: 16),
            // JSON preview box
            Container(
              height: 160,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1821),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: SiklabColors.cyan.withValues(alpha: 0.2)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  jsonStr.length > 800
                      ? '${jsonStr.substring(0, 800)}…\n\n[+${questions.length - 3} more]'
                      : jsonStr,
                  style: GoogleFonts.sourceCodePro(
                      color: SiklabColors.textSecondary, fontSize: 10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Copy button
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: SiklabColors.bgCard,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    content: Row(children: [
                      const Icon(Icons.block,
                          color: SiklabColors.orange, size: 18),
                      const SizedBox(width: 10),
                      Text('Copying is disabled in this app',
                          style: GoogleFonts.spaceGrotesk(
                              color: SiklabColors.textSecondary, fontSize: 13)),
                    ]),
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00CFFF), Color(0xFF0099CC)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.copy, color: Colors.black, size: 18),
                    const SizedBox(width: 8),
                    Text('COPY JSON TO CLIPBOARD',
                        style: GoogleFonts.spaceGrotesk(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reset progress confirmation ───────────────────────────────────────────
  Future<void> _showResetProgressConfirm(
      BuildContext context, Color bgCard, Color txtPri, Color txtSec) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reset Progress?',
            style: GoogleFonts.spaceGrotesk(
                color: txtPri, fontWeight: FontWeight.w700)),
        content: Text(
            'This will clear practice history, stats, and active time on this device. Progress synced to your account on other devices will not be changed. This cannot be undone.',
            style: GoogleFonts.spaceGrotesk(color: txtSec, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('CANCEL',
                  style: GoogleFonts.sourceCodePro(color: txtSec))),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('CONFIRM',
                  style: GoogleFonts.sourceCodePro(
                      color: SiklabColors.error, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ApiService.resetLocalProgress();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progress reset on this device.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not reset progress: $error')),
      );
    }
  }

  // ── Sign out confirm dialog ─────────────────────────────────────────────────
  void _showSignOutConfirm(BuildContext context, Color bgCard, Color border,
      Color txtPri, Color txtSec) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign Out',
            style: GoogleFonts.spaceGrotesk(
                color: txtPri, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to log out?',
            style: GoogleFonts.spaceGrotesk(color: txtSec, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text('No', style: GoogleFonts.sourceCodePro(color: txtSec))),
          TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await ApiService.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (route) => false,
                  );
                }
              },
              child: Text('Yes',
                  style: GoogleFonts.sourceCodePro(
                      color: SiklabColors.error, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

// ── Top-level helpers ─────────────────────────────────────────────────────────

Widget _sectionLabel(String text, Color color) => Text(text,
    style: GoogleFonts.sourceCodePro(
        color: color, fontSize: 10, letterSpacing: 1.8));

Widget _sheetLabel(String text) => Text(text,
    style: GoogleFonts.sourceCodePro(
        color: const Color(0xFF6B8099), fontSize: 9, letterSpacing: 1.5));

Widget _sheetField(TextEditingController ctrl, String hint, IconData icon,
    {TextInputType keyboardType = TextInputType.text}) {
  return SecureTextField(
    controller: ctrl,
    keyboardType: keyboardType,
    style:
        GoogleFonts.sourceCodePro(color: const Color(0xFFE8E8F0), fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.sourceCodePro(
          color: const Color(0xFF3A4F63), fontSize: 13),
      prefixIcon: Icon(icon, color: SiklabColors.textMuted, size: 18),
    ),
  );
}

// ── Settings tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final Color bgCard, border, txtPri, txtMut;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.bgCard,
    required this.border,
    required this.txtPri,
    required this.txtMut,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border)),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.spaceGrotesk(
                        color: txtPri,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style:
                        GoogleFonts.spaceGrotesk(color: txtMut, fontSize: 12)),
              ],
            ),
          ),
          trailing,
        ]),
      ),
    );
  }
}

// ── Certificates section ──────────────────────────────────────────────────────
// One certificate per programming language (unlocked when every module topic
// and practice question of that language - Beginner to Advanced -
// is completed) plus an overall certificate for completing every language.

class _CertificatesSection extends StatefulWidget {
  final Color bgCard, border, txtPri, txtMut;
  const _CertificatesSection({
    required this.bgCard,
    required this.border,
    required this.txtPri,
    required this.txtMut,
  });

  @override
  State<_CertificatesSection> createState() => _CertificatesSectionState();
}

class _CertificatesSectionState extends State<_CertificatesSection> {
  late Future<Map<String, CompletionStatus>> _future;

  @override
  void initState() {
    super.initState();
    _future = CertificateService.getLanguageStatuses();
  }

  void _refresh() =>
      setState(() => _future = CertificateService.getLanguageStatuses());

  void _open(String? language) {
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (_) => CertificateScreen(language: language)))
        .then((_) => _refresh());
  }

  void _showProgress(String scope, CompletionStatus s) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        'Modules: ${s.modulesDone}/${s.modulesTotal}'
        '  |  Practice: ${s.practiceDone}/${s.practiceTotal}'
        '\nComplete everything in $scope to unlock this certificate.',
        style: GoogleFonts.spaceGrotesk(fontSize: 12),
      ),
    ));
  }

  Widget _tile({
    required String title,
    required String scope, // used in the locked message
    required String? language,
    required CompletionStatus? status,
  }) {
    final unlocked = status?.isComplete ?? false;
    final subtitle = status == null
        ? 'Checking your progress...'
        : unlocked
            ? 'Unlocked! Tap to view, download or print'
            : 'Locked - finish all modules and practice questions '
                '(${status.percent}% done)';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: status == null || unlocked ? 1 : 0.65,
        child: _SettingsTile(
          icon:
              unlocked ? Icons.workspace_premium_outlined : Icons.lock_outline,
          iconColor: unlocked ? SiklabColors.success : widget.txtMut,
          title: title,
          subtitle: subtitle,
          trailing: Icon(
            unlocked ? Icons.chevron_right : Icons.lock_outline,
            color: widget.txtMut,
            size: 20,
          ),
          bgCard: widget.bgCard,
          border: unlocked
              ? SiklabColors.success.withValues(alpha: 0.5)
              : widget.border,
          txtPri: widget.txtPri,
          txtMut: widget.txtMut,
          onTap: status == null
              ? null
              : () => unlocked ? _open(language) : _showProgress(scope, status),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, CompletionStatus>>(
      future: _future,
      builder: (context, snapshot) {
        final statuses = snapshot.data;
        final overall = statuses == null
            ? null
            : CertificateService.combine(statuses.values);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tile(
              title: 'Certificate of Completion',
              scope: 'every language',
              language: null,
              status: overall,
            ),
            for (final lang in languageQuizzes)
              _tile(
                title: '${lang.name} Certificate',
                scope: lang.name,
                language: lang.name,
                status: statuses?[lang.name],
              ),
          ],
        );
      },
    );
  }
}
