import 'package:flutter/material.dart';

import '../../core/local_game_journal.dart';
import '../../shared/widgets/game_ui.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<LocalMatchRecord>> _activity;

  @override
  void initState() {
    super.initState();
    _activity = LocalGameJournal.loadMatches();
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
        title: 'الإشعارات',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('نشاطك الأخير', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('إشعارات محلية عن المباريات المكتملة؛ لا توجد إشعارات دفع أو نشاط شبكي.', style: TextStyle(color: mutedText)),
            const SizedBox(height: 18),
            FutureBuilder<List<LocalMatchRecord>>(
              future: _activity,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _ActivityEmpty(
                    icon: Icons.error_outline_rounded,
                    title: 'تعذر تحميل النشاط',
                    detail: 'حاول فتح الإشعارات مجدداً.',
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final records = snapshot.data!;
                if (records.isEmpty) {
                  return const _ActivityEmpty(
                    icon: Icons.notifications_none_rounded,
                    title: 'لا توجد إشعارات بعد',
                    detail: 'سيظهر ملخص هنا عند اكتمال مباراة محلية.',
                  );
                }
                return Column(
                  children: [
                    for (final record in records) ...[
                      _ActivityCard(record: record),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.record});
  final LocalMatchRecord record;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.emoji_events_rounded, color: gold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('اكتملت مباراة ${record.gameLabel}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text('الفائز: ${record.winner} • ${_playersLabel(record.playerCount)}', style: const TextStyle(color: mutedText, fontSize: 12)),
                  const SizedBox(height: 5),
                  Text(_formatDate(record.completedAt), style: const TextStyle(color: aqua, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ActivityEmpty extends StatelessWidget {
  const _ActivityEmpty({required this.icon, required this.title, required this.detail});
  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        child: Column(
          children: [
            Icon(icon, color: aqua, size: 34),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(detail, textAlign: TextAlign.center, style: const TextStyle(color: mutedText)),
          ],
        ),
      );
}

String _playersLabel(int count) => count == 2 ? 'لاعبان' : '$count لاعبين';

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} • $hour:$minute';
}
