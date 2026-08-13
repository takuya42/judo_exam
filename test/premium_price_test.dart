import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:judo_exam/core/constants/iap_constants.dart';
import 'package:judo_exam/src/features/premium/application/premium_providers.dart';

void main() {
  group('Premium price', () {
    test('always provides the Japanese yen display price', () {
      expect(IapConstants.premiumDisplayPrice, '¥1,500');
    });

    test(
      'keeps ProductDetails available for purchasing without displaying '
      'its price',
      () {
        final product = ProductDetails(
          id: 'premium',
          title: 'プレミアムプラン',
          description: '買い切り版',
          price: r'USD 12.34',
          rawPrice: 12.34,
          currencyCode: 'USD',
        );

        final state = PremiumState(product: product);

        expect(state.product, same(product));
        expect(state.product!.price, r'USD 12.34');
        expect(IapConstants.premiumDisplayPrice, '¥1,500');
      },
    );
  });
}
