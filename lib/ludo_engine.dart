// lib/ludo_engine.dart
import 'package:flutter/material.dart';

class Token {
  final String id;
  final String color; // 'red', 'green', 'yellow', 'blue'
  final int index;    // 0 to 3 index of the token
  int pos;            // -1: base, 0-51: main track, 52-57: home stretch, 58: finished

  Token({
    required this.id,
    required this.color,
    required this.index,
    required this.pos,
  });

  Token copyWith({int? pos, int? index}) {
    return Token(
      id: id,
      color: color,
      index: index ?? this.index,
      pos: pos ?? this.pos,
    );
  }
}

List<Token> getInitialTokens() {
  List<Token> tokens = [];
  for (int c = 0; c < LudoEngine.colors.length; c++) {
    String color = LudoEngine.colors[c];
    for (int i = 0; i < 4; i++) {
      tokens.add(Token(id: '$color-$i', color: color, index: i, pos: -1));
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

  static const Map<int, String> names = {
    0: 'الأحمر',
    1: 'الأخضر',
    2: 'الأصفر',
    3: 'الأزرق',
  };

  static const Map<String, int> startOffsets = {
    'red': 0,
    'green': 13,
    'yellow': 26,
    'blue': 39,
  };

  static const List<int> safeSpots = [0, 8, 13, 21, 26, 34, 39, 47];

  // Main path coordinates as List<List<double>> so indexing (pos[0], pos[1]) works correctly
  static final List<List<double>> mainPath = List.generate(
    52,
    (index) => [(index % 15).toDouble(), (index ~/ 15).toDouble()],
  );

  static List<double> getTokenCoords(String color, int pos, int index) {
    if (pos == -1) {
      double baseX = 2.0 + (index % 2) * 2.0;
      double baseY = 2.0 + (index ~/ 2) * 2.0;
      return [baseX, baseY];
    } else if (pos >= 52) {
      return [7.0, 7.0];
    } else {
      return [(pos % 15).toDouble(), (pos ~/ 15).toDouble()];
    }
  }
}
