import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../questions/application/question_providers.dart';
import '../../questions/domain/question.dart';
import '../../questions/presentation/question_exam_screen.dart';
import '../../settings/application/settings_providers.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionsProvider);
    final favorites = ref.watch(learningDataControllerProvider).favorites;

    return Scaffold(
      appBar: AppBar(title: const Text('お気に入り')),
      body: questionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('問題を取得できませんでした: $error')),
        data: (questions) {
          final favoriteQuestions = favorites
              .map((favorite) => _findQuestion(questions, favorite.questionId))
              .whereType<Question>()
              .toList(growable: false);

          if (favoriteQuestions.isEmpty) {
            return const _EmptyFavorites();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: favoriteQuestions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final question = favoriteQuestions[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.star_rounded),
                  title: Text(question.questionText),
                  subtitle: Text(question.category.label),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => QuestionExamScreen(
                        questions: [question],
                        title: 'お気に入り',
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

  Question? _findQuestion(List<Question> questions, String questionId) {
    for (final question in questions) {
      if (question.id == questionId) return question;
    }
    return null;
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
            Icon(Icons.star_outline, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('お気に入りはまだありません', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('問題画面の星ボタンから登録すると、ここから再学習できます。', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
