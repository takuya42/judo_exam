import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/shared_preferences_provider.dart';

final purchaseControllerProvider = AsyncNotifierProvider<PurchaseController, bool>(
  PurchaseController.new,
);

class PurchaseController extends AsyncNotifier<bool> {
  static const productId = 'unlock_all_questions';
  static const freeQuestionLimit = 30;
  static const _unlockAllQuestionsKey = 'unlock_all_questions_purchased';

  @override
  Future<bool> build() async {
    final preferences = await ref.watch(sharedPreferencesProvider.future);
    return preferences.getBool(_unlockAllQuestionsKey) ?? false;
  }

  Future<void> purchaseUnlockAllQuestions() async {
    state = const AsyncData(true);
    final preferences = await ref.read(sharedPreferencesProvider.future);
    await preferences.setBool(_unlockAllQuestionsKey, true);
  }
}
