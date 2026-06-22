import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_providers.dart';

class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isCreating = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final auth = ref.read(authControllerProvider);
      if (_isCreating) {
        await auth.createUserWithEmail(_emailController.text.trim(), _passwordController.text);
      } else {
        await auth.signInWithEmail(_emailController.text.trim(), _passwordController.text);
      }
      if (mounted) Navigator.of(context).pop();
    } on Exception catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('メールアドレスを入力してください')));
      return;
    }
    await ref.read(authControllerProvider).sendPasswordResetEmail(email);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('パスワード再設定メールを送信しました'),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('閉じる'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isCreating ? 'メールアドレスで登録' : 'メールアドレスでログイン')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'メールアドレス'),
              validator: (value) => value == null || !value.contains('@') ? '有効なメールアドレスを入力してください' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'パスワード'),
              validator: (value) => value == null || value.length < 6 ? '6文字以上で入力してください' : null,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: Text(_isCreating ? '登録' : 'ログイン'),
            ),
            TextButton(onPressed: _isLoading ? null : _resetPassword, child: const Text('パスワードを忘れた方はこちら')),
            TextButton(
              onPressed: () => setState(() => _isCreating = !_isCreating),
              child: Text(_isCreating ? 'ログイン画面へ' : '新規登録はこちら'),
            ),
          ],
        ),
      ),
    );
  }
}
