import 'package:flutter_test/flutter_test.dart';
import 'package:judo_exam/src/features/announcements/application/announcement_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('既読IDはUID別のキーに保存される', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final userA = AnnouncementReadController(
      preferences,
      storageKey: 'read_announcements_user-a',
    );
    final userB = AnnouncementReadController(
      preferences,
      storageKey: 'read_announcements_user-b',
    );

    await userA.markAsRead('notice-1');

    expect(userA.state, contains('notice-1'));
    expect(userB.state, isNot(contains('notice-1')));
    expect(
      preferences.getStringList('read_announcements_user-a'),
      contains('notice-1'),
    );
  });
}
