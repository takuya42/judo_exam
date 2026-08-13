import 'package:cloud_firestore/cloud_firestore.dart';

enum AnnouncementType { update, maintenance, important, info }

class Announcement {
  const Announcement({required this.id, required this.title, required this.body, required this.publishedAt, required this.type});
  final String id;
  final String title;
  final String body;
  final DateTime publishedAt;
  final AnnouncementType type;

  factory Announcement.fromFirestore(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    if (data == null) throw StateError('Announcement ${document.id} has no data');
    final publishedAt = data['publishedAt'];
    if (publishedAt is! Timestamp) throw FormatException('publishedAt must be a Timestamp: ${document.id}');
    return Announcement(
      id: document.id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      publishedAt: publishedAt.toDate(),
      type: AnnouncementType.values.firstWhere((type) => type.name == data['type'], orElse: () => AnnouncementType.info),
    );
  }
}
