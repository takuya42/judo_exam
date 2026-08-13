import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/application/auth_providers.dart';
import '../../settings/application/settings_providers.dart';
import '../domain/announcement.dart';

final announcementsProvider = StreamProvider<List<Announcement>>((ref) {
  return ref.watch(firestoreProvider).collection('announcements')
      .where('isPublished', isEqualTo: true).orderBy('publishedAt', descending: true).snapshots()
      .map((snapshot) => snapshot.docs.map(Announcement.fromFirestore).toList(growable: false));
});

final announcementReadControllerProvider = StateNotifierProvider<AnnouncementReadController, Set<String>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid ?? 'guest';
  return AnnouncementReadController(ref.watch(sharedPreferencesProvider), storageKey: 'read_announcements_$uid');
});

final hasUnreadAnnouncementsProvider = Provider<bool>((ref) {
  final readIds = ref.watch(announcementReadControllerProvider);
  return ref.watch(announcementsProvider).valueOrNull?.any((item) => !readIds.contains(item.id)) ?? false;
});

class AnnouncementReadController extends StateNotifier<Set<String>> {
  AnnouncementReadController(this._preferences, {required this.storageKey})
      : super(Set.unmodifiable(_preferences.getStringList(storageKey) ?? const []));
  final SharedPreferences _preferences;
  final String storageKey;

  Future<void> markAsRead(String announcementId) async {
    if (state.contains(announcementId)) return;
    state = Set.unmodifiable({...state, announcementId});
    await _preferences.setStringList(storageKey, state.toList(growable: false));
  }
}
