import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../navigation/application/navigation_provider.dart';
import '../../questions/application/question_providers.dart';
import '../../questions/domain/question_category.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final freeQuestionCount = ref.watch(freeQuestionCountProvider).maybeWhen(
          data: (count) => count.toString(),
          orElse: () => '-',
        );

    return Scaffold(
      appBar: AppBar(title: const Text('柔道整復師国試対策')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '国家試験合格に向けて学習を始めましょう',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '無料問題 $freeQuestionCount 問からスタート。全問題解放は買い切り 1,500 円です。',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () =>
                          ref.read(selectedTabIndexProvider.notifier).state = 1,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('問題を解く'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('カテゴリ', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: QuestionCategory.values.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.3,
              ),
              itemBuilder: (context, index) {
                final category = QuestionCategory.values[index];
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () =>
                        ref.read(selectedTabIndexProvider.notifier).state = 1,
                    child: Center(
                      child: Text(
                        category.label,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text('学習メニュー', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _MenuTile(
              icon: Icons.shuffle,
              title: 'ランダム出題',
              subtitle: 'カテゴリ横断で4択問題を出題します',
              onTap: () =>
                  ref.read(selectedTabIndexProvider.notifier).state = 1,
            ),
            _MenuTile(
              icon: Icons.error_outline,
              title: '間違えた問題一覧',
              subtitle: '復習が必要な問題を確認します',
              onTap: () =>
                  ref.read(selectedTabIndexProvider.notifier).state = 2,
            ),
            _MenuTile(
              icon: Icons.assignment,
              title: '模擬試験',
              subtitle: '本番形式の演習を開始します',
              onTap: () =>
                  ref.read(selectedTabIndexProvider.notifier).state = 4,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
