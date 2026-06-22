import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../premium/presentation/premium_screen.dart';
import '../application/auth_providers.dart';
import 'email_login_screen.dart';

Future<void> showLoginRequiredDialog(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('ログインして学習を開始'),
      content: const Text('学習履歴や正解率を保存するためログインが必要です'),
      actions: [
        TextButton(
          onPressed: () async {
            Navigator.of(dialogContext).pop();
            await ref.read(authControllerProvider).signInWithGoogle();
          },
          child: const Text('Googleログイン'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EmailLoginScreen()));
          },
          child: const Text('メールログイン'),
        ),
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('閉じる')),
      ],
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
