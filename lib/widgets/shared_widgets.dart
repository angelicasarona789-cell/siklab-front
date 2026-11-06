import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../navigation/shell_navigator.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/main_shell.dart';
import '../models/user_session.dart';
import '../services/api_service.dart';
import '../services/demo_certificate_accounts.dart';

// ─── Logo / Nav Brand ───────────────────────────────────────────────────────

class SiklabLogo extends StatelessWidget {
  final double size;
  final bool tappable;
  const SiklabLogo({super.key, this.size = 20, this.tappable = true});

  @override
  Widget build(BuildContext context) {
    final logo = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size * 1.6,
          height: size * 1.2,
          decoration: BoxDecoration(
            border: Border.all(color: SiklabColors.cyan, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              '>_',
              style: GoogleFonts.sourceCodePro(
                color: SiklabColors.cyan,
                fontSize: size * 0.55,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'SIKLAB',
          style: GoogleFonts.spaceGrotesk(
            color: SiklabColors.cyan,
            fontSize: size,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ],
    );

    if (!tappable) return logo;

    return GestureDetector(
      onTap: () => ShellNavigator.goHome(context),
      child: logo,
    );
  }
}

// ─── Cyan Glow Button ────────────────────────────────────────────────────────

class CyanButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool outlined;
  const CyanButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: outlined
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF00CFFF), Color(0xFF0099CC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          border:
              outlined ? Border.all(color: context.clBorder, width: 1.5) : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: outlined
              ? null
              : [
                  BoxShadow(
                    color: SiklabColors.cyan.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  color: outlined ? context.clTextPrimary : context.clBg,
                  size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: outlined ? context.clTextPrimary : context.clBg,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Code Label Tag ──────────────────────────────────────────────────────────

class CodeTag extends StatelessWidget {
  final String text;
  final Color? color;
  const CodeTag({super.key, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? SiklabColors.purple).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (color ?? SiklabColors.purple).withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.sourceCodePro(
          color: color ?? SiklabColors.purple,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─── Stat Card ───────────────────────────────────────────────────────────────

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;
  final Color? accentColor;
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.trailing,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.clBgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: accentColor ?? SiklabColors.cyan,
              width: 3,
            ),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.only(left: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: GoogleFonts.sourceCodePro(
                color: context.clTextMuted,
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: GoogleFonts.spaceGrotesk(
                    color: context.clTextPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Header ──────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String tag;
  final String title;
  final Color? tagColor;
  const SectionHeader({
    super.key,
    required this.tag,
    required this.title,
    this.tagColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: tagColor ?? SiklabColors.cyan,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              tag.toUpperCase(),
              style: GoogleFonts.sourceCodePro(
                color: tagColor ?? SiklabColors.cyan,
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            color: context.clTextPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class SiklabBackButton extends StatelessWidget {
  const SiklabBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      onPressed: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          ShellNavigator.back(context);
        }
      },
      icon: Icon(
        Icons.arrow_back_rounded,
        color: context.clTextSecondary,
        size: 20,
      ),
      style: IconButton.styleFrom(
        backgroundColor: context.clBgCard,
        side: BorderSide(color: context.clBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─── Bottom Nav Bar ──────────────────────────────────────────────────────────

class SiklabBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const SiklabBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Home'},
      {
        'icon': Icons.menu_book_outlined,
        'activeIcon': Icons.menu_book,
        'label': 'Modules'
      },
      {
        'icon': Icons.code_outlined,
        'activeIcon': Icons.code,
        'label': 'Practice'
      },
      {
        'icon': Icons.bar_chart_outlined,
        'activeIcon': Icons.bar_chart,
        'label': 'Analytics'
      },
      {
        'icon': Icons.person_outline,
        'activeIcon': Icons.person,
        'label': 'Profile'
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.clBgCard,
        border: Border(top: BorderSide(color: context.clBorder, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = i == currentIndex;
              return Expanded(
                  child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected
                            ? items[i]['activeIcon'] as IconData
                            : items[i]['icon'] as IconData,
                        color:
                            selected ? SiklabColors.cyan : context.clTextMuted,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i]['label'] as String,
                        style: GoogleFonts.spaceGrotesk(
                          color: selected
                              ? SiklabColors.cyan
                              : context.clTextMuted,
                          fontSize: 10,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ));
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Code Block ──────────────────────────────────────────────────────────────

class CodeBlock extends StatelessWidget {
  final String filename;
  final String code;
  final List<int>? highlightLines;
  const CodeBlock({
    super.key,
    required this.filename,
    required this.code,
    this.highlightLines,
  });

  @override
  Widget build(BuildContext context) {
    final lines = code.split('\n');
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1821),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.clBorder),
      ),
      child: Column(
        children: [
          // Title bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: context.clBorder),
              ),
            ),
            child: Row(
              children: [
                _dot(const Color(0xFFFF5F56)),
                const SizedBox(width: 6),
                _dot(const Color(0xFFFFBD2E)),
                const SizedBox(width: 6),
                _dot(const Color(0xFF27C93F)),
                const Spacer(),
                Text(
                  filename,
                  style: GoogleFonts.sourceCodePro(
                    color: context.clTextMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Code lines
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(lines.length, (i) {
                final hl =
                    highlightLines != null && highlightLines!.contains(i + 1);
                return Container(
                  color: hl
                      ? SiklabColors.cyan.withValues(alpha: 0.08)
                      : Colors.transparent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hl)
                        Container(
                          width: 3,
                          height: 18,
                          color: SiklabColors.cyan,
                          margin: const EdgeInsets.only(right: 8),
                        ),
                      SizedBox(
                        width: 28,
                        child: Text(
                          (i + 1).toString().padLeft(2, '0'),
                          style: GoogleFonts.sourceCodePro(
                            color: context.clTextMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _colorizeCode(context, lines[i]),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );

  Widget _colorizeCode(BuildContext context, String line) {
    // Simple keyword highlighting
    final keywords = [
      'function',
      'const',
      'let',
      'var',
      'return',
      'if',
      'else',
      'for',
      'while',
      'class',
      'import',
      'export',
      'async',
      'await',
      'null',
      'true',
      'false',
      'final',
      'Widget',
      'void',
      'def',
      'pass'
    ];

    final spans = <TextSpan>[];
    final words = line
        .split(RegExp(r'(?<=\s)|(?=\s)|(?=[{}\[\]();,])|(?<=[{}\[\]();,])'));

    for (final word in words) {
      Color color = context.clTextSecondary;
      if (keywords.contains(word.trim())) {
        color = SiklabColors.purple;
      } else if (word.trim().startsWith("'") || word.trim().startsWith('"')) {
        color = SiklabColors.green;
      } else if (word.trim().startsWith('//') || line.trim().startsWith('//')) {
        color = context.clTextMuted;
      } else if (RegExp(r'^\d+$').hasMatch(word.trim())) {
        color = SiklabColors.orange;
      } else if (word.contains('(')) {
        color = SiklabColors.cyan;
      }
      spans.add(TextSpan(
        text: word,
        style: GoogleFonts.sourceCodePro(color: color, fontSize: 12),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }
}

// ─── Hamburger Menu (shared across all main screens) ─────────────────────────

enum SiklabMenuAction { profile, demoAccounts, settings, toggleTheme }

class SiklabHamburgerMenu extends StatelessWidget {
  const SiklabHamburgerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = SiklabThemeScope.of(context);
    final isDark = themeNotifier.isDark;
    final bgCard = context.clBgCard;
    final border = context.clBorder;
    final txtPri = context.clTextPrimary;
    final txtSec = context.clTextSecondary;
    final txtMut = context.clTextMuted;

    return PopupMenuButton<SiklabMenuAction>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border, width: 1),
      ),
      color: bgCard,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      itemBuilder: (_) => [
        // ── Profile ──
        PopupMenuItem(
          value: SiklabMenuAction.profile,
          padding: EdgeInsets.zero,
          child: _SiklabMenuItem(
            icon: Icons.person_outline,
            label: 'Profile',
            color: SiklabColors.cyan,
            txtPri: txtPri,
            txtSec: txtSec,
            border: border,
            showDivider: true,
          ),
        ),
        PopupMenuItem(
          value: SiklabMenuAction.demoAccounts,
          padding: EdgeInsets.zero,
          child: _SiklabMenuItem(
            icon: Icons.school_outlined,
            label: 'Demo accounts',
            color: SiklabColors.green,
            txtPri: txtPri,
            txtSec: txtSec,
            border: border,
            showDivider: true,
          ),
        ),
        // ── Settings ──
        PopupMenuItem(
          value: SiklabMenuAction.settings,
          padding: EdgeInsets.zero,
          child: _SiklabMenuItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            color: SiklabColors.purple,
            txtPri: txtPri,
            txtSec: txtSec,
            border: border,
            showDivider: true,
          ),
        ),
        // ── Theme toggle ──
        PopupMenuItem(
          value: SiklabMenuAction.toggleTheme,
          padding: EdgeInsets.zero,
          child: _SiklabThemeMenuItem(
            isDark: isDark,
            txtPri: txtPri,
            bgCard: bgCard,
            border: border,
            txtMut: txtMut,
          ),
        ),
      ],
      onSelected: (action) {
        switch (action) {
          case SiklabMenuAction.profile:
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
          case SiklabMenuAction.demoAccounts:
            _chooseDemoAccount(context);
          case SiklabMenuAction.settings:
            Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()));
          case SiklabMenuAction.toggleTheme:
            themeNotifier.toggle();
        }
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: border),
        ),
        child: Icon(Icons.menu, color: txtSec, size: 20),
      ),
    );
  }

  Future<void> _chooseDemoAccount(BuildContext context) async {
    final account = await showDialog<DemoCertificateAccount>(
      context: context,
      builder: (dialogContext) {
        final txtPri = dialogContext.clTextPrimary;
        final txtMut = dialogContext.clTextMuted;
        final border = dialogContext.clBorder;

        return AlertDialog(
          title: Text(
            'Demo accounts',
            style: GoogleFonts.spaceGrotesk(
              color: txtPri,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Each account has completed Java, Python, C#, JavaScript, and SQL.',
                    style: GoogleFonts.spaceGrotesk(
                      color: txtMut,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...DemoCertificateAccounts.accounts.map(
                    (account) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.account_circle_outlined,
                        color: SiklabColors.green,
                      ),
                      title: Text(
                        account.name,
                        style: GoogleFonts.spaceGrotesk(
                          color: txtPri,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${account.level} certificate profile',
                        style: GoogleFonts.spaceGrotesk(color: txtMut),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: border,
                      ),
                      onTap: () => Navigator.of(dialogContext).pop(account),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
    if (account == null || !context.mounted) return;

    try {
      UserSession().stopActivityTracking();
      await UserSession().saveActiveTime();
      await DemoCertificateAccounts.activate(account);
      await ApiService.loadLanguageProgress();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const MainShell()),
        (_) => false,
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open the demo account: $error'),
          backgroundColor: SiklabColors.error,
        ),
      );
    }
  }
}

class _SiklabMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color txtPri;
  final Color txtSec;
  final Color border;
  final bool showDivider;

  const _SiklabMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.txtPri,
    required this.txtSec,
    required this.border,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(label,
                  style: GoogleFonts.spaceGrotesk(
                      color: txtPri,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Icon(Icons.chevron_right, color: txtSec, size: 16),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, thickness: 1, color: border),
      ],
    );
  }
}

class _SiklabThemeMenuItem extends StatelessWidget {
  final bool isDark;
  final Color txtPri;
  final Color bgCard;
  final Color border;
  final Color txtMut;

  const _SiklabThemeMenuItem({
    required this.isDark,
    required this.txtPri,
    required this.bgCard,
    required this.border,
    required this.txtMut,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: (isDark ? SiklabColors.purple : SiklabColors.orange)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              color: isDark ? SiklabColors.purple : SiklabColors.orange,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(isDark ? 'Dark Mode' : 'Light Mode',
              style: GoogleFonts.spaceGrotesk(
                  color: txtPri, fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          // Toggle pill
          Container(
            width: 44,
            height: 24,
            decoration: BoxDecoration(
              color: isDark
                  ? SiklabColors.cyan.withValues(alpha: 0.2)
                  : SiklabColors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? SiklabColors.cyan : SiklabColors.orange,
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment:
                      isDark ? Alignment.centerRight : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: isDark ? SiklabColors.cyan : SiklabColors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
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
