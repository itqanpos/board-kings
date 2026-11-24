import 'package:flutter/material.dart';

import '../../shared/widgets/game_ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;

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
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    value: _soundEnabled,
                    onChanged: (value) => setState(() => _soundEnabled = value),
                    title: const Text('المؤثرات الصوتية'),
                    subtitle: const Text('تفضيل مؤقت لهذه الجلسة', style: TextStyle(color: mutedText, fontSize: 12)),
                    activeColor: aqua,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SwitchListTile(
                    value: _hapticsEnabled,
                    onChanged: (value) => setState(() => _hapticsEnabled = value),
                    title: const Text('الاهتزاز'),
                    subtitle: const Text('تفضيل مؤقت لهذه الجلسة', style: TextStyle(color: mutedText, fontSize: 12)),
                    activeColor: aqua,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text('لا توجد حسابات أو إعدادات مزامنة في هذا الإصدار المحلي.', style: TextStyle(color: mutedText)),
          ],
        ),
      );
}
