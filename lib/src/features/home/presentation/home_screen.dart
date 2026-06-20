import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../navigation/application/navigation_provider.dart';
import '../../questions/application/question_providers.dart';
import '../../questions/domain/question.dart';
import '../../questions/domain/question_category.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final questionsAsync = ref.watch(questionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      appBar: AppBar(
        title: const Text('柔道整復師国試対策'),
        actions: [
          IconButton(
            tooltip: '問題を再取得',
            onPressed: () => ref.invalidate(questionsProvider),
            icon: const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: questionsAsync.when(
          loading: () => const _LoadingHome(),
          error: (error, _) => _HomeLoadError(error: error),
          data: (questions) => _HomeContent(questions: questions),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(selectedQuestionCategoryProvider.notifier).state = null;
          ref.read(selectedTabIndexProvider.notifier).state = 1;
        },
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('問題を解く'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.questions});

  final List<Question> questions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryCounts = _categoryCounts(questions);
    final totalQuestionCount = questions.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        const _HeroCard(),
        const SizedBox(height: 16),
        _DashboardGrid(totalQuestionCount: totalQuestionCount),
        const SizedBox(height: 24),
        _SectionHeader(
          icon: Icons.local_hospital_rounded,
          title: 'カテゴリ別学習',
          subtitle: 'Google Sheetsから取得した問題を科目別に集計',
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: QuestionCategory.values.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) {
            final category = QuestionCategory.values[index];
            return _CategoryCard(
              category: category,
              questionCount: categoryCounts[category] ?? 0,
              onTap: () {
                ref.read(selectedQuestionCategoryProvider.notifier).state =
                    category;
                ref.read(selectedTabIndexProvider.notifier).state = 1;
              },
            );
          },
        ),
        const SizedBox(height: 24),
        const _SectionHeader(
          icon: Icons.verified_rounded,
          title: 'カテゴリ別 正解率',
          subtitle: '解答データが蓄積されると科目別に自動更新されます',
        ),
        const SizedBox(height: 12),
        _AccuracyCard(categories: QuestionCategory.values),
        const SizedBox(height: 24),
        const _SectionHeader(
          icon: Icons.auto_graph_rounded,
          title: '今後の拡張エリア',
          subtitle: '学習状況をより詳しく可視化するためのスペース',
        ),
        const SizedBox(height: 12),
        const _ExpansionGrid(),
        const SizedBox(height: 24),
        const _LearningMenu(),
      ],
    );
  }

  Map<QuestionCategory, int> _categoryCounts(List<Question> questions) {
    final counts = {for (final category in QuestionCategory.values) category: 0};
    for (final question in questions) {
      counts[question.category] = (counts[question.category] ?? 0) + 1;
    }
    return counts;
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF00795A), Color(0xFF21A67A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00795A).withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '国家試験合格へ、\n今日の一問から。',
            style: textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '医療基礎から柔道整復理論まで、科目別に弱点を見える化して効率よく学習できます。',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary.withOpacity(0.88),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardGrid extends StatelessWidget {
  const _DashboardGrid({required this.totalQuestionCount});

  final int totalQuestionCount;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _MetricCard(
          icon: Icons.library_books_rounded,
          label: '総問題数',
          value: '$totalQuestionCount問',
        ),
        const _MetricCard(
          icon: Icons.fact_check_rounded,
          label: '学習済み問題数',
          value: '0問',
        ),
        const _MetricCard(
          icon: Icons.percent_rounded,
          label: '正解率',
          value: '0%',
        ),
        const _MetricCard(
          icon: Icons.local_fire_department_rounded,
          label: '連続正解数',
          value: '0問',
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _MedicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _IconBadge(icon: icon),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.questionCount,
    required this.onTap,
  });

  final QuestionCategory category;
  final int questionCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _MedicalCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _IconBadge(icon: _categoryIcon(category), size: 38),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                category.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$questionCount問',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccuracyCard extends StatelessWidget {
  const _AccuracyCard({required this.categories});

  final List<QuestionCategory> categories;

  @override
  Widget build(BuildContext context) {
    return _MedicalCard(
      child: Column(
        children: [
          for (final category in categories) ...[
            _AccuracyRow(category: category, accuracy: 0),
            if (category != categories.last) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _AccuracyRow extends StatelessWidget {
  const _AccuracyRow({required this.category, required this.accuracy});

  final QuestionCategory category;
  final int accuracy;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          children: [
            Icon(_categoryIcon(category), size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(category.label)),
            Text(
              '$accuracy%',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: accuracy / 100,
            minHeight: 8,
            backgroundColor: const Color(0xFFE3F1EA),
          ),
        ),
      ],
    );
  }
}

class _ExpansionGrid extends StatelessWidget {
  const _ExpansionGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      childAspectRatio: 3.2,
      children: const [
        _ExpansionCard(icon: Icons.show_chart_rounded, title: '正解率推移グラフ'),
        _ExpansionCard(icon: Icons.schedule_rounded, title: '学習時間'),
        _ExpansionCard(icon: Icons.emoji_events_rounded, title: 'ランキング'),
      ],
    );
  }
}

