import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedTabIndexProvider = NotifierProvider<SelectedTabIndexNotifier, int>(
  SelectedTabIndexNotifier.new,
);

abstract final class NavigationTab {
  static const requiredQuestions = 0;
  static const questions = 1;
  static const home = 2;
  static const favorites = 3;
  static const settings = 4;
}

class SelectedTabIndexNotifier extends Notifier<int> {
  @override
  int build() => NavigationTab.home;

  void select(int index) {
    state = index;
  }
}
