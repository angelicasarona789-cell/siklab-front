import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/secure_text_field.dart';
import '../services/api_service.dart';
import '../models/user_session.dart';
import 'programming_gate_screen.dart';
import 'main_shell.dart';

class AuthScreen extends StatefulWidget {
  final bool signedOutForFullscreenInterruptions;
  final bool fullscreenAccountLocked;

  const AuthScreen({
    super.key,
    this.signedOutForFullscreenInterruptions = false,
    this.fullscreenAccountLocked = false,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  @override
  void initState() {
    super.initState();
    if (!widget.signedOutForFullscreenInterruptions) {
      _checkExistingLogin();
    }
  }

  Future<void> _checkExistingLogin() async {
    final savedId = await ApiService.getSavedUserId();
    if (savedId != null && savedId > 0) {
      debugPrint('AuthScreen: User already logged in with ID: $savedId');
      await UserSession().setBasicLoginInfo(savedId);
      await ApiService.loadLanguageProgress();
      await UserSession().loadActiveTime();

      final result = await ApiService.getProfile(savedId);
      if (result.success && mounted) {
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
      } else if (mounted) {
        // Be very conservative about clearing saved ID - only clear on explicit auth failures
        final isAuthError = result.message.toLowerCase().contains('invalid') ||
            result.message.toLowerCase().contains('unauthorized') ||
            result.message.toLowerCase().contains('not found') ||
            result.message.toLowerCase().contains('expired');

        if (isAuthError) {
          debugPrint(
              'AuthScreen: Clearing saved ID due to auth error: ${result.message}');
          await ApiService.logout();
        } else {
          // Network/server error - proceed anyway
          debugPrint(
              'AuthScreen: Network/server error, keeping saved ID: ${result.message}');
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SiklabColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _isLogin
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.signedOutForFullscreenInterruptions) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: SiklabColors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: SiklabColors.orange.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          widget.fullscreenAccountLocked
                              ? 'Your account is locked on this device for one hour after repeated fullscreen interruptions.'
                              : 'You were signed out after leaving fullscreen. After signing in again, five more interruptions are allowed; the sixth locks access for one hour.',
                          style: GoogleFonts.spaceGrotesk(
                            color: SiklabColors.orange,
                          ),
                        ),
                      ),
                    ],
                    _LoginForm(
                      onSwitchToSignup: () => setState(() => _isLogin = false),
                    ),
                  ],
                )
              : _SignupForm(
                  onSwitchToLogin: () => setState(() => _isLogin = true)),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  final VoidCallback onSwitchToSignup;
  const _LoginForm({
    required this.onSwitchToSignup,
  });

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    final result = await ApiService.login(email: email, password: password);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      await ApiService.loadLanguageProgress();
      await UserSession().loadActiveTime();

      final userId = UserSession().dbId;
      final needsAssessment =
          await ApiService.requiresInitialAssessment(userId);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => needsAssessment
              ? const ProgrammingGateScreen()
              : const MainShell(),
        ),
      );
    } else {
      setState(() => _error = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: SiklabColors.border.withValues(alpha: 0.7)),
          ),
          child: const Icon(Icons.terminal_outlined,
              color: SiklabColors.cyan, size: 32),
        ),
        const SizedBox(height: 20),
        Text('Siklab',
            style: GoogleFonts.spaceGrotesk(
                color: SiklabColors.cyan,
                fontSize: 38,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('// AUTHENTICATION_REQUIRED',
            style: GoogleFonts.sourceCodePro(
                color: SiklabColors.textMuted, fontSize: 11, letterSpacing: 2)),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SiklabColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SiklabColors.border),
            boxShadow: [
              BoxShadow(
                color: SiklabColors.cyan.withValues(alpha: 0.05),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('EMAIL'),
              const SizedBox(height: 8),
              SecureTextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.sourceCodePro(
                    color: SiklabColors.textSecondary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'dev@siklab.io',
                  prefixIcon: Icon(Icons.alternate_email,
                      color: SiklabColors.textMuted, size: 18),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _fieldLabel('PASSWORD'),
                  GestureDetector(
                    onTap: () {},
                    child: Text('FORGOT?',
                        style: GoogleFonts.sourceCodePro(
                            color: SiklabColors.textMuted,
                            fontSize: 11,
                            letterSpacing: 1.5)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SecureTextField(
                controller: _passCtrl,
                obscureText: _obscure,
                style: GoogleFonts.sourceCodePro(
                    color: SiklabColors.textSecondary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '••••••••••',
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: SiklabColors.textMuted, size: 18),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: SiklabColors.textMuted,
                        size: 18),
                  ),
                ),
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: SiklabColors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: SiklabColors.orange.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: SiklabColors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error,
                            style: GoogleFonts.sourceCodePro(
                                color: SiklabColors.orange, fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: SiklabColors.cyan))
                  : CyanButton(label: 'Login →', onTap: _login),
              const SizedBox(height: 16),
              Row(children: [
                const Expanded(child: Divider(color: SiklabColors.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR',
                      style: GoogleFonts.sourceCodePro(
                          color: SiklabColors.textMuted,
                          fontSize: 10,
                          letterSpacing: 2)),
                ),
                const Expanded(child: Divider(color: SiklabColors.border)),
              ]),
              const SizedBox(height: 16),
              CyanButton(
                  label: 'Sign up',
                  onTap: widget.onSwitchToSignup,
                  outlined: true),
            ],
          ),
        ),
        const SizedBox(height: 40),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                color: SiklabColors.textMuted, size: 20),
            SizedBox(width: 16),
            Icon(Icons.shield_outlined,
                color: SiklabColors.textMuted, size: 20),
            SizedBox(width: 16),
            Icon(Icons.verified_user_outlined,
                color: SiklabColors.textMuted, size: 20),
          ],
        ),
        const SizedBox(height: 12),
        Text('BUILD 2.0.4-STABLE // ENCRYPTED CONNECTION',
            style: GoogleFonts.sourceCodePro(
                color: SiklabColors.textMuted,
                fontSize: 9,
                letterSpacing: 1.5)),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _fieldLabel(String text) => Text(text,
      style: GoogleFonts.spaceGrotesk(
          color: SiklabColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2));
}

