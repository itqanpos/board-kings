import 'package:flutter/material.dart';

import '../../shared/widgets/game_ui.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                  Text('ملف على هذا الجهاز', style: TextStyle(color: mutedText)),
                  SizedBox(height: 18),
                  LinearProgressIndicator(value: 0.35, color: aqua, backgroundColor: Color(0xFF34435A)),
                  SizedBox(height: 9),
                  Text('المستوى ١  •  التقدم ٣٥٪', style: TextStyle(color: mutedText, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const SurfaceCard(
              child: Row(
                children: [
                  Expanded(child: _Stat(label: 'مباريات', value: '—')),
                  Expanded(child: _Stat(label: 'انتصارات', value: '—')),
                  Expanded(child: _Stat(label: 'نقاط', value: '—')),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text('إحصاءات اللعب غير متاحة حتى تُضاف آلية محلية لحفظ النتائج.', style: TextStyle(color: mutedText), textAlign: TextAlign.center),
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
