import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_and_catalog_provider.dart';

/// Firebase email/password login screen.
class LoginScreen extends StatefulWidget {
  /// Creates the login screen.
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }
  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await context.read<AuthAndCatalogProvider>().signIn(_email.text, _password.text);
  }
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: SingleChildScrollView(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: Padding(padding: const EdgeInsets.all(24), child: Consumer<AuthAndCatalogProvider>(builder: (context, state, child) => Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.storefront, size: 64, color: Color(0xFF4DB6AC)),
    const SizedBox(height: 18),
    Text('تسجيل الدخول', style: Theme.of(context).textTheme.headlineSmall),
    const SizedBox(height: 20),
    TextField(controller: _email, keyboardType: TextInputType.emailAddress, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email))),
    const SizedBox(height: 12),
    TextField(controller: _password, obscureText: true, textDirection: TextDirection.ltr, onSubmitted: (_) => state.busy ? null : _submit(), decoration: const InputDecoration(labelText: 'كلمة المرور', prefixIcon: Icon(Icons.lock))),
    if (state.errorMessage != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(state.errorMessage!, style: const TextStyle(color: Color(0xFFEF5350)))),
    const SizedBox(height: 20),
    SizedBox(width: double.infinity, child: FilledButton(onPressed: state.busy ? null : _submit, child: state.busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('دخول'))),
  ])))))));
}
