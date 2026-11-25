import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/local_game_journal.dart';
import '../../shared/widgets/game_ui.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('BOARD KINGS', style: Theme.of(context).textTheme.titleLarge?.copyWith(letterSpacing: 1.3)),
                              const SizedBox(height: 4),
                              const Text('مساحتك للعب والتحدي', style: TextStyle(color: mutedText, fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'الإعدادات',
                          onPressed: () => context.push('/settings'),
                          icon: const Icon(Icons.tune_rounded),
                        ),
                        const SizedBox(width: 8),
                        const SizedBox(width: 4),
                        IconButton.filledTonal(
                          tooltip: 'المتجر',
                          onPressed: () => context.push('/store'),
                          icon: const Icon(Icons.storefront_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _PlayerSummary(onTap: () => context.push('/profile')),
                    const SizedBox(height: 28),
                    SectionTitle('اختر لعبتك', action: 'كل الألعاب', onAction: () => context.push('/games')),
                    const SizedBox(height: 12),
                    _GameCard(
                      title: 'لودو',
                      subtitle: 'خطط لحركتك، واحمِ قطعك حتى خط النهاية.',
                      icon: Icons.casino_rounded,
                      accent: coral,
                      badge: '٤ لاعبين محلياً',
                      onTap: () => context.push('/ludo-lobby'),
                    ),
                    const SizedBox(height: 12),
                    _GameCard(
                      title: 'الدومينو',
                      subtitle: 'طابق الأطراف وتخلّص من قطعك قبل الجميع.',
                      icon: Icons.extension_rounded,
                      accent: aqua,
                      badge: '٢–٤ لاعبين محلياً',
                      onTap: () => context.push('/domino-lobby'),
                    ),
                    const SizedBox(height: 28),
                    SectionTitle('آخر المباريات', action: 'عرض السجل', onAction: () => context.push('/history')),
                    const SizedBox(height: 12),
                    const _RecentGamesPreview(),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _ShortcutCard(
                            icon: Icons.group_outlined,
                            label: 'الأصدقاء',
                            onTap: () => context.push('/friends'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ShortcutCard(
                            icon: Icons.groups_2_outlined,
                            label: 'الفرق',
                            onTap: () => context.push('/teams'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ShortcutCard(
                            icon: Icons.table_restaurant_rounded,
                            label: 'الغرف والطاولات',
                            onTap: () => context.push('/rooms'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ShortcutCard(
                            icon: Icons.notifications_none_rounded,
                            label: 'الإشعارات',
                            onTap: () => context.push('/notifications'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _PlayerSummary extends StatelessWidget {
  const _PlayerSummary({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF263750), panel]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(20)),
                child: const Center(child: Text('BK', style: TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w900))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('لاعب محلي', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    const Text('ملف محلي على هذا الجهاز', style: TextStyle(color: mutedText, fontSize: 12)),
                    const SizedBox(height: 11),
                    const Text('النتائج والإحصاءات من مبارياتك المكتملة', style: TextStyle(color: mutedText, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_left_rounded, color: mutedText),
            ],
          ),
        ),
      );
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.title, required this.subtitle, required this.icon, required this.accent, required this.badge, required this.onTap});

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: accent.withOpacity(0.15), borderRadius: BorderRadius.circular(17)),
                  child: Icon(icon, color: accent, size: 27),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(badge, style: const TextStyle(color: mutedText, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_outward_rounded, color: accent, size: 20),
              ],
            ),
            const SizedBox(height: 14),
            Text(subtitle, style: const TextStyle(color: mutedText)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('العب الآن'),
                style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: ink),
              ),
            ),
          ],
        ),
      );
}

class _RecentGamesPreview extends StatelessWidget {
  const _RecentGamesPreview();

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: LocalGameJournal.revision,
        builder: (context, revision, _) => FutureBuilder<List<LocalMatchRecord>>(
          key: ValueKey(revision),
          future: LocalGameJournal.loadMatches(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const SurfaceCard(
                child: Text('تعذر تحميل سجل المباريات من هذا الجهاز.', style: TextStyle(color: mutedText)),
              );
            }
            if (!snapshot.hasData) {
              return const SurfaceCard(
                child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
              );
            }
            final matches = snapshot.data!;
            if (matches.isEmpty) {
              return const SurfaceCard(
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, color: mutedText, size: 25),
                    SizedBox(width: 12),
                    Expanded(child: Text('لا توجد مباريات مكتملة مسجلة بعد.', style: TextStyle(color: mutedText))),
                  ],
                ),
              );
            }
            return SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: matches.take(2).map((match) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(match.game == 'ludo' ? Icons.casino_rounded : Icons.extension_rounded, color: match.game == 'ludo' ? coral : aqua),
                      const SizedBox(width: 10),
                      Expanded(child: Text('${match.gameLabel} • الفائز: ${match.winner}', style: const TextStyle(fontWeight: FontWeight.w700))),
                      const Icon(Icons.emoji_events_rounded, color: gold, size: 18),
                    ],
                  ),
                )).toList(),
              ),
            );
          },
        ),
      );
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: panel,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 17),
            child: Row(
              children: [
                Icon(icon, color: aqua),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
