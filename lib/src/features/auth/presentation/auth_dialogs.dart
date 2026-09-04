import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart' as apple;

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
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
          SizedBox(
            width: 240,
            child: apple.SignInWithAppleButton(
              onPressed: () async {
                try {
                  await ref.read(authControllerProvider).signInWithApple();
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                } on AuthCanceledException {
                  // A cancellation is an intentional exit from the Apple sheet.
                } on Exception catch (error) {
                  if (!context.mounted) return;
                  _showAuthError(context, error);
                }
              },
              style: apple.SignInWithAppleButtonStyle.black,
              text: 'Appleでログイン',
            ),
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
      title: const Text('本日の無料問題数に達しました'),
      content: const Text('無料プランでは1日20問まで回答できます。\nプレミアムなら問題数の制限なく学習できます。'),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('閉じる')),
        FilledButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PremiumScreen()));
          },
          child: const Text('プレミアムを見る'),
        ),
      ],
    ),
  );
}

/// Explains that the required exam is a premium-only feature.
Future<void> showRequiredExamPremiumDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _RequiredExamPremiumDialog(
      onViewPremium: () {
        Navigator.of(dialogContext).pop();
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const PremiumScreen()),
        );
      },
    ),
  );
}

class _RequiredExamPremiumDialog extends StatelessWidget {
  const _RequiredExamPremiumDialog({required this.onViewPremium});

  final VoidCallback onViewPremium;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        size: 30,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '必修問題はプレミアム限定',
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'プレミアムなら必修問題50問に挑戦できます',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: onViewPremium,
                      child: const Text(
                        'プレミアムプランを見る',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: IconButton(
                tooltip: '閉じる',
                visualDensity: VisualDensity.compact,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
