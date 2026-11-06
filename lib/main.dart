import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:screen_protector/screen_protector.dart';
import 'models/user_session.dart';
import 'services/api_service.dart';
import 'services/fullscreen_interruption_service.dart';
import 'screens/auth_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/secure_text_field.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _enableScreenProtection();

  // Make the app open in full-screen (hide the status bar and nav bar).
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: SiklabColors.bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const SiklabApp());
}

Future<void> _enableScreenProtection() async {
  if (kIsWeb) return;

  if (defaultTargetPlatform == TargetPlatform.windows) {
    // The Windows runner applies capture exclusion to the top-level window.
    return;
  }

  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    debugPrint(
      'Screenshot protection is unavailable on $defaultTargetPlatform.',
    );
    return;
  }

  try {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await ScreenProtector.protectDataLeakageOn();
    } else {
      await ScreenProtector.preventScreenshotOn();
    }
  } catch (error) {
    debugPrint('Could not enable screenshot protection: $error');
  }
}

class SiklabApp extends StatefulWidget {
  const SiklabApp({super.key});
  @override
  State<SiklabApp> createState() => _SiklabAppState();
}

class _SiklabAppState extends State<SiklabApp> with WidgetsBindingObserver {
  static const int _maxPostLoginFullscreenInterruptions =
      FullscreenInterruptionService.postReloginInterruptionLimit;

  final _themeNotifier = ThemeNotifier();
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _hasBeenActive = false;
  bool _interruptionPending = false;
  bool _interruptionTransitionInProgress = false;
  Future<int>? _pendingInterruptionRecord;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (defaultTargetPlatform != TargetPlatform.windows) return;

    if (state == AppLifecycleState.resumed) {
      if (_interruptionPending) {
        _showInterruptionWarning();
      }
      _hasBeenActive = true;
    } else if (_hasBeenActive &&
        !_interruptionPending &&
        (state == AppLifecycleState.inactive ||
            state == AppLifecycleState.hidden ||
            state == AppLifecycleState.paused)) {
      _interruptionPending = true;
      _pendingInterruptionRecord =
          FullscreenInterruptionService.recordInterruption(
        userId: UserSession().dbId,
        email: UserSession().email,
      ).catchError((Object error) {
        debugPrint('Could not save fullscreen interruption: $error');
        return 0;
      });
    }
    if (state == AppLifecycleState.resumed) {
      _enableScreenProtection();
    }
  }

  Future<void> _showInterruptionWarning() async {
    if (_interruptionTransitionInProgress) return;
    final context = _navigatorKey.currentContext;
    final eventCount = await _pendingInterruptionRecord;
    _pendingInterruptionRecord = null;
    _interruptionPending = false;
    if (!mounted || context == null || !context.mounted) return;

    if (eventCount != null && eventCount >= 1) {
      _interruptionTransitionInProgress = true;
      final lockoutStarted =
          eventCount > _maxPostLoginFullscreenInterruptions + 1;
      try {
        await ApiService.logout(syncActiveTimeToServer: false);
      } catch (error) {
        debugPrint('Could not complete fullscreen sign-out: $error');
        _interruptionTransitionInProgress = false;
        rethrow;
      }
      if (!mounted) {
        _interruptionTransitionInProgress = false;
        return;
      }
      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => AuthScreen(
            signedOutForFullscreenInterruptions: true,
            fullscreenAccountLocked: lockoutStarted,
          ),
        ),
        (_) => false,
      );
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session interruption recorded'),
        content: Text(
          eventCount == null || eventCount == 0
              ? 'Siklab lost focus while running fullscreen. The local event log could not be saved.'
              : 'Siklab lost focus while running fullscreen. This interruption was recorded on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _themeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SiklabThemeScope(
      notifier: _themeNotifier,
      child: ListenableBuilder(
        listenable: _themeNotifier,
        builder: (_, __) => ClipboardGuard(
          child: MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'Siklab',
            debugShowCheckedModeBanner: false,
            theme: SiklabTheme.build(dark: _themeNotifier.isDark),
            home: const SplashScreen(),
          ),
        ),
      ),
    );
  }
}
