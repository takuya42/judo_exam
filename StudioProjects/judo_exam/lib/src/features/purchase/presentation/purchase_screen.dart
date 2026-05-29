import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/purchase_controller.dart';

class PurchaseScreen extends ConsumerWidget {
  const PurchaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnlocked = ref.watch(purchaseControllerProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('全問題解放')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.workspace_premium_outlined,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '全問題を買い切りで解放',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  const Text('無料で利用できるのは30問までです。31問目以降は全問題解放が必要です。'),
                  const SizedBox(height: 12),
                  const Text('productId: ${PurchaseController.productId}'),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: isUnlocked
                        ? null
                        : () async {
                            await ref
                                .read(purchaseControllerProvider.notifier)
                                .purchaseUnlockAllQuestions();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('ダミー購入が完了しました')),
                              );
                            }
                          },
                    icon: Icon(isUnlocked ? Icons.check_circle : Icons.shopping_cart),
                    label: Text(isUnlocked ? '購入済み' : '1,500円で全問題解放（ダミー）'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
