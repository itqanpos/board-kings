import 'package:flutter/material.dart';

import '../../core/local_game_journal.dart';
import '../../shared/widgets/game_ui.dart';

class MatchHistoryScreen extends StatefulWidget {
  const MatchHistoryScreen({super.key});

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> {
  late Future<List<LocalMatchRecord>> _matches;

  @override
  void initState() {
    super.initState();
    _matches = LocalGameJournal.loadMatches();
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
        title: 'سجل المباريات',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('مبارياتك المكتملة', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('النتائج المحفوظة على هذا الجهاز فقط.', style: TextStyle(color: mutedText)),
            const SizedBox(height: 18),
            FutureBuilder<List<LocalMatchRecord>>(
              future: _matches,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _HistoryState(
                    icon: Icons.error_outline_rounded,
                    title: 'تعذر تحميل السجل',
                    detail: 'حاول العودة إلى الشاشة مرة أخرى.',
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final matches = snapshot.data!;
                if (matches.isEmpty) {
                  return const _HistoryState(
                    icon: Icons.history_rounded,
                    title: 'لا توجد مباريات مسجلة بعد',
                    detail: 'ستظهر النتائج هنا بعد إكمال مباراة محلية.',
                  );
                }
                return Column(
                  children: [
                    for (final match in matches) ...[
                      _MatchCard(match: match),
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

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});
  final LocalMatchRecord match;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: (match.game == 'ludo' ? coral : aqua).withOpacity(0.14),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                match.game == 'ludo' ? Icons.casino_rounded : Icons.extension_rounded,
                color: match.game == 'ludo' ? coral : aqua,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(match.gameLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('الفائز: ${match.winner}', style: const TextStyle(color: aqua, fontSize: 12)),
                  const SizedBox(height: 3),
                  Text(
                    '${_playersLabel(match.playerCount)} • ${_formatDate(match.completedAt)}',
                    style: const TextStyle(color: mutedText, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.emoji_events_rounded, color: gold),
          ],
        ),
      );
}

class _HistoryState extends StatelessWidget {
  const _HistoryState({required this.icon, required this.title, required this.detail});
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