class _SignupForm extends StatefulWidget {
  final VoidCallback onSwitchToLogin;
  const _SignupForm({required this.onSwitchToLogin});

  @override
  State<_SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<_SignupForm> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();
    final confirmPassword = _confirmPassCtrl.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() => _error = 'All fields are required.');
      return;
    }

    if (password != confirmPassword) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    final result = await ApiService.signup(
      fullName: name,
      email: email,
      password: password,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      // A brand-new account always starts with the onboarding questions, even
      // if an older account on this device once used the same id.
      await ApiService.clearStaleStateForNewAccount(UserSession().dbId);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProgrammingGateScreen()),
      );
    } else {
      setState(() => _error = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: SiklabColors.border.withValues(alpha: 0.7)),
          ),
          child: const Icon(Icons.terminal_outlined,
              color: SiklabColors.cyan, size: 32),
        ),
        const SizedBox(height: 20),
        Text('Siklab',
            style: GoogleFonts.spaceGrotesk(
                color: SiklabColors.cyan,
                fontSize: 38,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('// ACCOUNT_CREATION',
            style: GoogleFonts.sourceCodePro(
                color: SiklabColors.textMuted, fontSize: 11, letterSpacing: 2)),
        const SizedBox(height: 40),
        _inputRow('FULL NAME', 'Alex Rivers', Icons.person_outline, _nameCtrl),
        const SizedBox(height: 16),
        _inputRow(
            'EMAIL', 'developer@siklab.dev', Icons.alternate_email, _emailCtrl,
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _passwordRow(),
        const SizedBox(height: 12),
        _confirmPasswordRow(),
        const SizedBox(height: 12),
        if (_error.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SiklabColors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: SiklabColors.orange.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: SiklabColors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_error,
                      style: GoogleFonts.sourceCodePro(
                          color: SiklabColors.orange, fontSize: 11)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        _loading
            ? const Center(
                child: CircularProgressIndicator(color: SiklabColors.cyan))
            : CyanButton(label: 'Sign up', onTap: _signup),
        const SizedBox(height: 16),
        Row(children: [
          const Expanded(child: Divider(color: SiklabColors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('EXISTING SESSION?',
                style: GoogleFonts.sourceCodePro(
                    color: SiklabColors.textMuted,
                    fontSize: 10,
                    letterSpacing: 1.5)),
          ),
          const Expanded(child: Divider(color: SiklabColors.border)),
        ]),
        const SizedBox(height: 16),
        CyanButton(
            label: 'Login', onTap: widget.onSwitchToLogin, outlined: true),
        const SizedBox(height: 40),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.sourceCodePro(
                color: SiklabColors.textMuted, fontSize: 10, letterSpacing: 1),
            children: const [
              TextSpan(
                  text: 'BY INITIALIZING THIS PROFILE, YOU AGREE TO OUR\n'),
              TextSpan(
                  text: 'KERNEL PROTOCOLS',
                  style: TextStyle(color: SiklabColors.cyan)),
              TextSpan(text: ' AND '),
              TextSpan(
                  text: 'PRIVACY LOGIC',
                  style: TextStyle(color: SiklabColors.cyan)),
              TextSpan(text: '.'),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _inputRow(
    String label,
    String hint,
    IconData icon,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.spaceGrotesk(
                color: SiklabColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2)),
        const SizedBox(height: 8),
        SecureTextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.sourceCodePro(
              color: SiklabColors.textSecondary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: SiklabColors.textMuted, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _passwordRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PASSWORD',
            style: GoogleFonts.spaceGrotesk(
                color: SiklabColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2)),
        const SizedBox(height: 8),
        SecureTextField(
          controller: _passCtrl,
          obscureText: _obscure,
          style: GoogleFonts.sourceCodePro(
              color: SiklabColors.textSecondary, fontSize: 14),
          decoration: InputDecoration(
            hintText: '••••••••••',
            prefixIcon: const Icon(Icons.lock_outline,
                color: SiklabColors.textMuted, size: 18),
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: SiklabColors.textMuted,
                  size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _confirmPasswordRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CONFIRM PASSWORD',
            style: GoogleFonts.spaceGrotesk(
                color: SiklabColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2)),
        const SizedBox(height: 8),
        SecureTextField(
          controller: _confirmPassCtrl,
          obscureText: _obscureConfirm,
          style: GoogleFonts.sourceCodePro(
              color: SiklabColors.textSecondary, fontSize: 14),
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline,
                color: SiklabColors.textMuted, size: 18),
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
              child: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: SiklabColors.textMuted,
                  size: 18),
            ),
          ),
        ),
      ],
    );
  }
}
