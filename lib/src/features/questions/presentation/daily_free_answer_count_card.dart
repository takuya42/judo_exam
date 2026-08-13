import 'package:flutter/material.dart';

import '../../settings/application/settings_providers.dart';

/// Shows the shared daily answer quota for free-plan users.
class DailyFreeAnswerCountCard extends StatelessWidget {
  const DailyFreeAnswerCountCard({
    super.key,
    required this.answeredCount,
  });

  final int answeredCount;

  @override
  Widget build(BuildContext context) {
    final displayedCount = answeredCount.clamp(0, freeDailyAnswerLimit);
    final hasReachedLimit = answeredCount >= freeDailyAnswerLimit;
    final progress = (displayedCount / freeDailyAnswerLimit).toDouble();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('今日の回答数', style: Theme.of(context).textTheme.labelLarge),
              const Spacer(),
              Text(
                '$displayedCount / $freeDailyAnswerLimit問',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          if (hasReachedLimit) ...[
            const SizedBox(height: 8),
            Text(
              '本日の無料回答上限に達しました',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
