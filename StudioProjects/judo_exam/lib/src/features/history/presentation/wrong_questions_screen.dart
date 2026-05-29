import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../questions/application/question_providers.dart';
import '../../questions/domain/question.dart';
import '../../questions/presentation/question_session_screen.dart';
import '../../study/application/study_progress_controller.dart';

class WrongQuestionsScreen extends ConsumerWidget {
  const WrongQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = ref.watch(questionsProvider);
    final progress = ref.watch(studyProgressControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('間違えた問題')),
      body: questions.when(
        data: (items) => progress.when(
          data: (studyProgress) {
            final wrongQuestions = items
                .where((question) => studyProgress.isWrong(question.id))
                .toList(growable: false);

            if (wrongQuestions.isEmpty) {
              return const _EmptyWrongQuestions();
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: wrongQuestions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _QuestionTile(
                question: wrongQuestions[index],
                allQuestions: items,
              ),
            );
          },
          error: (error, stackTrace) => Center(child: Text('履歴の読み込みに失敗しました: $error')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => Center(child: Text('問題の読み込みに失敗しました: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({required this.question, required this.allQuestions});

  final Question question;
  final List<Question> allQuestions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(question.questionText),
        subtitle: Text(question.category.label),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          final index = allQuestions.indexWhere((item) => item.id == question.id);
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => QuestionSessionScreen(initialQuestionIndex: index),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyWrongQuestions extends StatelessWidget {
  const _EmptyWrongQuestions();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('間違えた問題はありません', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('不正解の問題があると、ここに復習リストとして保存されます。'),
          ],
        ),
      ),
    );
  }
}
