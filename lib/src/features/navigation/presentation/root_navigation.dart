import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../favorites/presentation/favorites_screen.dart';
import '../../history/presentation/study_history_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../questions/presentation/question_list_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../application/navigation_provider.dart';

class RootNavigation extends ConsumerWidget {
  const RootNavigation({super.key});

  static const _screens = <Widget>[
    HomeScreen(),
    QuestionListScreen(),
    StudyHistoryScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedTabIndexProvider);

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => ref
            .read(selectedTabIndexProvider.notifier)
            .select(index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz_outlined), label: '問題'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), label: '履歴'),
          BottomNavigationBarItem(icon: Icon(Icons.star_outline), label: 'お気に入り'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: '設定'),
        ],
      ),
    );
  }
}
