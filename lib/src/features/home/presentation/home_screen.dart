import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:judo_exam/src/shared/widgets/auto_size_text.dart';

import '../../announcements/application/announcement_providers.dart';
import '../../announcements/presentation/announcements_screen.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/auth_dialogs.dart';
import '../../navigation/application/navigation_provider.dart';
import '../../questions/application/question_providers.dart';
import '../../questions/domain/question.dart';
import '../../questions/domain/question_category.dart';
import '../../questions/domain/question_subcategory.dart';
import '../../questions/presentation/question_exam_screen.dart';
import '../../questions/presentation/subcategory_selection_screen.dart';
import '../../settings/application/settings_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final questionsAsync = ref.watch(questionsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('柔道整復師国試対策'),
        actions: [
          _AnnouncementButton(
            hasUnread: ref.watch(hasUnreadAnnouncementsProvider),
          ),
          IconButton(
            tooltip: '問題を再取得',
            onPressed: () {
              ref.invalidate(questionsProvider);
              ref.invalidate(announcementsProvider);
            },
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
      floatingActionButton: SizedBox(
        height: 48,
        child: FloatingActionButton.extended(
          onPressed: () => _startRandomExam(context, ref, questionsAsync),
          elevation: 2,
          highlightElevation: 3,
          extendedPadding: const EdgeInsets.symmetric(horizontal: 18),
          icon: const Icon(Icons.play_arrow_rounded, size: 21),
          label: const Text(
            '問題を解く',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _AnnouncementButton extends StatelessWidget {
  const _AnnouncementButton({required this.hasUnread});
  final bool hasUnread;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'お知らせ',
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AnnouncementsScreen()),
    ),
    icon: Badge(
      isLabelVisible: hasUnread,
      smallSize: 8,
      backgroundColor: Theme.of(context).colorScheme.error,
      child: const Icon(Icons.notifications_none_rounded),
    ),
  );
}

void _startRandomExam(
  BuildContext context,
  WidgetRef ref,
  AsyncValue<List<Question>> questionsAsync,
) {
  if (ref.read(authStateProvider).valueOrNull == null) {
    showLoginRequiredDialog(context, ref);
    return;
  }
  questionsAsync.whenData((questions) {
    final shuffled = ref
        .read(randomQuestionOrderProvider.notifier)
        .create(questions);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuestionExamScreen(
          questions: shuffled,
          title: 'ランダム出題',
        ),
      ),
    );
  });
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.questions});

  final List<Question> questions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryCounts = _categoryCounts(questions);
    // 未対応の必修科目はデータとして保持し、ホームの科目一覧だけから除外する。
    final visibleCategories = QuestionCategory.values
        .where((category) => category != QuestionCategory.unknownRequired)
        .toList(growable: false);
    final totalQuestionCount = questions.length;
    final learningSummary = ref.watch(learningDataControllerProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      children: [
        const _HeroCard(),
        const SizedBox(height: 16),
        _DashboardGrid(
          totalQuestionCount: totalQuestionCount,
          learnedQuestionCount: learningSummary.learnedQuestionCount,
          correctRate: learningSummary.correctRate,
          correctStreak: learningSummary.correctStreak,
        ),
        const SizedBox(height: 24),
        const _SectionHeader(
          icon: Icons.local_hospital_rounded,
          title: 'カテゴリ別学習',
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleCategories.length - (visibleCategories.length % 2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.42,
          ),
          itemBuilder: (context, index) {
            final category = visibleCategories[index];
            return _CategoryCard(
              category: category,
              questionCount: categoryCounts[category] ?? 0,
              onTap: () => _openCategory(context, ref, category),
            );
          },
        ),
        if (visibleCategories.length.isOdd) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 78,
            child: _CategoryCard(
              category: visibleCategories.last,
              questionCount: categoryCounts[visibleCategories.last] ?? 0,
              isWide: true,
              onTap: () => _openCategory(context, ref, visibleCategories.last),
            ),
          ),
        ],
        const SizedBox(height: 32),
        const _SectionHeader(
          icon: Icons.verified_rounded,
          title: 'カテゴリ別 正解率',
          subtitle: '解答データが蓄積されると科目別に自動更新されます',
        ),
        const SizedBox(height: 12),
        _AccuracyCard(categories: visibleCategories),
        const SizedBox(height: 24),
        const _LearningMenu(),
      ],
    );
  }

  void _openCategory(
    BuildContext context,
    WidgetRef ref,
    QuestionCategory category,
  ) {
    if (ref.read(authStateProvider).valueOrNull == null) {
      showLoginRequiredDialog(context, ref);
      return;
    }
    final categoryQuestions = questions
        .where((question) => question.category == category)
        .toList(growable: false);
    final subcategories = subcategoriesByCategory[category];
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => subcategories != null
            ? SubcategorySelectionScreen(
                category: category,
                questions: categoryQuestions,
                subcategories: subcategories,
              )
            : QuestionExamScreen(
                questions: categoryQuestions,
                title: category.label,
              ),
      ),
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
        color: const Color(0xFFF1F8F4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCEBE3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFDCEFE5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.health_and_safety_rounded,
              color: colorScheme.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '国家試験合格へ、\n今日の一問から。',
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '医療基礎から柔道整復理論まで、科目別に弱点を見える化して効率よく学習できます。',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardGrid extends StatelessWidget {
  const _DashboardGrid({
    required this.totalQuestionCount,
    required this.learnedQuestionCount,
    required this.correctRate,
    required this.correctStreak,
  });

  final int totalQuestionCount;
  final int learnedQuestionCount;
  final int correctRate;
  final int correctStreak;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.08,
      children: [
        _MetricCard(
          icon: Icons.library_books_rounded,
          label: '総問題数',
          value: '$totalQuestionCount',
        ),
        _MetricCard(
          icon: Icons.fact_check_rounded,
          label: '学習済み問題数',
          value: '$learnedQuestionCount',
        ),
        _MetricCard(
          icon: Icons.percent_rounded,
          label: '正解率',
          value: '$correctRate%',
        ),
        _MetricCard(
          icon: Icons.local_fire_department_rounded,
          label: '連続正解数',
          value: '$correctStreak',
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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _IconBadge(icon: icon, size: 42),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.1,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
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
    this.isWide = false,
  });

  final QuestionCategory category;
  final int questionCount;
  final VoidCallback onTap;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _MedicalCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 16 : 12,
            vertical: isWide ? 10 : 11,
          ),
          child: isWide
              ? Row(
                  children: [
                    _IconBadge(
                      icon: _categoryIcon(category),
                      size: 38,
                      circular: true,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        category.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$questionCount問',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _IconBadge(
                          icon: _categoryIcon(category),
                          size: 34,
                          circular: true,
                        ),
                        const Spacer(),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: AutoSizeText(
                          category.label,
                          maxLines: 2,
                          minFontSize: 12,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.18,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$questionCount問',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _AccuracyCard extends ConsumerWidget {
  const _AccuracyCard({required this.categories});

  final List<QuestionCategory> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learningSummary = ref.watch(learningDataControllerProvider);
    return _MedicalCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          for (final category in categories) ...[
            _AccuracyRow(
              category: category,
              accuracy: learningSummary.categoryCorrectRate(category),
            ),
            if (category != categories.last) const SizedBox(height: 12),
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
            _IconBadge(icon: _categoryIcon(category), size: 28, circular: true),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                category.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
            minHeight: 6,
            backgroundColor: const Color(0xFFE3F1EA),
          ),
        ),
      ],
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
            if (ref.read(authStateProvider).valueOrNull == null) {
              showLoginRequiredDialog(context, ref);
              return;
            }
            ref.read(questionsProvider).whenData((questions) {
              final shuffled = ref
                  .read(randomQuestionOrderProvider.notifier)
                  .create(questions);
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => QuestionExamScreen(
                    questions: shuffled,
                    title: 'ランダム出題',
                  ),
                ),
              );
            });
          },
        ),
        _MenuTile(
          icon: Icons.error_outline_rounded,
          title: '間違えた問題一覧',
          subtitle: '復習が必要な問題を確認します',
          onTap: () {
            if (ref.read(authStateProvider).valueOrNull == null) {
              showLoginRequiredDialog(context, ref);
              return;
            }
            ref.read(selectedTabIndexProvider.notifier).select(2);
          },
        ),
        _MenuTile(
          icon: Icons.star_rounded,
          title: 'お気に入り',
          subtitle: '保存した問題を復習します',
          onTap: () {
            if (ref.read(authStateProvider).valueOrNull == null) {
              showLoginRequiredDialog(context, ref);
              return;
            }
            ref.read(selectedTabIndexProvider.notifier).select(3);
          },
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
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconBadge(icon: icon, size: 30, circular: true),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle case final subtitle?) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withOpacity(0.78),
                  ),
                ),
              ],
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
        color: Color.alphaBlend(
          Theme.of(context).colorScheme.primary.withOpacity(0.018),
          Theme.of(context).colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    this.size = 44,
    this.circular = false,
  });

  final IconData icon;
  final double size;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F6EE),
        borderRadius: circular ? null : BorderRadius.circular(14),
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
        size: size * 0.55,
      ),
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
          Text('読み込み中...'),
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
    QuestionCategory.publicHealth => Icons.health_and_safety_rounded,
    QuestionCategory.clinicalMedicine => Icons.medical_services_rounded,
    QuestionCategory.surgery => Icons.healing_rounded,
    QuestionCategory.orthopedics => Icons.personal_injury_rounded,
    QuestionCategory.rehabilitationMedicine => Icons.wheelchair_pickup_rounded,
    QuestionCategory.judoTherapyTheory => Icons.sports_martial_arts_rounded,
    QuestionCategory.relatedLaws => Icons.gavel_rounded,
    QuestionCategory.unknownRequired => Icons.help_outline_rounded,
  };
}
