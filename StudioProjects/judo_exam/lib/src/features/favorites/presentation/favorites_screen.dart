import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../questions/application/question_providers.dart';
import '../../questions/domain/question.dart';
import '../../questions/presentation/question_session_screen.dart';
import '../../study/application/study_progress_controller.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = ref.watch(questionsProvider);
    final progress = ref.watch(studyProgressControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('お気に入り')),
      body: questions.when(
        data: (items) => progress.when(
          data: (studyProgress) {
            final favoriteQuestions = items
                .where((question) => studyProgress.isFavorite(question.id))
                .toList(growable: false);

            if (favoriteQuestions.isEmpty) {
              return const _EmptyFavorites();
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favoriteQuestions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _FavoriteQuestionTile(
                question: favoriteQuestions[index],
                allQuestions: items,
              ),
            );
          },
          error: (error, stackTrace) => Center(child: Text('お気に入りの読み込みに失敗しました: $error')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => Center(child: Text('問題の読み込みに失敗しました: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _FavoriteQuestionTile extends ConsumerWidget {
  const _FavoriteQuestionTile({required this.question, required this.allQuestions});

  final Question question;
  final List<Question> allQuestions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        title: Text(question.questionText),
        subtitle: Text(question.category.label),
        leading: IconButton(
          icon: const Icon(Icons.star),
          tooltip: 'お気に入り解除',
          onPressed: () => ref
              .read(studyProgressControllerProvider.notifier)
              .toggleFavorite(question.id),
        ),
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

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_outline,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('お気に入りはまだありません', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              '問題画面の星アイコンから復習したい問題を登録できます。',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
