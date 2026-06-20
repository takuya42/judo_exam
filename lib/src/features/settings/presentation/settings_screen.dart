import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../navigation/application/navigation_provider.dart';
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
          _SettingsSection(
            title: 'アプリ',
            children: [
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'アプリについて',
                onTap: () => _showSimpleDialog(context, 'アプリについて',
                    '柔道整復師国家試験対策のための学習アプリです。'),
              ),
              _SettingsTile(
                icon: Icons.article_outlined,
                title: '利用規約',
                onTap: () => _showSimpleDialog(
                  context,
                  '利用規約',
                  '利用規約ページは準備中です。',
                ),
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'プライバシーポリシー',
                onTap: () => _showSimpleDialog(
                  context,
                  'プライバシーポリシー',
                  'プライバシーポリシーページは準備中です。',
                ),
              ),
              _SettingsTile(
                icon: Icons.mail_outline_rounded,
                title: 'お問い合わせ',
                onTap: () => _showSimpleDialog(
                  context,
                  'お問い合わせ',
                  'お問い合わせフォームは準備中です。',
                ),
              ),
              const _AppVersionTile(),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsSection(
            title: '学習データ',
            children: [
              _SettingsTile(
                icon: Icons.cloud_sync_outlined,
                title: '問題データ再取得',
                subtitle: 'Google Sheetsを再読み込みします',
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
          const SizedBox(height: 18),
          _SettingsSection(
            title: 'サポート',
            children: [
              _SettingsTile(
                icon: Icons.star_rate_outlined,
                title: 'アプリ評価する',
                onTap: () => _showSimpleDialog(
                  context,
                  'アプリ評価する',
                  'ストア評価ページは準備中です。',
                ),
              ),
              _SettingsTile(
                icon: Icons.new_releases_outlined,
                title: 'アップデート情報',
                onTap: () => _showSimpleDialog(
                  context,
                  'アップデート情報',
                  '最新のアップデート情報は準備中です。',
                ),
              ),
            ],
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

class _AppVersionTile extends StatelessWidget {
  const _AppVersionTile();

  static const _version = '1.0.0+1';

  @override
  Widget build(BuildContext context) {
    return const _SettingsTile(
      icon: Icons.verified_outlined,
      title: 'アプリバージョン',
      subtitle: _version,
      trailing: SizedBox.shrink(),
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
