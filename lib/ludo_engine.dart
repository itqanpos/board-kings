import 'package:flutter/material.dart';

class LudoEngine {
  // مسار اللودو الدقيق (52 خطوة) 
  static const List<List<int>> mainPath = [
    [6,13],[6,12],[6,11],[6,10],[6,9],[5,8],[4,8],[3,8],[2,8],[1,8],[0,8],[0,7],
    [0,6],[1,6],[2,6],[3,6],[4,6],[5,6],[6,5],[6,4],[6,3],[6,2],[6,1],[6,0],[7,0],
    [8,0],[8,1],[8,2],[8,3],[8,4],[8,5],[9,6],[10,6],[11,6],[12,6],[13,6],[14,6],
    [14,7],[14,8],[13,8],[12,8],[11,8],[10,8],[9,8],[8,9],[8,10],[8,11],[8,12],
    [8,13],[8,14],[7,14],[6,14]
  ];

  static const List<String> colors = ['red', 'green', 'blue', 'yellow'];
  
  static const Map<String, Color> colorValues = {
    'red': Color(0xFFFF3B30),
    'green': Color(0xFF34C759),
    'blue': Color(0xFF007AFF),
    'yellow': Color(0xFFFFCC00)
  };
  
  static const Map<int, String> names = { 0: 'أحمد', 1: 'محمد', 2: 'سارة', 3: 'علي' };

  static const Map<String, int> startOffsets = { 'red': 0, 'green': 13, 'blue': 26, 'yellow': 39 };
  static const List<int> safeSpots = [0, 8, 13, 21, 26, 34, 39, 47];

  // إحداثيات البيوت
  static const Map<String, List<List<double>>> bases = {
    'red': [[2,2],[4,2],[2,4],[4,4]],
    'green': [[10,2],[12,2],[10,4],[12,4]],
    'blue': [[10,10],[12,10],[10,12],[12,12]],
    'yellow': [[2,10],[4,10],[2,12],[4,12]]
  };

  // إحداثيات مسار النهاية
  static const Map<String, List<List<double>>> homePaths = {
    'red': [[1,7],[2,7],[3,7],[4,7],[5,7],[7.5,7.5]],
    'green': [[7,1],[7,2],[7,3],[7,4],[7,5],[7.5,7.5]],
    'blue': [[13,7],[12,7],[11,7],[10,7],[9,7],[7.5,7.5]],
    'yellow': [[7,13],[7,12],[7,11],[7,10],[7,9],[7.5,7.5]]
  };

  // دالة حساب مكان القطعة
  static List<double> getTokenCoords(String color, int pos, int tokenIndex) {
    if (pos == -1) return bases[color]![tokenIndex];
    if (pos >= 52) {
      int homeIndex = pos - 52;
      return homePaths[color]![homeIndex >= 5 ? 5 : homeIndex];
    }
    int absolutePos = (startOffsets[color]! + pos) % 52;
    return mainPath[absolutePos].map((e) => e.toDouble()).toList();
  }
}

// كلاس القطعة
class Token {
  final String id;
  final String color;
  int pos;
  final int index;

  Token({required this.id, required this.color, required this.pos, required this.index});
}

// دالة توليد القطع الـ 16 في البداية
List<Token> getInitialTokens() {
  List<Token> tokens = [];
  for (int c = 0; c < LudoEngine.colors.length; c++) {
    String color = LudoEngine.colors[c];
    for (int i = 0; i < 4; i++) {
      tokens.add(Token(id: '$color-$i', color: color, pos: -1, index: c));
    }
  }
  return tokens;
}
