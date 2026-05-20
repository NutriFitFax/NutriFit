import 'package:flutter/material.dart';

class AppPage extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const AppPage({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: child,
      // The outer AppShell Scaffold already handles keyboard resize; setting
      // this to false prevents the inner Scaffold from double-shrinking the
      // body in landscape when the keyboard is open.
      resizeToAvoidBottomInset: false,
    );
  }
}
