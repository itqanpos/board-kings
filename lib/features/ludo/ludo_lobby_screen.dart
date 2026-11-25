import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/game_ui.dart';

class LudoLobbyScreen extends StatelessWidget {
  const LudoLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => GameScaffold(
        title: 'ردهة لودو',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GameLobbyHero(
              title: 'جهّز طاولة لودو',
              subtitle: 'ابدأ جولة كاملة على جهاز واحد، دون اتصال أو حساب.',
              badge: '٤ مقاعد محلية',
              icon: Icons.casino_rounded,
              accent: coral,
            ),
            const SizedBox(height: 22),
            const SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ModeRow(icon: Icons.people_alt_rounded, title: 'لعب محلي', detail: 'أربعة ألوان على جهاز واحد', active: true),
                  Divider(height: 28),
                  _ModeRow(icon: Icons.person_outline_rounded, title: 'لاعبان', detail: 'غير مدعوم في المحرك الحالي', active: false),
                  Divider(height: 28),
                  _ModeRow(icon: Icons.groups_2_outlined, title: 'فريقان ٢ ضد ٢', detail: 'غير مدعوم في المحرك الحالي', active: false),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('قواعد الجولة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  SizedBox(height: 12),
                  _RuleLine(text: 'تحتاج إلى ٦ لإخراج قطعة من القاعدة.'),
                  _RuleLine(text: 'تحتاج القطعة إلى رقم دقيق للوصول إلى النهاية.'),
                  _RuleLine(text: 'الخانات الآمنة تحمي القطع من الالتقاط.'),
                  _RuleLine(text: 'الستة أو الالتقاط يمنحان دوراً إضافياً حسب المحرك.'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GameActionButton(label: 'اللعب السريع المحلي', icon: Icons.bolt_rounded, onPressed: () => context.push('/ludo')),
            const SizedBox(height: 9),
            OutlinedButton.icon(
              onPressed: () => context.push('/ludo'),
              icon: const Icon(Icons.people_alt_rounded),
              label: const Text('العب محلياً'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ],
        ),
      );
}

class _ModeRow extends StatelessWidget {
  const _ModeRow({required this.icon, required this.title, required this.detail, required this.active});
  final IconData icon;
  final String title;
  final String detail;
  final bool active;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: active ? aqua : mutedText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(detail, style: const TextStyle(color: mutedText, fontSize: 12))],
            ),
          ),
          if (active) const Icon(Icons.check_circle_rounded, color: aqua, size: 20) else const ComingSoonLabel(label: 'غير متاح'),
        ],
      );
}

class _RuleLine extends StatelessWidget {
  const _RuleLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [const Icon(Icons.circle, size: 6, color: coral), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(color: mutedText)))],
        ),
      );
}
