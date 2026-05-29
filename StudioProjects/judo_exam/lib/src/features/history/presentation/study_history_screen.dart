import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../study/application/study_progress_controller.dart';
import 'wrong_questions_screen.dart';

class StudyHistoryScreen extends ConsumerWidget {
  const StudyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(studyProgressControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('学習履歴')),
      body: progress.when(
        data: (studyProgress) {
          final accuracy = (studyProgress.accuracyRate * 100).toStringAsFixed(1);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('学習サマリー', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      _HistoryRow(label: '解答数', value: '${studyProgress.answeredCount} 問'),
                      _HistoryRow(label: '正解数', value: '${studyProgress.correctCount} 問'),
                      _HistoryRow(label: '不正解数', value: '${studyProgress.incorrectCount} 問'),
                      _HistoryRow(label: '正答率', value: '$accuracy %'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.error_outline),
                  title: const Text('間違えた問題一覧'),
                  subtitle: Text('${studyProgress.wrongQuestionIds.length} 問を復習できます'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const WrongQuestionsScreen()),
                  ),
                ),
              ),
            ],
          );
        },
        error: (error, stackTrace) => Center(child: Text('学習履歴の読み込みに失敗しました: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
