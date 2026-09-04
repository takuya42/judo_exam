import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_exam/src/features/navigation/application/navigation_provider.dart';

void main() {
  test('navigation indices match the displayed tab order and start at home', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(NavigationTab.requiredQuestions, 0);
    expect(NavigationTab.questions, 1);
    expect(NavigationTab.home, 2);
    expect(NavigationTab.favorites, 3);
    expect(NavigationTab.settings, 4);
    expect(container.read(selectedTabIndexProvider), NavigationTab.home);
  });
}
