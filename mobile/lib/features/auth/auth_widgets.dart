import 'package:flutter/material.dart';

import '../../../app/nutri_colors.dart';

/// The serif "NutriFit" wordmark — "Nutri" in ink, "Fit" in italic primary.
class NutriWordmark extends StatelessWidget {
  final double fontSize;
  const NutriWordmark({super.key, this.fontSize = 34});

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    final base = Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          height: 1.0,
          color: c.ink,
        );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'Nutri'),
          TextSpan(
            text: 'Fit',
            style: TextStyle(color: c.primary, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

/// All-caps muted field label.
class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7, left: 2),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
          color: context.nutri.ink2,
        ),
      ),
    );
  }
}

/// Cream rounded text field with a leading icon and optional password toggle.
class AuthTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;
  final bool autofocus;

  const AuthTextField({
    super.key,
    this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onSubmitted,
    this.autofocus = false,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return TextFormField(
      controller: widget.controller,
      obscureText: _hidden,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      autofocus: widget.autofocus,
      onFieldSubmitted: widget.onSubmitted,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: Icon(widget.icon, size: 20, color: c.ink2),
        suffixIcon: widget.obscure
            ? IconButton(
                splashRadius: 20,
                icon: Icon(
                  _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                  color: _hidden ? c.ink2 : c.primary,
                ),
                onPressed: () => setState(() => _hidden = !_hidden),
              )
            : null,
      ),
    );
  }
}
