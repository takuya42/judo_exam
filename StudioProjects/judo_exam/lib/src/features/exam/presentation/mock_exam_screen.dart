import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../questions/application/question_providers.dart';
import '../../questions/domain/question.dart';
import '../../questions/presentation/question_session_screen.dart';

class MockExamScreen extends ConsumerWidget {
  const MockExamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = ref.watch(questionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('模擬試験')),
      body: questions.when(
        data: (items) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ランダム100問 模擬試験',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    const Text('CSVの問題から最大100問をランダム出題し、終了後に成績を表示します。'),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: items.isEmpty ? null : () => _startExam(context, items),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('模擬試験を開始'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        error: (error, stackTrace) => Center(child: Text('問題の読み込みに失敗しました: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _startExam(BuildContext context, List<Question> items) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuestionSessionScreen(
          title: '模擬試験',
          sessionQuestions: pickRandomQuestions(items, 100),
          showResultOnComplete: true,
          recordStudyProgress: false,
        ),
      ),
    );
  }
}
