import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/game_ui.dart';

class GameSelectionScreen extends StatelessWidget {
  const GameSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) => GameScaffold(
        title: 'الألعاب',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ماذا ستلعب اليوم؟', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('اختر لعبة محلية وابدأ جولة جديدة على نفس الجهاز.', style: TextStyle(color: mutedText)),
            const SizedBox(height: 24),
            _SelectionCard(
              icon: Icons.casino_rounded,
              title: 'لودو',
              subtitle: 'لعبة استراتيجية لأربعة لاعبين محلياً.',
              color: coral,
              onTap: () => context.push('/ludo-lobby'),
            ),
            const SizedBox(height: 14),
            _SelectionCard(
              icon: Icons.extension_rounded,
              title: 'الدومينو',
              subtitle: 'من لاعبين إلى أربعة، بقواعد المحرك الحالي.',
              color: aqua,
              onTap: () => context.push('/domino-lobby'),
            ),
          ],
        ),
      );
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 18),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 7),
            Text(subtitle, style: const TextStyle(color: mutedText)),
            const SizedBox(height: 18),
            GameActionButton(label: 'اختيار اللعبة', icon: Icons.arrow_back_rounded, onPressed: onTap),
          ],
        ),
      );
}
