import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../history/presentation/wrong_questions_screen.dart';
import '../../navigation/application/navigation_provider.dart';
import '../../questions/application/question_providers.dart';
import '../../questions/domain/question.dart';
import '../../questions/domain/question_category.dart';
import '../../questions/presentation/question_session_screen.dart';
import '../../study/application/study_progress_controller.dart';
import '../../study/domain/study_progress.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final questions = ref.watch(questionsProvider);
    final progress = ref.watch(studyProgressControllerProvider);
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
            _HeroCard(freeQuestionCount: freeQuestionCount),
            const SizedBox(height: 16),
            progress.maybeWhen(
              data: (studyProgress) => _StudyStatusCard(progress: studyProgress),
              orElse: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('クイック学習', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _MenuTile(
              icon: Icons.shuffle,
              title: 'ランダム20問',
              subtitle: '短時間でカテゴリ横断の演習をします',
              onTap: () => questions.maybeWhen(
                data: (items) => _startRandomPractice(context, items),
                orElse: () {},
              ),
            ),
            _MenuTile(
              icon: Icons.error_outline,
              title: '間違えた問題一覧',
              subtitle: '復習が必要な問題を確認します',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const WrongQuestionsScreen()),
              ),
            ),
            _MenuTile(
              icon: Icons.assignment,
              title: '模擬試験',
              subtitle: 'ランダム100問で本番形式の演習をします',
              onTap: () => ref.read(selectedTabIndexProvider.notifier).state = 4,
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
                    onTap: () {
                      ref.read(selectedCategoryProvider.notifier).state = category;
                      ref.read(selectedTabIndexProvider.notifier).state = 1;
                    },
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
          ],
        ),
      ),
    );
  }

  void _startRandomPractice(BuildContext context, List<Question> questions) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuestionSessionScreen(
          title: 'ランダム20問',
          sessionQuestions: pickRandomQuestions(questions, 20),
          showResultOnComplete: true,
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.freeQuestionCount});

  final String freeQuestionCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '国家試験合格に向けて学習を始めましょう',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            '無料問題 $freeQuestionCount 問からスタート。全問題解放は買い切り 1,500 円です。',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onPrimary,
                ),
          ),
        ],
      ),
    );
  }
}

class _StudyStatusCard extends StatelessWidget {
  const _StudyStatusCard({required this.progress});

  final StudyProgress progress;

  @override
  Widget build(BuildContext context) {
    final accuracy = (progress.accuracyRate * 100).toStringAsFixed(1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('学習状況', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.6,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _StatusItem(label: '総解答数', value: '${progress.answeredCount}'),
                _StatusItem(label: '正答率', value: '$accuracy%'),
                _StatusItem(label: 'お気に入り', value: '${progress.favoriteQuestionIds.length}'),
                _StatusItem(label: '間違えた問題', value: '${progress.wrongQuestionIds.length}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
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
