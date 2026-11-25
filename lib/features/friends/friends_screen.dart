import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/game_ui.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) => GameScaffold(
        title: 'الأصدقاء',
        child: SurfaceCard(
          child: Column(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(color: aqua.withOpacity(0.12), borderRadius: BorderRadius.circular(22)),
                child: const Icon(Icons.group_add_rounded, color: aqua, size: 32),
              ),
              const SizedBox(height: 18),
              Text('مساحة الأصدقاء', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'هذه واجهة تأسيسية فقط. لا توجد دعوات أو لعب عبر الإنترنت مفعّلة حالياً.',
                style: TextStyle(color: mutedText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const ComingSoonLabel(label: 'الميزات الاجتماعية غير متاحة'),
              const SizedBox(height: 16),
              GameActionButton(
                label: 'العب محلياً الآن',
                icon: Icons.table_restaurant_rounded,
                onPressed: () => context.push('/rooms'),
              ),
            ],
          ),
        ),
      );
}
