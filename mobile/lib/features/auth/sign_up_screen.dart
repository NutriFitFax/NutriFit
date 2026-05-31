import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/nutri_colors.dart';
import 'profile_setup_screen.dart';
import 'user_profile.dart';
import 'auth_widgets.dart';


class SignUpScreen extends StatefulWidget {
  final void Function(UserProfile profile) onComplete;
  const SignUpScreen({super.key, required this.onComplete});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _continue() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileSetupScreen(
          name: _name.text.trim(),
          email: _email.text.trim(),
          onComplete: widget.onComplete,
        ),
      ),
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
                padding: const EdgeInsets.fromLTRB(26, 6, 26, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top bar
                      Row(
                        children: [
                          _BackButton(),
                          const SizedBox(width: 6),
                          Text(
                            'STEP 1 OF 2',
                            style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              letterSpacing: 0.8, color: c.ink2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'JOIN NUTRIFIT',
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          letterSpacing: 0.8, color: c.ink3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create your account',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 30),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A few details to get you started.',
                        style: TextStyle(color: c.ink2, fontSize: 14),
                      ),
                      const SizedBox(height: 24),

                      const FieldLabel('Full name'),
                      AuthTextField(
                        controller: _name,
                        hint: 'Your name',
                        icon: Icons.person_outline,
                        keyboardType: TextInputType.name,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                      ),
                      const SizedBox(height: 14),

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
                        hint: 'At least 8 characters',
                        icon: Icons.lock_outline,
                        obscure: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _continue(),
                        validator: (v) => (v == null || v.length < 8)
                            ? 'Use at least 8 characters'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      FilledButton(
                        onPressed: _continue,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Continue'),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Text.rich(
                          TextSpan(
                            style: TextStyle(fontSize: 11.5, color: c.ink3, height: 1.5),
                            children: [
                              const TextSpan(text: 'By continuing you agree to our '),
                              TextSpan(text: 'Terms', style: TextStyle(color: c.ink2, decoration: TextDecoration.underline)),
                              const TextSpan(text: ' & '),
                              TextSpan(text: 'Privacy Policy', style: TextStyle(color: c.ink2, decoration: TextDecoration.underline)),
                              const TextSpan(text: '.'),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
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
                  Text('Already have an account? ', style: TextStyle(color: c.ink2, fontSize: 13.5)),
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Text(
                      'Log in',
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

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => Navigator.of(context).maybePop(),
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40, height: 40,
          child: Icon(Icons.chevron_left, size: 26, color: context.nutri.ink),
        ),
      ),
    );
  }
}