class _ExpansionCard extends StatelessWidget {
  const _ExpansionCard({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return _MedicalCard(
      child: Row(
        children: [
          _IconBadge(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '近日公開予定',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.more_horiz_rounded),
        ],
      ),
    );
  }
}

class _LearningMenu extends ConsumerWidget {
  const _LearningMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          icon: Icons.menu_book_rounded,
          title: '学習メニュー',
          subtitle: '既存機能へすばやくアクセス',
        ),
        const SizedBox(height: 12),
        _MenuTile(
          icon: Icons.shuffle_rounded,
          title: 'ランダム出題',
          subtitle: 'カテゴリ横断で4択問題を出題します',
          onTap: () {
            ref.read(selectedQuestionCategoryProvider.notifier).state = null;
            ref.read(selectedTabIndexProvider.notifier).state = 1;
          },
        ),
        _MenuTile(
          icon: Icons.error_outline_rounded,
          title: '間違えた問題一覧',
          subtitle: '復習が必要な問題を確認します',
          onTap: () => ref.read(selectedTabIndexProvider.notifier).state = 2,
        ),
        _MenuTile(
          icon: Icons.assignment_rounded,
          title: '模擬試験',
          subtitle: '本番形式の演習を開始します',
          onTap: () => ref.read(selectedTabIndexProvider.notifier).state = 4,
        ),
      ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _MedicalCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: _IconBadge(icon: icon),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconBadge(icon: icon, size: 34),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MedicalCard extends StatelessWidget {
  const _MedicalCard({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F2ED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, this.size = 44});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F6EE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: size * 0.55),
    );
  }
}

class _LoadingHome extends StatelessWidget {
  const _LoadingHome();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Google Sheetsから学習データを取得しています...'),
        ],
      ),
    );
  }
}

class _HomeLoadError extends ConsumerWidget {
  const _HomeLoadError({required this.error});

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
              Icons.cloud_off_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text('問題数を取得できませんでした', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.invalidate(questionsProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _categoryIcon(QuestionCategory category) {
  return switch (category) {
    QuestionCategory.anatomy => Icons.accessibility_new_rounded,
    QuestionCategory.physiology => Icons.monitor_heart_rounded,
    QuestionCategory.kinesiology => Icons.directions_run_rounded,
    QuestionCategory.pathology => Icons.biotech_rounded,
    QuestionCategory.clinicalMedicine => Icons.medical_services_rounded,
    QuestionCategory.surgery => Icons.healing_rounded,
    QuestionCategory.orthopedics => Icons.personal_injury_rounded,
    QuestionCategory.rehabilitationMedicine => Icons.wheelchair_pickup_rounded,
    QuestionCategory.judoTherapyTheory => Icons.sports_martial_arts_rounded,
    QuestionCategory.relatedLaws => Icons.gavel_rounded,
  };
}
