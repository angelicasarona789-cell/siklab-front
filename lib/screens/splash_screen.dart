import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_session.dart';
import 'onboarding_screen.dart';
import 'main_shell.dart';
import 'programming_gate_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _progress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _ctrl.forward().then((_) async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        // Check if user is already logged in
        final savedId = await ApiService.getSavedUserId();
        debugPrint('SplashScreen: Saved user ID = $savedId');

        if (savedId != null && savedId > 0) {
          debugPrint(
              'SplashScreen: Found saved user ID: $savedId, loading profile...');

          // Set up UserSession with saved ID immediately to prevent reset
          await UserSession().setBasicLoginInfo(savedId);

          // Restore local progress and active time before entering the app
          await ApiService.loadLanguageProgress();
          await UserSession().loadActiveTime();

          // Try to load user profile from backend (but don't fail if it doesn't work)
          try {
            final result = await ApiService.getProfile(savedId);
            debugPrint(
                'SplashScreen: Profile load success = ${result.success}');

            if (!result.success) {
              // Only clear saved ID on explicit auth errors
              final isAuthError =
                  result.message.toLowerCase().contains('invalid') ||
                      result.message.toLowerCase().contains('unauthorized') ||
                      result.message.toLowerCase().contains('not found') ||
                      result.message.toLowerCase().contains('expired');

              if (isAuthError) {
                debugPrint(
                    'SplashScreen: Clearing saved ID due to auth error: ${result.message}');
                await ApiService.logout();
                return; // Don't proceed to main shell if auth error
              } else {
                debugPrint(
                    'SplashScreen: Profile failed but keeping saved ID: ${result.message}');
                // Try to load cached user data from SharedPreferences
                await _loadCachedUserData(savedId);
              }
            }
          } catch (e) {
            debugPrint(
                'SplashScreen: Profile load exception: $e - keeping saved ID');
            // Try to load cached user data from SharedPreferences
            await _loadCachedUserData(savedId);
          }

          // Always proceed to main shell if we have saved ID and no auth error
          if (mounted) {
            debugPrint(
                'SplashScreen: Proceeding to main shell with saved ID: $savedId');
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
          return;
        }
        // No saved user or failed to load, go to onboarding
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        }
      }
    });
  }

  Future<void> _loadCachedUserData(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedName = prefs.getString('cached_user_name_$userId');
      final cachedEmail = prefs.getString('cached_user_email_$userId');

      debugPrint('SplashScreen: Looking for cached data for user $userId');
      debugPrint('SplashScreen: Found cached name: $cachedName');
      debugPrint('SplashScreen: Found cached email: $cachedEmail');
      debugPrint(
          'SplashScreen: Current UserSession name before update: ${UserSession().displayName}');

      if (cachedName != null && cachedName.isNotEmpty) {
        UserSession().displayName = cachedName;
        UserSession().email = cachedEmail ?? '';
        debugPrint(
            'SplashScreen: Updated UserSession - Name: $cachedName, Email: ${cachedEmail ?? 'N/A'}');
        debugPrint(
            'SplashScreen: UserSession name after update: ${UserSession().displayName}');

        // Force notify listeners to update UI
        // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
        UserSession().notifyListeners();
      } else {
        debugPrint('SplashScreen: No cached name found for user $userId');
      }
    } catch (e) {
      debugPrint('SplashScreen: Failed to load cached user data: $e');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SiklabColors.bg,
      body: FadeTransition(
        opacity: _fade,
        child: Stack(
          children: [
            // Background glow
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              left: MediaQuery.of(context).size.width * 0.1,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.width * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      SiklabColors.cyan.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: SiklabColors.border.withValues(alpha: 0.7)),
                      boxShadow: [
                        BoxShadow(
                          color: SiklabColors.cyan.withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Center(
                          child: Icon(
                            Icons.terminal_outlined,
                            color: SiklabColors.cyan,
                            size: 46,
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: SiklabColors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.bolt,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Siklab',
                    style: GoogleFonts.spaceGrotesk(
                      color: SiklabColors.cyan,
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '// SPARK YOUR LOGIC. STRENGTHEN YOUR CODE.',
                    style: GoogleFonts.sourceCodePro(
                      color: SiklabColors.textMuted,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),
                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: AnimatedBuilder(
                      animation: _progress,
                      builder: (_, __) => Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: _progress.value,
                              backgroundColor: SiklabColors.border,
                              valueColor: const AlwaysStoppedAnimation(
                                  SiklabColors.cyan),
                              minHeight: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom version
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'SYSTEM READY',
                    style: GoogleFonts.sourceCodePro(
                      color: SiklabColors.textMuted,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: SiklabColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'V1.0.4-STABLE',
                    style: GoogleFonts.sourceCodePro(
                      color: SiklabColors.textMuted,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
