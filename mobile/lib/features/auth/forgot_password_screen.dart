import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/nutri_colors.dart';
import 'widgets/auth_widgets.dart';

/// "Reset password" — collects an email and shows a sent-confirmation state.
/// No backend call (stubbed); wire the TODO to your real reset endpoint.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    HapticFeedback.lightImpact();
    // TODO: call your password-reset endpoint here.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() { _busy = false; _sent = true; });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 0, 26, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: _sent ? c.primarySoft : c.carbsSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _sent ? Icons.mark_email_read_outlined : Icons.mail_outline,
                      color: _sent ? c.primary : c.carbs,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _sent ? 'Check your inbox' : 'Reset password',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 27),
                ),
                const SizedBox(height: 8),
                Text(
                  _sent
                      ? "We've sent a secure reset link to ${_email.text.trim()}."
                      : "Enter the email tied to your account and we'll send a secure reset link.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.ink2, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 26),

                if (!_sent) ...[
                  const FieldLabel('Email'),
                  AuthTextField(
                    controller: _email,
                    hint: 'you@example.com',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofocus: true,
                    onSubmitted: (_) => _send(),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : _send,
                    child: _busy
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Send reset link'),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Back to login'),
                  ),
                ] else ...[
                  FilledButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Back to login'),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => setState(() => _sent = false),
                    child: const Text('Use a different email'),
                  ),
                ],

                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border.all(color: c.line),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 20, color: c.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Didn't get the email? Check your spam folder, or try again in 60 seconds.",
                          style: TextStyle(fontSize: 12.5, color: c.ink2, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter your email';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid email';
  }
}
