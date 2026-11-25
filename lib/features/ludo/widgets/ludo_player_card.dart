import 'package:flutter/material.dart';

import '../engine/ludo_engine.dart';
import 'ludo_style.dart';

class LudoPlayerCard extends StatelessWidget {
  const LudoPlayerCard({
    super.key,
    required this.color,
    required this.active,
    required this.finishedPieces,
    required this.points,
    required this.onTap,
    this.isAi = false,
    this.compact = false,
  });

  final LudoColor color;
  final bool active;
  final int finishedPieces;
  final int points;
  final VoidCallback onTap;
  final bool isAi;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = ludoPlayerColors[color]!;
    final name = ludoPlayerNames[color]!;
    final scale = compact ? 0.9 : 1.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      constraints: BoxConstraints(minHeight: compact ? 64 : 84),
      padding: EdgeInsets.all(compact ? 9 : 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: active
              ? [Color.lerp(accent, Colors.white, 0.08)!, ludoPanel, const Color(0xFF151116)]
              : [const Color(0xFF2C2329), ludoPanel],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: active ? ludoGold : Colors.white.withOpacity(0.09), width: active ? 1.7 : 1),
        boxShadow: [
          BoxShadow(color: active ? accent.withOpacity(0.23) : Colors.black.withOpacity(0.2), blurRadius: active ? 20 : 10, offset: const Offset(0, 5)),
          if (active) BoxShadow(color: ludoGold.withOpacity(0.11), blurRadius: 2, spreadRadius: 1),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              width: compact ? 40 : 46,
              height: compact ? 40 : 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color.lerp(accent, Colors.white, 0.42)!, accent, Color.lerp(accent, Colors.black, 0.35)!]),
                border: Border.all(color: ludoGold.withOpacity(active ? 0.9 : 0.38), width: active ? 1.6 : 1),
                boxShadow: [BoxShadow(color: accent.withOpacity(0.35), blurRadius: 11)],
              ),
              child: ClipOval(
                child: Image.asset(
                  ludoPlayerAvatars[color]!,
                  fit: BoxFit.cover,
                  semanticLabel: 'صورة $name',
                  errorBuilder: (_, __, ___) => Center(child: Text(name.substring(0, 1), style: TextStyle(color: Colors.white, fontSize: compact ? 17 : 19, fontWeight: FontWeight.w900))),
                ),
              ),
            ),
            SizedBox(width: compact ? 8 : 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: ludoCream, fontSize: 13 * scale, fontWeight: FontWeight.w900))),
                      if (isAi) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.smart_toy_rounded, color: accent, size: 13),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Semantics(
                    label: 'النقاط $points، وصلت $finishedPieces من 4 قطع',
                    child: Row(
                      children: [
                        Icon(finishedPieces == 4 ? Icons.emoji_events_rounded : Icons.stars_rounded, size: 13, color: ludoGold),
                        const SizedBox(width: 4),
                        Flexible(child: Text('$points نقطة', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ludoCream, fontSize: 10, fontWeight: FontWeight.w800))),
                        const SizedBox(width: 4),
                        Text('$finishedPieces/4', style: TextStyle(color: Colors.white.withOpacity(0.64), fontSize: 9, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (active) ...[
              SizedBox(width: compact ? 4 : 7),
              Container(width: 7, height: 7, decoration: BoxDecoration(color: const Color(0xFF5AF39A), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF5AF39A).withOpacity(0.7), blurRadius: 7)])),
            ],
          ],
        ),
      ),
    );
  }
}
