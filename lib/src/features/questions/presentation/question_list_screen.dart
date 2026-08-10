import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/question_providers.dart';
import '../domain/question.dart';
import 'question_exam_screen.dart';

class QuestionListScreen extends ConsumerWidget {
  const QuestionListScreen({super.key, this.questions, this.title = '問題'});

  final List<Question>? questions;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = questions == null
        ? ref.watch(questionsProvider)
        : AsyncValue<List<Question>>.data(questions!);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: questionsAsync.when(
        loading: () => const _LoadingQuestions(),
        error: (error, _) => _QuestionLoadError(error: error),
        data: (questions) {
          if (questions.isEmpty) {
            return const _EmptyQuestionList();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: questions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final question = questions[index];
              return Card(
                child: ListTile(
                  title: Text(question.questionText),
                  subtitle: Text(
                    '${question.category.label} / '
                    '${question.isPremium ? '有料' : '無料'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => QuestionExamScreen(
                        questions: [question],
                        title: title,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyQuestionList extends StatelessWidget {
  const _EmptyQuestionList();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('表示できる問題がありません。', textAlign: TextAlign.center),
      ),
    );
  }
}

class _LoadingQuestions extends StatelessWidget {
  const _LoadingQuestions();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('読み込み中...'),
        ],
      ),
    );
  }
}

class _QuestionLoadError extends ConsumerWidget {
  const _QuestionLoadError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '問題を取得できませんでした',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.invalidate(questionsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }
}
