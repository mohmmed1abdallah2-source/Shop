import 'package:flutter/material.dart';

/// Login screen awaiting Firebase project configuration.
class LoginScreen extends StatelessWidget {
  /// Creates login screen.
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.storefront, size: 56), const Text('تسجيل الدخول', style: TextStyle(fontSize: 24)), const TextField(decoration: InputDecoration(labelText: 'البريد الإلكتروني')), const SizedBox(height: 12), const TextField(obscureText: true, decoration: InputDecoration(labelText: 'كلمة المرور')), const SizedBox(height: 20), const FilledButton(onPressed: null, child: Text('تسجيل الدخول'))])))));
}
