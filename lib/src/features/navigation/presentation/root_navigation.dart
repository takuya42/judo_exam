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
  final _homeIconKey = GlobalKey<_HomeTabIconState>();
  var _barIndex = NavigationTab.home;
  var _homeTapInProgress = false;

  void _syncBarTo(int index) {
    if (_barIndex == index) return;
    _barIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _barKey.currentState?.animateTo(index);
    });
  }

  Future<void> _selectTab(int index) async {
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
    if (index == NavigationTab.home) {
      if (_homeTapInProgress) return;
      _homeTapInProgress = true;
      final pressAnimation =
          _homeIconKey.currentState?.press() ??
          Future<void>.delayed(const Duration(milliseconds: 180));
      await pressAnimation;
      _homeTapInProgress = false;
      if (!mounted) return;
    }
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
            style: TabStyle.fixedCircle,
            initialActiveIndex: selectedIndex,
            elevation: 0,
            height: 62,
            curveSize: 82,
            top: -18,
            backgroundColor: barColor,
            activeColor: activeColor,
            color: inactiveColor,
            onTap: _selectTab,
            items: [
              TabItem(
                icon: _AnimatedTabIcon(
                  icon: UniconsLine.clipboard_notes,
                  selected: selectedIndex == NavigationTab.requiredQuestions,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                title: '必修問題',
              ),
              TabItem(
                icon: _AnimatedTabIcon(
                  icon: Icons.public_outlined,
                  selected: selectedIndex == NavigationTab.questions,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                title: '問題',
              ),
              TabItem(
                icon: _HomeTabIcon(
                  key: _homeIconKey,
                  color: selectedIndex == NavigationTab.home
                      ? activeColor
                      : inactiveColor,
                ),
                title: 'ホーム',
              ),
              TabItem(
                icon: _AnimatedTabIcon(
                  icon: Icons.star_outline_rounded,
                  selected: selectedIndex == NavigationTab.favorites,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                title: 'お気に入り',
              ),
              TabItem(
                icon: _AnimatedTabIcon(
                  icon: Icons.settings_outlined,
                  selected: selectedIndex == NavigationTab.settings,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                title: '設定',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedTabIcon extends StatefulWidget {
  const _AnimatedTabIcon({
    required this.icon,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
  });

  final IconData icon;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;

  @override
  State<_AnimatedTabIcon> createState() => _AnimatedTabIconState();
}

class _AnimatedTabIconState extends State<_AnimatedTabIcon>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 260);
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _duration,
      value: widget.selected ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant _AnimatedTabIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(
        end: widget.selected ? widget.activeColor : widget.inactiveColor,
      ),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, color, child) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = Curves.easeOutBack.transform(_controller.value);
          final scale = TweenSequence<double>([
            TweenSequenceItem(
              tween: Tween<double>(begin: 0.95, end: 1.10),
              weight: 62,
            ),
            TweenSequenceItem(
              tween: Tween<double>(begin: 1.10, end: 1.0),
              weight: 38,
            ),
          ]).transform(_controller.value);
          return Transform.translate(
            offset: Offset(0, widget.selected ? 3 * (1 - progress) : 0),
            child: Transform.scale(
              scale: widget.selected ? scale : 1,
              child: Icon(widget.icon, color: color),
            ),
          );
        },
      ),
    );
  }
}

class _HomeTabIcon extends StatefulWidget {
  const _HomeTabIcon({super.key, required this.color});

  final Color color;

  @override
  State<_HomeTabIcon> createState() => _HomeTabIconState();
}

class _HomeTabIconState extends State<_HomeTabIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );

  Future<void> press() => _controller.forward(from: 0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.92),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.92, end: 1.0),
        weight: 55,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    return ScaleTransition(
      scale: scale,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: Icon(
          Icons.home_rounded,
          key: ValueKey(widget.color),
          color: widget.color,
        ),
      ),
    );
  }
}
