import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/nutri_colors.dart';
import 'auth_widgets.dart';
import 'forgot_password_screen.dart';
import 'sign_up_screen.dart';
import 'user_profile.dart';

/// Email + password login. On success calls [onLogin] (backend verification),
/// then [onAuthenticated] (navigation). On a new account, navigates to the
/// sign-up flow which calls [onProfileCreated] then [onAuthenticated].
class LoginScreen extends StatefulWidget {
  /// Called with the entered email. Returns null on success or an error string.
  final Future<String?> Function(String email) onLogin;

  /// Called after login or sign-up succeeds — triggers navigation to AppShell.
  final VoidCallback onAuthenticated;

  /// Called when a brand-new profile is created via the sign-up flow.
  final Future<void> Function(UserProfile profile)? onProfileCreated;

  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onAuthenticated,
    this.onProfileCreated,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    HapticFeedback.lightImpact();
    final error = await widget.onLogin(_email.text.trim());
    if (!mounted) return;
    if (error != null) {
      setState(() { _busy = false; _error = error; });
    } else {
      setState(() => _busy = false);
      widget.onAuthenticated();
    }
  }

  void _goToSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SignUpScreen(
          onComplete: (profile) async {
            await widget.onProfileCreated?.call(profile);
            widget.onAuthenticated();
          },
        ),
      ),
    );
  }

  void _goToForgot() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(26, 0, 26, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 48),
                      const Center(child: NutriWordmark(fontSize: 36)),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          "Welcome back. Let's eat well today.",
                          style: TextStyle(color: c.ink2, fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 40),

                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: c.warn.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: c.warn.withValues(alpha: 0.4)),
                          ),
                          child: Text(_error!, style: TextStyle(color: c.warn, fontSize: 13)),
                        ),
                        const SizedBox(height: 16),
                      ],

                      const FieldLabel('Email'),
                      AuthTextField(
                        controller: _email,
                        hint: 'you@example.com',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 14),

                      const FieldLabel('Password'),
                      AuthTextField(
                        controller: _password,
                        hint: 'Your password',
                        icon: Icons.lock_outline,
                        obscure: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Enter your password' : null,
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _goToForgot,
                          child: const Text('Forgot password?'),
                        ),
                      ),
                      const SizedBox(height: 6),

                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Log in'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('New to NutriFit? ', style: TextStyle(color: c.ink2, fontSize: 13.5)),
                  GestureDetector(
                    onTap: _goToSignUp,
                    child: Text(
                      'Create account',
                      style: TextStyle(color: c.primary, fontWeight: FontWeight.w700, fontSize: 13.5),
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

  static String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter your email';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid email';
  }
}
