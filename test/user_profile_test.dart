import 'package:flutter_test/flutter_test.dart';
import 'package:judo_exam/src/features/auth/application/auth_providers.dart';

void main() {
  group('UserProfile.fromJson', () {
    test('maps a boolean true isPremium value', () {
      final profile = UserProfile.fromJson({
        'uid': 'premium-user',
        'isPremium': true,
      });

      expect(profile.uid, 'premium-user');
      expect(profile.isPremium, isTrue);
    });

    test('maps false, missing, and non-boolean values as free', () {
      expect(
        UserProfile.fromJson({'isPremium': false}).isPremium,
        isFalse,
      );
      expect(UserProfile.fromJson(const {}).isPremium, isFalse);
      expect(
        UserProfile.fromJson({'isPremium': 'true'}).isPremium,
        isFalse,
      );
    });

    test('uses the Firestore document id when uid is absent', () {
      final profile = UserProfile.fromJson(
        {'isPremium': true},
        documentId: 'current-auth-uid',
      );

      expect(profile.uid, 'current-auth-uid');
    });
  });
}
