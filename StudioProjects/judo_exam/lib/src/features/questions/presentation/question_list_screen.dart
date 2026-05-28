import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/question_providers.dart';
import 'question_session_screen.dart';

class QuestionListScreen extends ConsumerWidget {
  const QuestionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = ref.watch(questionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('問題一覧')),
      body: questions.when(
        data: (items) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return FilledButton.icon(
                onPressed: items.isEmpty ? null : () => _openSession(context),
                icon: const Icon(Icons.play_arrow),
                label: const Text('最初から解く'),
              );
            }

            final questionIndex = index - 1;
            final question = items[questionIndex];
            return Card(
              child: ListTile(
                title: Text(question.questionText),
                subtitle: Text(
                  '${question.category.label} / ${question.isPremium ? '有料' : '無料'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openSession(context, initialQuestionIndex: questionIndex),
              ),
            );
          },
        ),
        error: (error, stackTrace) => Center(child: Text('問題の読み込みに失敗しました: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _openSession(BuildContext context, {int initialQuestionIndex = 0}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuestionSessionScreen(
          initialQuestionIndex: initialQuestionIndex,
        ),
      ),
    );
  }
}
