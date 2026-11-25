import 'package:flutter/material.dart';

import '../../../shared/widgets/game_ui.dart';
import '../models/cosmetic_item.dart';

class CosmeticArtwork extends StatelessWidget {
  const CosmeticArtwork({super.key, required this.item, this.height = 128, this.iconSize = 46});

  final CosmeticItem item;
  final double height;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final palette = _palette(item.previewStyle);
    final icon = switch (item.category) {
      'dice' => Icons.casino_rounded,
      'pieces' => Icons.circle_rounded,
      'tiles' => Icons.extension_rounded,
      _ => Icons.grid_view_rounded,
    };

    return ExcludeSemantics(
      child: Container(
        height: height,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: palette,
          ),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: -25,
              left: -18,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            if (item.category == 'table')
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(19),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Center(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [coral, aqua, gold, const Color(0xFF789BFF)].map((color) => Container(
                          width: 19,
                          height: 19,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.92),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 9)],
                          ),
                        )).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            if (item.category != 'table')
              Icon(icon, color: Colors.white.withOpacity(0.22), size: iconSize + 42),
            Icon(icon, color: Colors.white, size: iconSize, shadows: const [Shadow(color: Colors.black38, blurRadius: 12)]),
            Positioned(
              bottom: 10,
              right: 11,
              child: Text(
                item.gameScope == 'ludo' ? 'LUDO' : 'DOMINO',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 9,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _palette(String style) => switch (style) {
        'oak' => const [Color(0xFF96704C), Color(0xFF4B332C)],
        'regal' || 'crown' || 'gold' => const [Color(0xFFB98B37), Color(0xFF3D2B21)],
        'neon' => const [Color(0xFF1A5464), Color(0xFF242146)],
        'galaxy' => const [Color(0xFF59478E), Color(0xFF171D3A)],
        'forest' => const [Color(0xFF4B7C5B), Color(0xFF1B3B3A)],
        'flame' => const [Color(0xFFCB6844), Color(0xFF452334)],
        'crystal' => const [Color(0xFF70B9C7), Color(0xFF354675)],
        'marble' || 'obsidian' => const [Color(0xFF556274), Color(0xFF171D28)],
        'desert' || 'ivory' => const [Color(0xFFD0AD78), Color(0xFF70523A)],
        'winter' => const [Color(0xFF80BDCE), Color(0xFF354F7B)],
        _ => const [Color(0xFF536D87), Color(0xFF263750)],
      };
}
