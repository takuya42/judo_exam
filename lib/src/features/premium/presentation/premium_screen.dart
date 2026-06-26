import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:judo_exam/core/constants/iap_constants.dart';

import '../../auth/application/auth_providers.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  ProductDetails? _premiumProduct;
  bool _isLoading = true;
  bool _isPurchasePending = false;

  bool get _isBusy => _isLoading || _isPurchasePending;

  @override
  void initState() {
    super.initState();
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        _showSnackBar('購入情報の更新に失敗しました。時間をおいて再度お試しください。');
        if (mounted) setState(() => _isPurchasePending = false);
      },
    );
    _loadPremiumProduct();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    if (profile?.isPremium == true) {
      return Scaffold(
        appBar: AppBar(title: const Text('買い切り版')),
        body: const Center(child: Text('買い切り版を利用中です')),
      );
    }

    const benefits = ['全問題解放', '回答回数無制限', '学習履歴保存', 'お気に入り保存', '正解率分析', '今後追加される問題も利用可能'];
    return Scaffold(
      backgroundColor: const Color(0xFFF3FBF7),
      appBar: AppBar(title: const Text('買い切り版')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF006C52), Color(0xFF1BAE7F)]),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: const Color(0xFF006C52).withOpacity(0.24), blurRadius: 28, offset: const Offset(0, 16))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 44),
                const SizedBox(height: 18),
                Text('買い切り版で全問題を学習', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Text('国家試験対策を最後まで続けられるプレミアムプラン', style: TextStyle(color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFD3EDE2))),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  for (final benefit in benefits)
                    ListTile(
                      leading: const Icon(Icons.check_circle_rounded, color: Color(0xFF008765)),
                      title: Text(benefit, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  const Divider(height: 28),
                  Text(_premiumProduct?.price ?? '1,500円（税込）', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: const Color(0xFF006C52))),
                  const SizedBox(height: 14),
                  if (_isBusy) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 14),
                  ],
                  FilledButton.icon(
                    onPressed: _isBusy ? null : _purchasePremium,
                    icon: const Icon(Icons.lock_open_rounded),
                    label: const Text('買い切り版を購入'),
                  ),
                  TextButton(onPressed: _isBusy ? null : _restorePurchase, child: const Text('購入を復元')),
                  const SizedBox(height: 8),
                  const Text('一度購入すると追加料金は発生しません'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadPremiumProduct() async {
    setState(() => _isLoading = true);
    try {
      final isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        _showSnackBar('ストアに接続できません。時間をおいて再度お試しください。');
        return;
      }

      final response = await _inAppPurchase.queryProductDetails({
        IapConstants.premiumProductId,
      });
      if (response.error != null) {
        _showSnackBar('商品情報の取得に失敗しました。${response.error!.message}');
        return;
      }
      if (response.notFoundIDs.contains(IapConstants.premiumProductId) || response.productDetails.isEmpty) {
        _showSnackBar('買い切り版の商品情報が見つかりませんでした。');
        return;
      }
      if (!mounted) return;
      setState(() => _premiumProduct = response.productDetails.first);
    } catch (_) {
      _showSnackBar('商品情報の取得に失敗しました。時間をおいて再度お試しください。');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _purchasePremium() async {
    final product = _premiumProduct;
    if (product == null) {
      _showSnackBar('商品情報を取得中です。しばらくしてから再度お試しください。');
      await _loadPremiumProduct();
      return;
    }

    setState(() => _isPurchasePending = true);
    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      final started = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      if (!started) {
        _showSnackBar('購入処理を開始できませんでした。時間をおいて再度お試しください。');
        if (mounted) setState(() => _isPurchasePending = false);
      }
    } catch (_) {
      _showSnackBar('購入処理に失敗しました。時間をおいて再度お試しください。');
      if (mounted) setState(() => _isPurchasePending = false);
    }
  }

  Future<void> _restorePurchase() async {
    setState(() => _isPurchasePending = true);
    try {
      await _inAppPurchase.restorePurchases();
      _showSnackBar('購入の復元を確認しています。');
    } catch (_) {
      _showSnackBar('購入の復元に失敗しました。時間をおいて再度お試しください。');
    } finally {
      if (mounted) setState(() => _isPurchasePending = false);
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.productID != IapConstants.premiumProductId) continue;

      if (purchaseDetails.status == PurchaseStatus.pending) {
        if (mounted) setState(() => _isPurchasePending = true);
        continue;
      }

      if (purchaseDetails.status == PurchaseStatus.error) {
        _showSnackBar(purchaseDetails.error?.message ?? '購入処理中にエラーが発生しました。');
      } else if (purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored) {
        try {
          await ref.read(authControllerProvider).setPremium(true);
          _showSnackBar(
            purchaseDetails.status == PurchaseStatus.restored ? '購入を復元しました。' : '購入が完了しました。',
          );
        } catch (_) {
          _showSnackBar('購入情報の保存に失敗しました。時間をおいて再度お試しください。');
        }
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        _showSnackBar('購入がキャンセルされました。');
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
      if (mounted) setState(() => _isPurchasePending = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
