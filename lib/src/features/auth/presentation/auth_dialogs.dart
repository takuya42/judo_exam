import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../premium/presentation/premium_screen.dart';
import '../application/auth_providers.dart';
import 'email_login_screen.dart';

Future<void> showLoginRequiredDialog(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.school_outlined),
      title: const Text('ログインして学習を開始'),
      content: const Text('学習履歴・無料利用状況・プレミアム状態を保存するためログインが必要です。'),
      actions: [
        FilledButton.icon(
          onPressed: () async {
            Navigator.of(dialogContext).pop();
            try {
              await ref.read(authControllerProvider).signInWithGoogle();
            } on Exception catch (error) {
              if (!context.mounted) return;
              _showAuthError(context, error);
            }
          },
          icon: const Icon(Icons.g_mobiledata_rounded),
          label: const Text('Googleログイン'),
        ),
        TextButton.icon(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EmailLoginScreen()));
          },
          icon: const Icon(Icons.mail_outline_rounded),
          label: const Text('メールログイン'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EmailLoginScreen(initialMode: AuthScreenMode.signUp)));
          },
          child: const Text('新規登録'),
        ),
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('閉じる')),
      ],
    ),
  );
}

void _showAuthError(BuildContext context, Object error) {
  final message = error is AuthFailure ? error.message : error.toString();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      content: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
    ),
  );
}

Future<void> showFreeLimitDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('無料利用上限に達しました'),
      content: const Text('買い切り版で全問題を学習できます'),
      actions: [
        FilledButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PremiumScreen()));
          },
          child: const Text('買い切り版を見る'),
        ),
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('閉じる')),
      ],
    ),
  );
}
