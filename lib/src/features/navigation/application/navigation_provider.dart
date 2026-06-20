import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedTabIndexProvider = NotifierProvider<SelectedTabIndexNotifier, int>(
  SelectedTabIndexNotifier.new,
);

class SelectedTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) {
    state = index;
  }
}
