import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart' as apple;

import '../application/auth_providers.dart';

enum AuthScreenMode { signIn, signUp }

class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key, this.initialMode = AuthScreenMode.signIn});

  final AuthScreenMode initialMode;

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AuthScreenMode _mode = widget.initialMode;
  bool _isLoading = false;

  bool get _isCreating => _mode == AuthScreenMode.signUp;
  bool get _showsAppleSignIn => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

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
    } on AuthFailure catch (error) {
      _showError(error.message);
    } on Exception catch (error) {
      _showError('$error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authControllerProvider).signInWithGoogle();
      if (mounted) Navigator.of(context).pop();
    } on AuthCanceledException catch (error) {
      _showError(error.toString());
    } on AuthFailure catch (error) {
      _showError(error.message);
    } on Exception catch (error) {
      _showError('$error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authControllerProvider).signInWithApple();
      if (mounted) Navigator.of(context).pop();
    } on AuthCanceledException catch (error) {
      _showError(error.toString());
    } on AuthFailure catch (error) {
      _showError(error.message);
    } on Exception catch (error) {
      _showError('$error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('パスワード再設定用のメールアドレスを入力してください。');
      return;
    }
    try {
      await ref.read(authControllerProvider).sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('$email にパスワード再設定メールを送信しました。'),
        ),
      );
    } on AuthFailure catch (error) {
      _showError(error.message);
    } on Exception catch (error) {
      _showError('$error');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = _isCreating ? 'アカウントを作成' : 'おかえりなさい';
    final description = _isCreating ? '学習履歴をクラウドに保存して、国家試験対策を始めましょう。' : 'ログインして学習状況とプレミアム状態を同期します。';

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(title: Text(_isCreating ? '新規登録' : 'ログイン')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
            children: [
              Card(
                elevation: 0,
                color: _isCreating ? colorScheme.primaryContainer : colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: colorScheme.surface,
                        child: Icon(_isCreating ? Icons.person_add_alt_1_rounded : Icons.verified_user_outlined, color: colorScheme.primary),
                      ),
                      const SizedBox(height: 18),
                      Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(description, style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant, height: 1.5)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: colorScheme.outlineVariant),
                  elevation: 1,
                ),
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: const Icon(Icons.g_mobiledata_rounded, size: 30),
                label: Text(_isCreating ? 'Googleで登録' : 'Googleログイン'),
              ),
              if (_showsAppleSignIn) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: apple.SignInWithAppleButton(
                    borderRadius: const BorderRadius.all(Radius.circular(28)),
                    height: 52,
                    iconAlignment: apple.IconAlignment.center,
                    onPressed: _isLoading ? null : _signInWithApple,
                    style: apple.SignInWithAppleButtonStyle.black,
                    text: _isCreating ? 'Appleで登録' : 'Appleでログイン',
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('または', style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.mail_outline_rounded), labelText: 'メールアドレス'),
                        validator: (value) => value == null || !value.contains('@') ? '有効なメールアドレスを入力してください' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_outline_rounded), labelText: 'パスワード'),
                        validator: (value) => value == null || value.length < 6 ? '6文字以上で入力してください' : null,
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: _isCreating ? colorScheme.primary : colorScheme.tertiary,
                        ),
                        onPressed: _isLoading ? null : _submit,
                        icon: Icon(_isCreating ? Icons.person_add_alt_1_rounded : Icons.login_rounded),
                        label: Text(_isCreating ? 'メールアドレスで登録' : 'メールログイン'),
                      ),
                      if (!_isCreating) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _isLoading ? null : _resetPassword,
                          icon: const Icon(Icons.help_outline_rounded),
                          label: const Text('パスワード再設定'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: _isLoading ? null : () => setState(() => _mode = _isCreating ? AuthScreenMode.signIn : AuthScreenMode.signUp),
                child: Text(_isCreating ? 'すでにアカウントをお持ちの方' : '新規登録はこちら'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
