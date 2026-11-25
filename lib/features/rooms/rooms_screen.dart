import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/game_ui.dart';

class RoomsScreen extends StatelessWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context) => GameScaffold(
        title: 'الغرف والطاولات',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('اختر طاولتك', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text(
              'هذه الطاولات محلية على جهازك؛ اختر لعبة لإعداد جولة جديدة.',
              style: TextStyle(color: mutedText),
            ),
            const SizedBox(height: 20),
            _LocalTableCard(
              title: 'طاولة لودو',
              subtitle: 'أربعة مقاعد • لعب محلي على جهاز واحد',
              icon: Icons.casino_rounded,
              accent: coral,
              onTap: () => context.push('/ludo-lobby'),
            ),
            const SizedBox(height: 12),
            _LocalTableCard(
              title: 'طاولة الدومينو',
              subtitle: 'من مقعدين إلى أربعة • إعداد محلي',
              icon: Icons.extension_rounded,
              accent: aqua,
              onTap: () => context.push('/domino-lobby'),
            ),
            const SizedBox(height: 18),
            const SurfaceCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: gold),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'الغرف العامة، رموز الدعوة والطاولات عبر الإنترنت غير مفعّلة. لم يُنشأ نظام لعب جماعي أو تُغيّر قاعدة البيانات.',
                      style: TextStyle(color: mutedText),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _LocalTableCard extends StatelessWidget {
  const _LocalTableCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: panel,
        borderRadius: BorderRadius.circular(23),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [accent.withOpacity(0.16), panel],
              ),
              border: Border.all(color: accent.withOpacity(0.22)),
              borderRadius: BorderRadius.circular(23),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.17),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: accent, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 5),
                      Text(subtitle, style: const TextStyle(color: mutedText, fontSize: 12)),
                      const SizedBox(height: 9),
                      Text('متاحة محلياً', style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_back_rounded, color: accent),
              ],
            ),
          ),
        ),
      );
}
