import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/application/settings_providers.dart';

class StudyHistoryScreen extends ConsumerWidget {
  const StudyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(learningDataControllerProvider).history;

    return Scaffold(
      appBar: AppBar(title: const Text('学習履歴')),
      body: history.isEmpty
          ? const _EmptyState(
              icon: Icons.history,
              title: '学習履歴はまだありません',
              message: '問題に解答すると、回答日時・正誤・カテゴリが最新順で表示されます。',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = history[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      entry.isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: entry.isCorrect
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                    ),
                    title: Text(entry.questionText, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${entry.category.label} / ${_formatDateTime(entry.answeredAt)}'),
                    trailing: Text(entry.isCorrect ? '正解' : '不正解'),
                  ),
                );
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime dateTime) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${dateTime.year}/${two(dateTime.month)}/${two(dateTime.day)} ${two(dateTime.hour)}:${two(dateTime.minute)}';
}
