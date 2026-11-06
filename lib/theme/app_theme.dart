import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Color Palette ────────────────────────────────────────────────────────────

class SiklabColors {
  // Dark mode surfaces
  static const bg              = Color(0xFF0A0E14);
  static const bgCard          = Color(0xFF111820);
  static const bgElevated      = Color(0xFF161E28);
  static const border          = Color(0xFF1E2D3D);
  static const textPrimary     = Color(0xFFE8F0FA);
  static const textSecondary   = Color(0xFF6B8099);
  static const textMuted       = Color(0xFF3A4F63);

  // Light mode surfaces
  static const bgLight             = Color(0xFFF0F4FA);
  static const bgCardLight         = Color(0xFFFFFFFF);
  static const bgElevatedLight     = Color(0xFFE8EEF8);
  static const borderLight         = Color(0xFFD0DCF0);
  static const textPrimaryLight    = Color(0xFF0D1B2A);
  static const textSecondaryLight  = Color(0xFF4A6070);
  static const textMutedLight      = Color(0xFF9AAFC4);

  // Accents — same across both themes
  static const cyan      = Color(0xFF00CFFF);
  static const cyanDark  = Color(0xFF0099BB);
  static const purple    = Color(0xFFB57BFF);
  static const orange    = Color(0xFFFF9A3C);
  static const green     = Color(0xFF00FF9D);
  static const pink      = Color(0xFFFF4D9E);
  static const error     = Color(0xFFFF4B4B);
  static const success   = Color(0xFF00D68F);
}

// ─── ThemeNotifier ────────────────────────────────────────────────────────────

class ThemeNotifier extends ChangeNotifier {
  bool _isDark = true;
  bool get isDark => _isDark;

  void toggle() { _isDark = !_isDark; notifyListeners(); }
  void setDark(bool v) { if (_isDark != v) { _isDark = v; notifyListeners(); } }
}

// ─── InheritedNotifier scope ──────────────────────────────────────────────────

class SiklabThemeScope extends InheritedNotifier<ThemeNotifier> {
  const SiklabThemeScope({
    super.key,
    required ThemeNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  static ThemeNotifier of(BuildContext ctx) {
    final s = ctx.dependOnInheritedWidgetOfExactType<SiklabThemeScope>();
    assert(s != null, 'No SiklabThemeScope found');
    return s!.notifier!;
  }
}

// ─── Context extensions ───────────────────────────────────────────────────────

extension ThemeColors on BuildContext {
  bool  get isDark           => SiklabThemeScope.of(this).isDark;
  Color get clBg             => isDark ? SiklabColors.bg             : SiklabColors.bgLight;
  Color get clBgCard         => isDark ? SiklabColors.bgCard         : SiklabColors.bgCardLight;
  Color get clBgElevated     => isDark ? SiklabColors.bgElevated     : SiklabColors.bgElevatedLight;
  Color get clBorder         => isDark ? SiklabColors.border         : SiklabColors.borderLight;
  Color get clTextPrimary    => isDark ? SiklabColors.textPrimary    : SiklabColors.textPrimaryLight;
  Color get clTextSecondary  => isDark ? SiklabColors.textSecondary  : SiklabColors.textSecondaryLight;
  Color get clTextMuted      => isDark ? SiklabColors.textMuted      : SiklabColors.textMutedLight;
}

// ─── Theme factory ────────────────────────────────────────────────────────────

class SiklabTheme {
  static ThemeData build({required bool dark}) {
    final bg         = dark ? SiklabColors.bg             : SiklabColors.bgLight;
    final bgCard     = dark ? SiklabColors.bgCard         : SiklabColors.bgCardLight;
    final bgElev     = dark ? SiklabColors.bgElevated     : SiklabColors.bgElevatedLight;
    final bord       = dark ? SiklabColors.border         : SiklabColors.borderLight;
    final txtPri     = dark ? SiklabColors.textPrimary    : SiklabColors.textPrimaryLight;
    final txtSec     = dark ? SiklabColors.textSecondary  : SiklabColors.textSecondaryLight;
    final txtMut     = dark ? SiklabColors.textMuted      : SiklabColors.textMutedLight;

    return ThemeData(
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: dark ? Brightness.dark : Brightness.light,
        primary: SiklabColors.cyan,    onPrimary: Colors.black,
        secondary: SiklabColors.purple, onSecondary: Colors.black,
        error: SiklabColors.error,      onError: Colors.white,
        surface: bgCard,               onSurface: txtPri,
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(
        dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ).copyWith(
        displayLarge:  GoogleFonts.spaceGrotesk(color: txtPri,  fontSize: 48, fontWeight: FontWeight.w700),
        headlineLarge: GoogleFonts.spaceGrotesk(color: txtPri,  fontSize: 32, fontWeight: FontWeight.w700),
        headlineMedium:GoogleFonts.spaceGrotesk(color: txtPri,  fontSize: 24, fontWeight: FontWeight.w700),
        titleLarge:    GoogleFonts.spaceGrotesk(color: txtPri,  fontSize: 18, fontWeight: FontWeight.w600),
        bodyLarge:     GoogleFonts.spaceGrotesk(color: txtSec,  fontSize: 16),
        bodyMedium:    GoogleFonts.spaceGrotesk(color: txtSec,  fontSize: 14),
        labelSmall:    GoogleFonts.sourceCodePro(color: txtMut, fontSize: 11, letterSpacing: 1.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg, elevation: 0, scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: txtPri),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bgCard,
        selectedItemColor: SiklabColors.cyan,
        unselectedItemColor: txtMut,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true, showUnselectedLabels: true, elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: bgElev,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: bord)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: bord)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SiklabColors.cyan, width: 1.5)),
        hintStyle:  GoogleFonts.sourceCodePro(color: txtMut,  fontSize: 14),
        labelStyle: GoogleFonts.spaceGrotesk(
            color: txtSec, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w600),
      ),
    );
  }

  static ThemeData get dark  => build(dark: true);
  static ThemeData get light => build(dark: false);
}
