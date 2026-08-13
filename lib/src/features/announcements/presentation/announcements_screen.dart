import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/announcement_providers.dart';
import '../domain/announcement.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcements = ref.watch(announcementsProvider);
    final readIds = ref.watch(announcementReadControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('お知らせ'), actions: [
        IconButton(tooltip: '再読み込み', onPressed: () => ref.invalidate(announcementsProvider), icon: const Icon(Icons.refresh_rounded)),
      ]),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(announcementsProvider.future);
        },
        child: announcements.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const _MessageList(icon: Icons.cloud_off_outlined, message: 'お知らせを取得できませんでした\n下に引いて再読み込みしてください'),
          data: (items) => items.isEmpty
              ? const _MessageList(icon: Icons.notifications_none_rounded, message: '現在、お知らせはありません')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _AnnouncementCard(announcement: item, isUnread: !readIds.contains(item.id), onTap: () {
                      ref.read(announcementReadControllerProvider.notifier).markAsRead(item.id);
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AnnouncementDetailScreen(announcement: item)));
                    });
                  },
                ),
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement, required this.isUnread, required this.onTap});
  final Announcement announcement;
  final bool isUnread;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(margin: EdgeInsets.zero, clipBehavior: Clip.antiAlias, child: InkWell(onTap: onTap, child: Padding(
      padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (isUnread) Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3), decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(20)), child: Text('NEW', style: TextStyle(color: colors.onPrimaryContainer, fontSize: 11, fontWeight: FontWeight.w800))),
          if (isUnread) const SizedBox(width: 8),
          Icon(_typeIcon(announcement.type), size: 18, color: colors.primary), const Spacer(),
          Text(_formatDate(announcement.publishedAt), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
        ]),
        const SizedBox(height: 12),
        Text(announcement.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(announcement.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.onSurfaceVariant, height: 1.5)),
      ]),
    )));
  }
}

class AnnouncementDetailScreen extends StatelessWidget {
  const AnnouncementDetailScreen({required this.announcement, super.key});
  final Announcement announcement;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(appBar: AppBar(title: const Text('お知らせ詳細')), body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(announcement.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Row(children: [Icon(Icons.calendar_today_outlined, size: 16, color: colors.primary), const SizedBox(width: 6), Text(_formatDate(announcement.publishedAt), style: TextStyle(color: colors.onSurfaceVariant))]),
        const SizedBox(height: 20), Divider(color: colors.outlineVariant), const SizedBox(height: 20),
        SelectableText(announcement.body, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.8)),
      ]),
    ));
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.icon, required this.message});
  final IconData icon;
  final String message;
  @override
  Widget build(BuildContext context) => ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
    const SizedBox(height: 160), Icon(icon, size: 52, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 16), Text(message, textAlign: TextAlign.center),
  ]);
}

String _formatDate(DateTime date) => '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
IconData _typeIcon(AnnouncementType type) => switch (type) {
  AnnouncementType.update => Icons.auto_awesome_rounded,
  AnnouncementType.maintenance => Icons.build_outlined,
  AnnouncementType.important => Icons.priority_high_rounded,
  AnnouncementType.info => Icons.info_outline_rounded,
};
