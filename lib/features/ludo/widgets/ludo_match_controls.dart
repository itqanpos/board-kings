import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../engine/ludo_engine.dart';
import 'ludo_style.dart';

class LudoTopBar extends StatelessWidget {
  const LudoTopBar({super.key, required this.currentTurn, required this.timer, required this.soundEnabled, required this.onPause, required this.onToggleSound, required this.onChat, required this.onSettings});

  final LudoColor currentTurn;
  final String timer;
  final bool soundEnabled;
  final VoidCallback onPause;
  final VoidCallback onToggleSound;
  final VoidCallback onChat;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 450;
          final toolSize = compact ? 34.0 : 40.0;
          final gap = compact ? 3.0 : 5.0;
          final accent = ludoPlayerColors[currentTurn]!;
          return Container(
            height: 58,
            padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 11),
            decoration: BoxDecoration(
              color: const Color(0xD9161116),
              border: Border(bottom: BorderSide(color: ludoGold.withOpacity(0.3))),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 13, offset: Offset(0, 5))],
            ),
            child: Row(
              children: [
                _ToolButton(icon: Icons.pause_rounded, label: 'إيقاف مؤقت', onPressed: onPause, size: toolSize),
                SizedBox(width: gap),
                _ToolButton(icon: soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded, label: soundEnabled ? 'كتم الصوت' : 'تشغيل الصوت', onPressed: onToggleSound, size: toolSize),
                SizedBox(width: compact ? 5 : 9),
                Expanded(
                  child: Container(
                    height: 42,
                    padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1A2E52), Color(0xFF10192D)]),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: ludoGold.withOpacity(0.84), width: 1.2),
                      boxShadow: [BoxShadow(color: accent.withOpacity(0.15), blurRadius: 12)],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.workspace_premium_rounded, color: ludoGold, size: compact ? 15 : 19),
                        SizedBox(width: compact ? 4 : 7),
                        Flexible(child: Text('دور اللاعب: ${ludoPlayerNames[currentTurn]}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: ludoCream, fontSize: compact ? 11 : 13, fontWeight: FontWeight.w900))),
                        if (!compact) ...[const SizedBox(width: 7), Icon(Icons.casino_rounded, color: accent, size: 19)],
                      ],
                    ),
                  ),
                ),
                SizedBox(width: compact ? 4 : 9),
                Container(
                  height: 38,
                  padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 9),
                  decoration: BoxDecoration(color: const Color(0xFF111625), borderRadius: BorderRadius.circular(21), border: Border.all(color: ludoGold.withOpacity(0.62))),
                  child: Row(children: [if (!compact) const Icon(Icons.hourglass_bottom_rounded, color: ludoGold, size: 16), if (!compact) const SizedBox(width: 4), Text(timer, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, fontFeatures: [FontFeature.tabularFigures()]))]),
                ),
                SizedBox(width: gap),
                _ToolButton(icon: Icons.chat_bubble_rounded, label: 'الدردشة السريعة', onPressed: onChat, size: toolSize),
                SizedBox(width: gap),
                _ToolButton(icon: Icons.settings_rounded, label: 'الإعدادات', onPressed: onSettings, size: toolSize),
              ],
            ),
          );
        },
      );
}

class LudoRollButton extends StatelessWidget {
  const LudoRollButton({super.key, required this.value, required this.enabled, required this.onPressed, required this.skin});

  final int? value;
  final bool enabled;
  final VoidCallback onPressed;
  final String skin;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: enabled ? const [Color(0xFF4DF36B), Color(0xFF08A73F), Color(0xFF04742D)] : const [Color(0xFF63745F), Color(0xFF344936)]),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: ludoGold, width: 2),
          boxShadow: [BoxShadow(color: const Color(0xFF17DB4D).withOpacity(enabled ? 0.26 : 0.08), blurRadius: 18, offset: const Offset(0, 5)), const BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 5))],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(26),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedRotation(
                    turns: value == null ? 0 : value! / 6,
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutBack,
                    child: _DiceIcon(value: value, skin: skin),
                  ),
                  const SizedBox(width: 10),
                  Text(value == null ? 'ارمِ النرد' : 'النتيجة $value', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17, shadows: [Shadow(color: Colors.black45, blurRadius: 5, offset: Offset(0, 1))])),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiceIcon extends StatelessWidget {
  const _DiceIcon({required this.value, required this.skin});
  final int? value;
  final String skin;

  static const Map<int, Set<int>> _pips = {1: {4}, 2: {0, 8}, 3: {0, 4, 8}, 4: {0, 2, 6, 8}, 5: {0, 2, 4, 6, 8}, 6: {0, 2, 3, 5, 6, 8}};

  @override
  Widget build(BuildContext context) {
    final style = skin.replaceFirst('ludo_dice_', '');
    final face = switch (style) {
      'gold' || 'crown' => const Color(0xFFF4C66A),
      'crystal' => const Color(0xFFB8EAEB),
      'flame' => const Color(0xFFFFE1C8),
      'neon' => const Color(0xFF153D4D),
      _ => const Color(0xFFFFF8EB),
    };
    final pip = style == 'neon' ? Colors.white : const Color(0xFF251D1B);
    return Container(
      width: 34,
      height: 34,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color.lerp(face, Colors.white, 0.18)!, face, Color.lerp(face, Colors.black, 0.12)!]), borderRadius: BorderRadius.circular(9), border: Border.all(color: ludoGold, width: 1.4), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 5, offset: Offset(0, 2))]),
      child: value == null
          ? Icon(Icons.casino_rounded, size: 23, color: pip)
          : Column(
              children: List.generate(
                3,
                (row) => Expanded(
                  child: Row(
                    children: List.generate(
                      3,
                      (column) => Expanded(
                        child: Center(
                          child: _pips[value]!.contains(row * 3 + column)
                              ? Container(
                                  width: 4.5,
                                  height: 4.5,
                                  decoration: BoxDecoration(
                                    color: pip,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.label, required this.onPressed, this.size = 40});
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: label,
        child: Material(
          color: const Color(0xFF12213D),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ludoGold.withOpacity(0.82), width: 1.3), boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 5, offset: Offset(0, 2))]),
              child: Icon(icon, color: ludoCream, size: size * 0.53),
            ),
          ),
        ),
      );
}

class LudoQuickActionButton extends StatelessWidget {
  const LudoQuickActionButton({super.key, required this.icon, required this.label, required this.onPressed});
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: label,
        child: Material(
          color: const Color(0xFF14223B),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: ludoGold.withOpacity(0.75))),
              child: Icon(icon, color: ludoGold, size: 24),
            ),
          ),
        ),
      );
}
