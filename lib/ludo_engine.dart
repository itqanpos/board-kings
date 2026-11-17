import 'package:flutter/material.dart';

class Token {
  final String id;
  final String color; // 'red', 'green', 'yellow', 'blue'
  final int index;    // 0 to 3
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
    'red': Color(0xFFFF334B),
    'green': Color(0xFF00E676),
    'yellow': Color(0xFFFFD600),
    'blue': Color(0xFF2979FF),
  };

  static const Map<String, Color> colorGlowValues = {
    'red': Color(0x66FF334B),
    'green': Color(0x6600E676),
    'yellow': Color(0x66FFD600),
    'blue': Color(0x662979FF),
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

  // Precise coordinate mapping for 15x15 Ludo Board
  static List<double> getTokenCoords(String color, int pos, int index) {
    if (pos == -1) {
      // Base slots coordinates
      final baseOffsets = {
        'red': [[1.5, 1.5], [3.5, 1.5], [1.5, 3.5], [3.5, 3.5]],
        'green': [[10.5, 1.5], [12.5, 1.5], [10.5, 3.5], [12.5, 3.5]],
        'yellow': [[1.5, 10.5], [3.5, 10.5], [1.5, 12.5], [3.5, 12.5]],
        'blue': [[10.5, 10.5], [12.5, 10.5], [10.5, 12.5], [12.5, 12.5]],
      };
      var slots = baseOffsets[color]!;
      return slots[index];
    } else if (pos >= 52 && pos <= 57) {
      // Home stretch coordinates
      int step = pos - 52;
      final stretchCoords = {
        'red': [[1.0 + step, 7.0]],
        'green': [[7.0, 1.0 + step]],
        'yellow': [[13.0 - step, 7.0]],
        'blue': [[7.0, 13.0 - step]],
      };
      return stretchCoords[color]![0];
    } else if (pos == 58) {
      // Center winning position
      return [7.0, 7.0];
    } else {
      // Main 52 track coordinates mapping simplified for professional grid
      return _getMainTrackCoords(pos);
    }
  }

  static List<double> _getMainTrackCoords(int pos) {
    // Standard path mapping across 15x15 grid
    final List<List<double>> path = [
      [6, 13], [6, 12], [6, 11], [6, 10], [6, 9],
      [5, 8], [4, 8], [3, 8], [2, 8], [1, 8], [0, 8],
      [0, 7], [0, 6],
      [1, 6], [2, 6], [3, 6], [4, 6], [5, 6],
      [6, 5], [6, 4], [6, 3], [6, 2], [6, 1], [6, 0],
      [7, 0], [8, 0],
      [8, 1], [8, 2], [8, 3], [8, 4], [8, 5],
      [9, 6], [10, 6], [11, 6], [12, 6], [13, 6], [14, 6],
      [14, 7], [14, 8],
      [13, 8], [12, 8], [11, 8], [10, 8], [9, 8],
      [8, 9], [8, 10], [8, 11], [8, 12], [8, 13], [8, 14],
      [7, 14], [6, 14]
    ];
    if (pos >= 0 && pos < path.length) {
      return path[pos];
    }
    return [7.0, 7.0];
  }
}
