import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicons/unicons.dart';

import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/auth_dialogs.dart';
import '../../favorites/presentation/favorites_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../questions/presentation/question_list_screen.dart';
import '../../questions/presentation/required_question_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../application/navigation_provider.dart';

class RootNavigation extends ConsumerWidget {
  const RootNavigation({super.key});

  static const _screens = <Widget>[
    RequiredQuestionScreen(),
    QuestionListScreen(),
    HomeScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedTabIndexProvider);

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: _screens),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            Theme.of(context).colorScheme.primary.withOpacity(0.06),
            Theme.of(context).colorScheme.surface,
          ),
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: ConvexAppBar(
            key: ValueKey(selectedIndex),
            style: TabStyle.fixedCircle,
            initialActiveIndex: selectedIndex,
            elevation: 0,
            height: 62,
            curveSize: 82,
            top: -18,
            backgroundColor: Color.alphaBlend(
              Theme.of(context).colorScheme.primary.withOpacity(0.06),
              Theme.of(context).colorScheme.surface,
            ),
            activeColor: Theme.of(context).colorScheme.primary,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(0.68),
            onTap: (index) {
              final requiresLogin =
                  index == NavigationTab.requiredQuestions ||
                  index == NavigationTab.questions ||
                  index == NavigationTab.favorites;
              final user = ref.read(authStateProvider).valueOrNull;
              if (requiresLogin && user == null) {
                showLoginRequiredDialog(context, ref);
                return;
              }
              ref.read(selectedTabIndexProvider.notifier).select(index);
            },
            items: const [
              TabItem(icon: UniconsLine.clipboard_notes, title: '必修問題'),
              TabItem(icon: Icons.public_outlined, title: '問題'),
              TabItem(icon: Icons.home_rounded, title: 'ホーム'),
              TabItem(icon: Icons.star_outline_rounded, title: 'お気に入り'),
              TabItem(icon: Icons.settings_outlined, title: '設定'),
            ],
          ),
        ),
      ),
    );
  }
}
