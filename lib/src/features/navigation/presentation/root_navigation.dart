import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    HomeScreen(),
    QuestionListScreen(),
    RequiredQuestionScreen(),
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
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
        ),
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          currentIndex: selectedIndex,
          onTap: (index) {
            final requiresLogin = index == 1 || index == 2 || index == 3;
            final user = ref.read(authStateProvider).valueOrNull;
            if (requiresLogin && user == null) {
              showLoginRequiredDialog(context, ref);
              return;
            }
            ref.read(selectedTabIndexProvider.notifier).select(index);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'ホーム',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.public_outlined),
              activeIcon: Icon(Icons.public_rounded),
              label: '問題',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.quiz_outlined),
              activeIcon: Icon(Icons.quiz),
              label: '必修問題',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star_outline_rounded),
              activeIcon: Icon(Icons.star_rounded),
              label: 'お気に入り',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: '設定',
            ),
          ],
        ),
      ),
    );
  }
}
