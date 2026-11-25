import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/game_ui.dart';

class TeamsScreen extends StatelessWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context) => GameScaffold(
        title: 'الفرق',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('العبوا كفريق', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('إدارة الفرق تحتاج إلى دعوات ومزامنة بين اللاعبين.', style: TextStyle(color: mutedText)),
            const SizedBox(height: 20),
            const SurfaceCard(
              child: Column(
                children: [
                  Icon(Icons.groups_2_rounded, color: aqua, size: 36),
                  SizedBox(height: 14),
                  Text('الفرق عبر الإنترنت غير مفعّلة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  SizedBox(height: 8),
                  Text(
                    'لا توجد فرق أو أعضاء محفوظون حاليًا. لم أضف بيانات تجريبية أو دعوات شكلية، ولم أبدأ اللعب الجماعي أو أغيّر قاعدة بيانات Supabase.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: mutedText, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GameActionButton(
              label: 'استكشف الطاولات المحلية',
              icon: Icons.table_restaurant_rounded,
              onPressed: () => context.push('/rooms'),
            ),
          ],
        ),
      );
}
