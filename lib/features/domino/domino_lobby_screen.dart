import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/game_ui.dart';

class DominoLobbyScreen extends StatefulWidget {
  const DominoLobbyScreen({super.key});

  @override
  State<DominoLobbyScreen> createState() => _DominoLobbyScreenState();
}

class _DominoLobbyScreenState extends State<DominoLobbyScreen> {
  int _players = 2;

  @override
  Widget build(BuildContext context) => GameScaffold(
        title: 'ردهة الدومينو',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GameLobbyHero(
              title: 'اضبط طاولة الدومينو',
              subtitle: 'حدد عدد المقاعد ثم ابدأ جولة على هذا الجهاز.',
              badge: _players == 2 ? 'مقعدان • محلي' : '$_players مقاعد • محلي',
              icon: Icons.extension_rounded,
              accent: aqua,
              backgroundAsset: 'assets/images/domino_lounge.webp',
            ),
            const SizedBox(height: 22),
            const Text('عدد اللاعبين', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 9,
              children: [2, 3, 4].map((count) => ChoiceChip(
                label: Text('$count لاعبين'),
                selected: _players == count,
                onSelected: (_) => setState(() => _players = count),
              )).toList(),
            ),
            const SizedBox(height: 18),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('طريقة اللعب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  _Rule(text: 'ابدأ بالقطعة الافتتاحية التي يحددها المحرك.'),
                  const _Rule(text: 'طابق أحد طرفي قطعتك مع طرف السلسلة المفتوح.'),
                  const _Rule(text: 'اسحب قطعة عندما لا تملك حركة قانونية.'),
                  const _Rule(text: 'عند نفاد السحب وانسداد اللعب، يحدد المحرك الفائز.'),
                  const SizedBox(height: 3),
                  Text('التوزيع: ${_players == 2 ? 7 : 5} قطع لكل لاعب.', style: const TextStyle(color: aqua, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GameActionButton(
              label: 'ابدأ مباراة محلية',
              icon: Icons.extension_rounded,
              onPressed: () => context.push('/domino?players=$_players'),
            ),
          ],
        ),
      );
}

class _Rule extends StatelessWidget {
  const _Rule({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [const Icon(Icons.circle, size: 6, color: aqua), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(color: mutedText)))],
        ),
      );
}
