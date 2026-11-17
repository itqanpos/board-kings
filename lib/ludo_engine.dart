// lib/ludo_engine.dart
import 'package:flutter/material.dart';

class Token {
  final String id;
  final String color; // 'red', 'green', 'yellow', 'blue'
  int pos; // -1: base, 0-51: main track, 52-57: home stretch, 58: finished

  Token({
    required this.id,
    required this.color,
    required this.pos,
  });

  Token copyWith({int? pos}) {
    return Token(
      id: id,
      color: color,
      pos: pos ?? this.pos,
    );
  }
}

List<Token> getInitialTokens() {
  List<Token> tokens = [];
  for (var color in LudoEngine.colors) {
    for (int i = 0; i < 4; i++) {
      tokens.add(Token(id: '$color-$i', color: color, pos: -1));
    }
  }
  return tokens;
}

class LudoEngine {
  static const List<String> colors = ['red', 'green', 'yellow', 'blue'];

  static const Map<String, Color> colorValues = {
    'red': Colors.red,
    'green': Colors.green,
    'yellow': Colors.amber,
    'blue': Colors.blue,
  };

  static const Map<String, String> names = {
    'red': 'الأحمر',
    'green': 'الأخضر',
    'yellow': 'الأصفر',
    'blue': 'الأزرق',
  };

  static const Map<String, int> startOffsets = {
    'red': 0,
    'green': 13,
    'yellow': 26,
    'blue': 39,
  };

  static const List<int> safeSpots = [0, 8, 13, 21, 26, 34, 39, 47];

  // Placeholder coordinates for main path (52 steps)
  static final List<Offset> mainPath = List.generate(
    52,
    (index) => Offset((index % 15).toDouble(), (index ~/ 15).toDouble()),
  );

  static List<double> getTokenCoords(String color, int pos, int index) {
    // Returns [x, y] coordinates for rendering tokens on board
    if (pos == -1) {
      // Base positions offset based on index and color
      double baseX = 2.0 + (index % 2) * 2.0;
      double baseY = 2.0 + (index ~/ 2) * 2.0;
      return [baseX, baseY];
    } else if (pos >= 52) {
      // Home stretch
      return [7.0, 7.0];
    } else {
      // Main track coordinates approximation
      return [(pos % 15).toDouble(), (pos ~/ 15).toDouble()];
    }
  }
}
