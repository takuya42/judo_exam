import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:judo_exam/src/features/premium/application/premium_providers.dart';

void main() {
  group('PremiumState localized price', () {
    test('does not provide a fallback before product details are loaded', () {
      const state = PremiumState();

      expect(state.localizedPrice, isNull);
    });

    test('uses the store-localized ProductDetails.price unchanged', () {
      final product = ProductDetails(
        id: 'premium',
        title: 'プレミアムプラン',
        description: '買い切り版',
        price: '¥980',
        rawPrice: 980,
        currencyCode: 'JPY',
      );

      final state = PremiumState(product: product);

      expect(state.localizedPrice, '¥980');
    });
  });
}
