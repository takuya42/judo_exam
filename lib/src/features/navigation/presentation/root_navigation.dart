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

class RootNavigation extends ConsumerStatefulWidget {
  const RootNavigation({super.key});

  @override
  ConsumerState<RootNavigation> createState() => _RootNavigationState();
}

class _RootNavigationState extends ConsumerState<RootNavigation> {
  static const _screenTransitionDuration = Duration(milliseconds: 220);
  static const _screens = <Widget>[
    RequiredQuestionScreen(),
    QuestionListScreen(),
    HomeScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  final _barKey = GlobalKey<ConvexAppBarState>();
  var _barIndex = NavigationTab.home;

  void _syncBarTo(int index) {
    if (_barIndex == index) return;
    _barIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _barKey.currentState?.animateTo(index);
    });
  }

  void _selectTab(int index) {
    final selectedIndex = ref.read(selectedTabIndexProvider);
    final requiresLogin =
        index == NavigationTab.requiredQuestions ||
        index == NavigationTab.questions ||
        index == NavigationTab.favorites;
    final user = ref.read(authStateProvider).valueOrNull;
    if (requiresLogin && user == null) {
      _barIndex = selectedIndex;
      _barKey.currentState?.animateTo(selectedIndex);
      if (mounted) showLoginRequiredDialog(context, ref);
      return;
    }

    // ConvexAppBar already animates its own selection. Remembering the index
    // prevents the provider listener from starting that animation a second time.
    _barIndex = index;
    ref.read(selectedTabIndexProvider.notifier).select(index);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedTabIndexProvider);
    ref.listen<int>(selectedTabIndexProvider, (_, next) => _syncBarTo(next));

    final colors = Theme.of(context).colorScheme;
    final activeColor = colors.primary;
    final inactiveColor = colors.onSurfaceVariant.withOpacity(0.68);
    final barColor = Color.alphaBlend(
      activeColor.withOpacity(0.06),
      colors.surface,
    );

    return Scaffold(
      body: AnimatedSwitcher(
        duration: _screenTransitionDuration,
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.012),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(selectedIndex),
          child: _screens[selectedIndex],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: barColor,
          border: Border(
            top: BorderSide(color: colors.outlineVariant.withOpacity(0.5)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: ConvexAppBar(
            key: _barKey,
            style: TabStyle.reactCircle,
            initialActiveIndex: selectedIndex,
            elevation: 0,
            height: 60,
            curveSize: 52,
            top: -12,
            backgroundColor: barColor,
            activeColor: activeColor,
            color: inactiveColor,
            onTap: _selectTab,
            items: const [
              TabItem(
                icon: UniconsLine.clipboard_notes,
                title: '必修問題',
              ),
              TabItem(
                icon: Icons.public_outlined,
                title: '問題',
              ),
              TabItem(icon: Icons.home_rounded, title: 'ホーム'),
              TabItem(
                icon: Icons.star_outline_rounded,
                title: 'お気に入り',
              ),
              TabItem(
                icon: Icons.settings_outlined,
                title: '設定',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
