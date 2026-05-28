import 'package:flutter/material.dart';

class MockExamScreen extends StatelessWidget {
  const MockExamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('模擬試験')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('本番形式で実力チェック', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  const Text('出題範囲、制限時間、採点結果の詳細表示を今後実装します。'),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('準備中'),
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
