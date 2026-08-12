import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:judo_exam/core/constants/iap_constants.dart';

import '../../auth/application/auth_providers.dart';
import '../../settings/application/settings_providers.dart';

final inAppPurchaseProvider = Provider<InAppPurchase>((ref) => InAppPurchase.instance);

final premiumControllerProvider =
    StateNotifierProvider<PremiumController, PremiumState>((ref) {
  final controller = PremiumController(
    inAppPurchase: ref.watch(inAppPurchaseProvider),
    preferences: ref.watch(sharedPreferencesProvider),
    syncAccount: (isPremium) =>
        ref.read(authControllerProvider).setPremium(isPremium),
  );
  unawaited(controller.initialize());
  return controller;
});

/// The single entitlement used by both feature gates and presentation.
final isPremiumProvider = Provider<bool>(
  (ref) => ref.watch(premiumControllerProvider.select((state) => state.isPremium)),
);

final premiumMembershipLabelProvider = Provider<String>(
  (ref) => ref.watch(isPremiumProvider) ? 'プレミアム利用中' : '無料会員',
);

class PremiumState {
  const PremiumState({
    required this.isPremium,
    this.isLoading = true,
    this.isPurchasePending = false,
    this.product,
    this.message,
    this.messageId = 0,
  });

  final bool isPremium;
  final bool isLoading;
  final bool isPurchasePending;
  final ProductDetails? product;
  final String? message;
  final int messageId;

  bool get isBusy => isLoading || isPurchasePending;

  PremiumState copyWith({
    bool? isPremium,
    bool? isLoading,
    bool? isPurchasePending,
    ProductDetails? product,
    String? message,
    bool clearMessage = false,
    int? messageId,
  }) =>
      PremiumState(
        isPremium: isPremium ?? this.isPremium,
        isLoading: isLoading ?? this.isLoading,
        isPurchasePending: isPurchasePending ?? this.isPurchasePending,
        product: product ?? this.product,
        message: clearMessage ? null : message ?? this.message,
        messageId: messageId ?? this.messageId,
      );
}

class PremiumController extends StateNotifier<PremiumState> {
  PremiumController({
    required InAppPurchase inAppPurchase,
    required SharedPreferences preferences,
    required Future<void> Function(bool) syncAccount,
  })  : _inAppPurchase = inAppPurchase,
        _preferences = preferences,
        _syncAccount = syncAccount,
        super(PremiumState(isPremium: preferences.getBool(_premiumKey) == true));

  static const _premiumKey = 'premium_entitlement';

  final InAppPurchase _inAppPurchase;
  final SharedPreferences _preferences;
  final Future<void> Function(bool) _syncAccount;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Future<void> initialize() async {
    _subscription ??= _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (_) {
        state = state.copyWith(isPurchasePending: false);
        _notify('購入情報の更新に失敗しました。時間をおいて再度お試しください。');
      },
    );
    await loadProduct();
    // Non-consumable purchases are restored at startup so a reinstall or a new
    // device updates the same entitlement observed throughout the app.
    try {
      await _inAppPurchase.restorePurchases();
    } catch (_) {
      // Product loading and manual restore remain available if startup restore
      // cannot reach the store.
    }
  }

  Future<void> loadProduct() async {
    state = state.copyWith(isLoading: true);
    try {
      if (!await _inAppPurchase.isAvailable()) {
        _notify('ストアに接続できません。時間をおいて再度お試しください。');
        return;
      }
      final response = await _inAppPurchase.queryProductDetails({
        IapConstants.premiumProductId,
      });
      if (response.error != null) {
        _notify('商品情報の取得に失敗しました。${response.error!.message}');
      } else if (response.productDetails.isEmpty) {
        _notify('買い切り版の商品情報が見つかりませんでした。');
      } else {
        state = state.copyWith(product: response.productDetails.first);
      }
    } catch (_) {
      _notify('商品情報の取得に失敗しました。時間をおいて再度お試しください。');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> purchase() async {
    final product = state.product;
    if (product == null) {
      _notify('商品情報を取得中です。しばらくしてから再度お試しください。');
      await loadProduct();
      return;
    }
    state = state.copyWith(isPurchasePending: true);
    try {
      final started = await _inAppPurchase.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) {
        state = state.copyWith(isPurchasePending: false);
        _notify('購入処理を開始できませんでした。時間をおいて再度お試しください。');
      }
    } catch (_) {
      state = state.copyWith(isPurchasePending: false);
      _notify('購入処理に失敗しました。時間をおいて再度お試しください。');
    }
  }

  Future<void> restore() async {
    state = state.copyWith(isPurchasePending: true);
    try {
      await _inAppPurchase.restorePurchases();
      state = state.copyWith(isPurchasePending: false);
      _notify('購入の復元を確認しています。');
    } catch (_) {
      state = state.copyWith(isPurchasePending: false);
      _notify('購入の復元に失敗しました。時間をおいて再度お試しください。');
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != IapConstants.premiumProductId) continue;
      if (purchase.status == PurchaseStatus.pending) {
        state = state.copyWith(isPurchasePending: true);
        continue;
      }
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        state = state.copyWith(isPremium: true, isPurchasePending: false);
        await _preferences.setBool(_premiumKey, true);
        try {
          await _syncAccount(true);
        } catch (_) {
          // The store entitlement is device-wide and remains valid even when
          // there is no signed-in account or account syncing is unavailable.
        }
        _notify(purchase.status == PurchaseStatus.restored
            ? '購入を復元しました。'
            : '購入が完了しました。');
      } else if (purchase.status == PurchaseStatus.error) {
        state = state.copyWith(isPurchasePending: false);
        _notify(purchase.error?.message ?? '購入処理中にエラーが発生しました。');
      } else if (purchase.status == PurchaseStatus.canceled) {
        state = state.copyWith(isPurchasePending: false);
        _notify('購入がキャンセルされました。');
      }
      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  void _notify(String message) {
    state = state.copyWith(message: message, messageId: state.messageId + 1);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
