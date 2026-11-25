import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/local_game_journal.dart';
import '../../shared/widgets/game_ui.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) => GameScaffold(
        title: 'الملف الشخصي',
        child: Column(
          children: [
            const SurfaceCard(
              child: Column(
                children: [
                  CircleAvatar(radius: 38, backgroundColor: gold, child: Text('BK', style: TextStyle(color: ink, fontSize: 22, fontWeight: FontWeight.w900))),
                  SizedBox(height: 14),
                  Text('لاعب محلي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  SizedBox(height: 5),
                  Text('النتائج محفوظة على هذا الجهاز فقط', style: TextStyle(color: mutedText)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ValueListenableBuilder<int>(
              valueListenable: LocalGameJournal.revision,
              builder: (context, revision, _) => FutureBuilder<List<LocalMatchRecord>>(
                key: ValueKey(revision),
                future: LocalGameJournal.loadMatches(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return SurfaceCard(
                      child: snapshot.hasError
                          ? const Text('تعذر تحميل الإحصاءات المحلية.', style: TextStyle(color: mutedText))
                          : const Center(child: CircularProgressIndicator()),
                    );
                  }
                  final matches = snapshot.data!;
                  final ludoCount = matches.where((match) => match.game == 'ludo').length;
                  final dominoCount = matches.length - ludoCount;
                  return SurfaceCard(
                    child: Row(
                      children: [
                        Expanded(child: _Stat(label: 'مباريات مكتملة', value: '${matches.length}')),
                        Expanded(child: _Stat(label: 'لودو', value: '$ludoCount')),
                        Expanded(child: _Stat(label: 'دومينو', value: '$dominoCount')),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'لا نحتسب انتصارات لملف لاعب واحد لأن الجولات الحالية محلية ومتعددة المقاعد.',
              style: TextStyle(color: mutedText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => context.push('/history'),
              icon: const Icon(Icons.history_rounded),
              label: const Text('عرض سجل المباريات'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ],
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(children: [Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: aqua)), const SizedBox(height: 5), Text(label, style: const TextStyle(color: mutedText, fontSize: 12))]);
}
