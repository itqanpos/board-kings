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
  static const int trackLength = 52;
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

  /// Returns the absolute shared-track square for a piece's relative progress.
  /// Returns null for base, home-lane, finished, or invalid positions.
  static int? getAbsoluteTrackPosition(String color, int pos) {
    final offset = startOffsets[color];
    if (offset == null || pos < 0 || pos >= trackLength) return null;
    return (offset + pos) % trackLength;
  }

  /// Precise coordinate mapping for the 15x15 board.
  /// [pos] remains relative game progress; color selects the correct route entry.
  /// Stack offsets affect drawing only and never feed back into game rules.
  static List<double> getTokenCoords(
    String color,
    int pos,
    int index, {
    int stackIndex = 0,
    int stackSize = 1,
  }) {
    if (pos == -1) {
      // Base slots coordinates
      final baseOffsets = {
        'red': [[1.5, 1.5], [3.5, 1.5], [1.5, 3.5], [3.5, 3.5]],
        'green': [[10.5, 1.5], [12.5, 1.5], [10.5, 3.5], [12.5, 3.5]],
        'yellow': [[1.5, 10.5], [3.5, 10.5], [1.5, 12.5], [3.5, 12.5]],
        'blue': [[10.5, 10.5], [12.5, 10.5], [10.5, 12.5], [12.5, 12.5]],
      };
      final slots = baseOffsets[color]!;
      return slots[index];
    }

    late final List<double> point;
    if (pos >= 52 && pos <= 57) {
      final step = pos - 52;
      final stretchCoords = {
        'red': [1.0 + step, 7.0],
        'green': [7.0, 1.0 + step],
        'yellow': [13.0 - step, 7.0],
        'blue': [7.0, 13.0 - step],
      };
      point = stretchCoords[color]!;
    } else if (pos == 58) {
      point = [7.0, 7.0];
    } else {
      final absolutePosition = getAbsoluteTrackPosition(color, pos);
      point = absolutePosition == null
          ? [7.0, 7.0]
          : _getMainTrackCoords(absolutePosition);
    }

    return _applyStackOffset(point, stackIndex, stackSize);
  }

  static List<double> _applyStackOffset(
    List<double> point,
    int stackIndex,
    int stackSize,
  ) {
    if (stackSize <= 1 || stackIndex < 0 || stackIndex >= stackSize) {
      return point;
    }

    if (stackSize == 2) {
      return [point[0] + (stackIndex == 0 ? -0.26 : 0.26), point[1]];
    }

    if (stackSize <= 4) {
      const offsets = [
        [-0.26, -0.26],
        [0.26, -0.26],
        [-0.26, 0.26],
        [0.26, 0.26],
      ];
      return [
        point[0] + offsets[stackIndex][0],
        point[1] + offsets[stackIndex][1],
      ];
    }

    const columns = 4;
    final rows = (stackSize / columns).ceil();
    final column = stackIndex % columns;
    final row = stackIndex ~/ columns;
    return [
      point[0] + (column - (columns - 1) / 2) * 0.32,
      point[1] + (row - (rows - 1) / 2) * 0.32,
    ];
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
