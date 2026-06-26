import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/email_login_screen.dart';
import '../../navigation/application/navigation_provider.dart';
import '../../premium/presentation/premium_screen.dart';
import '../../questions/application/question_providers.dart';
import '../application/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _AccountSection(),
          const SizedBox(height: 18),
          _SettingsSection(
            title: 'アプリ',
            children: [
              _SettingsTile(
                icon: Icons.workspace_premium_outlined,
                title: '買い切り版',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PremiumScreen(),
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.article_outlined,
                title: '利用規約',
                onTap: () => _openUrl(
                  context,
                  url: _termsOfServiceUrl,
                  title: '利用規約',
                ),
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'プライバシーポリシー',
                onTap: () => _openUrl(
                  context,
                  url: _privacyPolicyUrl,
                  title: 'プライバシーポリシー',
                ),
              ),
              _SettingsTile(
                icon: Icons.comment,
                title: '問い合わせ',
                onTap: () => _openUrl(
                  context,
                  url: _inquiryUrl,
                  title: '問い合わせ',
                ),
              ),

            ],
          ),
          const SizedBox(height: 18),
          _SettingsSection(
            title: '学習データ',
            children: [
              _SettingsTile(
                icon: Icons.cloud_sync_outlined,
                title: '問題データ再取得',
                onTap: () {
                  ref.invalidate(questionsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('問題データを再取得しています')),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.delete_forever_outlined,
                title: '学習データリセット',
                subtitle: '正解率・履歴・お気に入りを削除します',
                isDestructive: true,
                onTap: () => _confirmReset(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsSection(
            title: '表示',
            children: const [_ThemeModeTile()],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('学習データをリセット'),
        content: const Text(
          '正解率、学習履歴、連続正解数、お気に入りを初期状態（0%）に戻します。\nこの操作は元に戻せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('リセットする'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(learningDataControllerProvider.notifier).resetLearningData();
    ref.read(selectedTabIndexProvider.notifier).select(0);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('学習データをリセットしました')),
    );
  }
}


class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    if (user == null) {
      return _SettingsSection(
        title: 'アカウント',
        children: [
          _SettingsTile(
            icon: Icons.g_mobiledata,
            title: 'Googleでログイン',
            onTap: () async {
              try {
                await ref.read(authControllerProvider).signInWithGoogle();
              } on Exception catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error is AuthFailure ? error.message : error.toString())));
              }
            },
          ),
          _SettingsTile(
            icon: Icons.mail_outline_rounded,
            title: 'メールアドレスでログイン',
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EmailLoginScreen())),
          ),
        ],
      );
    }
    return _SettingsSection(
      title: 'アカウント',
      children: [
        _SettingsTile(
          icon: Icons.person_outline_rounded,
          title: user.displayName?.isNotEmpty == true ? user.displayName! : 'ユーザー名未設定',
          subtitle: '${user.email ?? 'メールアドレス未設定'} ・ ${profile?.isPremium == true ? 'プレミアム会員' : '無料会員'}',
          trailing: const SizedBox.shrink(),
        ),
        _SettingsTile(
          icon: Icons.logout_rounded,
          title: 'ログアウト',
          onTap: () => ref.read(authControllerProvider).signOut(),
        ),
        _SettingsTile(
          icon: Icons.person_remove_outlined,
          title: 'アカウント削除（退会）',
          isDestructive: true,
          onTap: () => _confirmDeleteAccount(context, ref),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アカウントを削除しますか？'),
        content: const Text('学習履歴・お気に入り・正解率データは削除され復元できません'),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除する'),
          ),
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('キャンセル')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(learningDataControllerProvider.notifier).resetLearningData();
    await ref.read(authControllerProvider).deleteAccount();
    ref.read(selectedTabIndexProvider.notifier).select(0);
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = isDestructive ? colorScheme.error : colorScheme.onSurface;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (isDestructive ? colorScheme.error : colorScheme.primary)
              .withOpacity(0.1),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: foreground, size: 21),
      ),
      title: Text(
        title,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _ThemeModeTile extends ConsumerWidget {
  const _ThemeModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appSettingsControllerProvider);
    return _SettingsTile(
      icon: Icons.contrast_rounded,
      title: 'テーマ設定',
      subtitle: _themeModeLabel(themeMode),
      trailing: DropdownButton<ThemeMode>(
        value: themeMode,
        underline: const SizedBox.shrink(),
        items: ThemeMode.values
            .map(
              (mode) => DropdownMenuItem(
                value: mode,
                child: Text(_themeModeLabel(mode)),
              ),
            )
            .toList(),
        onChanged: (mode) {
          if (mode != null) {
            ref.read(appSettingsControllerProvider.notifier).setThemeMode(mode);
          }
        },
      ),
    );
  }
}

String _themeModeLabel(ThemeMode themeMode) {
  return switch (themeMode) {
    ThemeMode.light => 'ライト',
    ThemeMode.dark => 'ダーク',
    ThemeMode.system => 'システム',
  };
}
const _termsOfServiceUrl =
    'https://flutter-family.notion.site/387b5c1f2cef80149324c6928bd6822a';
const _privacyPolicyUrl =
    'https://flutter-family.notion.site/38ab5c1f2cef80bcacbeedab179063c9';
const _inquiryUrl =
'https://docs.google.com/forms/d/1vaIqVPMiI0e3fZBTrFsbQOs86IPVUdnYnd1fYW_cSHc/edit';

Future<void> _openUrl(
  BuildContext context, {
  required String url,
  required String title,
}) async {
  final uri = Uri.parse(url);
  if (!uri.hasScheme || uri.scheme != 'https' || uri.host.isEmpty) {
    _showUrlLaunchError(context, title);
    return;
  }

  try {
    final canLaunch = await canLaunchUrl(uri);
    debugPrint('canLaunchUrl($uri): $canLaunch');

    final launchedWithPlatformDefault = await launchUrl(uri);
    debugPrint(
      'launchUrl($uri, mode: ${LaunchMode.platformDefault.name}): '
      '$launchedWithPlatformDefault',
    );

    if (launchedWithPlatformDefault) {
      return;
    }

    final launchedWithExternalApplication = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    debugPrint(
      'launchUrl($uri, mode: ${LaunchMode.externalApplication.name}): '
      '$launchedWithExternalApplication',
    );

    if (!launchedWithExternalApplication && context.mounted) {
      _showUrlLaunchError(context, title);
    }
  } on Exception catch (error, stackTrace) {
    debugPrint('Failed to launch $uri: $error');
    debugPrintStack(stackTrace: stackTrace);
    if (context.mounted) {
      _showUrlLaunchError(context, title);
    }
  }
}

void _showUrlLaunchError(BuildContext context, String title) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$titleを開けませんでした。時間をおいて再度お試しください。')),
  );
}

Future<void> _showSimpleDialog(
  BuildContext context,
  String title,
  String message,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    ),
  );
}
