import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/game_ui.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => GameScaffold(
        title: 'الإعدادات',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('اللغة', style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(height: 7),
                  Text('العربية  •  اتجاه من اليمين إلى اليسار', style: TextStyle(color: mutedText)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const SurfaceCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.volume_off_rounded, color: mutedText),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الصوت والاهتزاز', style: TextStyle(fontWeight: FontWeight.w800)),
                        SizedBox(height: 6),
                        Text('لا توجد مؤثرات صوتية أو اهتزازات مدمجة حالياً؛ لذلك لا تظهر مفاتيح تبديل غير مؤثرة.', style: TextStyle(color: mutedText)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.person_outline_rounded, color: aqua),
                title: const Text('حساب BOARD KINGS'),
                subtitle: const Text('سجّل الدخول لمزامنة المظاهر ورصيد العملات.', style: TextStyle(color: mutedText, fontSize: 12)),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => context.push('/account'),
              ),
            ),
          ],
        ),
      );
}
