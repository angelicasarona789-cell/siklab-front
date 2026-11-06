import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_session.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/secure_text_field.dart';
import '../widgets/shared_widgets.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  static const _categories = [
    'Suggestion',
    'Bug report',
    'General feedback',
  ];

  final _messageController = TextEditingController();
  String _category = _categories.first;
  bool _submitting = false;
  String? _error;
  String? _status;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() => _error = 'Please enter your feedback.');
      return;
    }
    if (message.length > 2000) {
      setState(() => _error = 'Feedback must be 2,000 characters or fewer.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
      _status = null;
    });

    final result = await ApiService.submitFeedback(
      userId: UserSession().dbId,
      category: _category,
      message: message,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success) {
      _messageController.clear();
      setState(() => _status = 'Submitted — pending admin review.');
    } else {
      setState(() => _error = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = UserSession();
    final isSignedIn = session.dbId > 0;

    return Scaffold(
      backgroundColor: context.clBg,
      appBar: AppBar(
        backgroundColor: context.clBg,
        foregroundColor: context.clTextPrimary,
        title: Text(
          'Feedback',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'SHARE YOUR THOUGHTS',
              style: GoogleFonts.sourceCodePro(
                color: SiklabColors.cyan,
                fontSize: 11,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your feedback helps us improve Siklab. Submissions are shared with the Siklab admin team.',
              style: GoogleFonts.spaceGrotesk(
                color: context.clTextSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            if (!isSignedIn)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.clBgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.clBorder),
                ),
                child: Text(
                  'Please sign in to submit feedback.',
                  style: GoogleFonts.spaceGrotesk(
                    color: context.clTextSecondary,
                  ),
                ),
              )
            else ...[
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: 'Feedback type',
                  filled: true,
                  fillColor: context.clBgCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: _categories
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: _submitting
                    ? null
                    : (category) {
                        if (category != null) {
                          setState(() => _category = category);
                        }
                      },
              ),
              const SizedBox(height: 14),
              SecureTextField(
                controller: _messageController,
                maxLines: 7,
                keyboardType: TextInputType.multiline,
                enabled: !_submitting,
                showSnackBarOnBlock: false,
                decoration: InputDecoration(
                  hintText: 'Tell us what you think...',
                  helperText:
                      '${_messageController.text.length}/2000 characters',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: context.clBgCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: GoogleFonts.spaceGrotesk(color: SiklabColors.error),
                ),
              ],
              if (_status != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SiklabColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: SiklabColors.success.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    _status!,
                    style: GoogleFonts.spaceGrotesk(
                      color: SiklabColors.success,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              CyanButton(
                label: _submitting ? 'SUBMITTING...' : 'SUBMIT FEEDBACK',
                icon: Icons.send_outlined,
                onTap: _submitting ? null : _submit,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
