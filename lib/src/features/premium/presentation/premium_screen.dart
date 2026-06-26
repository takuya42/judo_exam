import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:judo_exam/core/constants/iap_constants.dart';

import '../../auth/application/auth_providers.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

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
                  Text('1,500円（税込）', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: const Color(0xFF006C52))),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => _purchasePremium(
                      ref,
                      productId: IapConstants.premiumProductId,
                    ),
                    icon: const Icon(Icons.lock_open_rounded),
                    label: const Text('買い切り版を購入'),
                  ),
                  TextButton(onPressed: () => ref.read(authControllerProvider).restorePurchase(), child: const Text('購入を復元')),
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

  void _purchasePremium(WidgetRef ref, {required String productId}) {
    assert(productId == IapConstants.premiumProductId);
    ref.read(authControllerProvider).setPremium(true);
  }
}
