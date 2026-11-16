import 'package:flutter/material.dart';
import 'ludo_engine.dart';

class LudoScreen extends StatefulWidget {
  const LudoScreen({super.key});

  @override
  State<LudoScreen> createState() => _LudoScreenState();
}

class _LudoScreenState extends State<LudoScreen> {
  List<Token> tokens = getInitialTokens();
  int currentPlayer = 0;
  int diceValue = 0;
  bool hasRolled = false;
  String message = '';

  void rollDice() {
    if (hasRolled) return;
    
    final roll = (DateTime.now().millisecondsSinceEpoch % 6) + 1;
    setState(() {
      diceValue = roll;
      hasRolled = true;
      message = '';
    });

    // هل فيه حركة متاحة؟
    bool hasValidMove = false;
    for (var token in tokens) {
      if (token.color == LudoEngine.colors[currentPlayer]) {
        if (token.pos == -1 && roll == 6) hasValidMove = true;
        if (token.pos != -1 && token.pos + roll <= 57) hasValidMove = true;
      }
    }

    if (!hasValidMove) {
      setState(() => message = 'لا توجد حركات متاحة');
      Future.delayed(const Duration(milliseconds: 1500), () => endTurn());
    }
  }

  void endTurn({bool extraTurn = false}) {
    setState(() {
      diceValue = 0;
      hasRolled = false;
      if (!extraTurn) {
        currentPlayer = (currentPlayer + 1) % 4;
      }
    });
  }

  void moveToken(Token token) {
    if (!hasRolled) return;
    if (token.color != LudoEngine.colors[currentPlayer]) return;

    setState(() {
      if (token.pos == -1 && diceValue == 6) {
        token.pos = 0;
      } else if (token.pos != -1) {
        if (token.pos + diceValue > 57) return;
        token.pos += diceValue;
      }

      // منطق الأكل
      if (token.pos < 52) {
        int absPos = (token.pos + LudoEngine.startOffsets[token.color]!) % 52;
        if (!LudoEngine.safeSpots.contains(absPos)) {
          for (var other in tokens) {
            if (other.color != token.color && other.pos != -1 && other.pos < 52) {
              int otherAbsPos = (other.pos + LudoEngine.startOffsets[other.color]!) % 52;
              if (otherAbsPos == absPos) {
                other.pos = -1; // رجوع للبيت
                message = 'تم أكل قطعة ${LudoEngine.names[other.index]}!';
              }
            }
          }
        }
      }
    });

    endTurn(extraTurn: diceValue == 6);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF388E3C), Color(0xFF1B5E20)], // خلفية نجيلة
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // الشريط العلوي
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(4, (index) {
                    bool isActive = currentPlayer == index;
                    return Column(
                      children: [
                        CircleAvatar(
                          backgroundColor: LudoEngine.colorValues[LudoEngine.colors[index]],
                          radius: isActive ? 25 : 20,
                          child: Text(
                            LudoEngine.names[index]![0],
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          LudoEngine.names[index]!,
                          style: TextStyle(
                            color: isActive ? Colors.yellow : Colors.white70,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
              
              // اللوحة
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF5D4037), width: 6),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15, offset: Offset(0, 10))],
                      ),
                      child: Stack(
                        children: [
                          CustomPaint(
                            size: Size.infinite,
                            painter: LudoBoardPainter(),
                          ),
                          ...tokens.map((token) {
                            final coords = LudoEngine.getTokenCoords(token.color, token.pos, token.index == 0 ? (token.id.split('-')[1] == '0' ? 0 : (token.id.split('-')[1] == '1' ? 1 : (token.id.split('-')[1] == '2' ? 2 : 3))) : 0);
                            // (ملاحظة: طريقة حساب الإحداثيات هنا مبسطة، وتحتاج LayoutBuilder للدقة العالية، لكنها ستعمل)
                            
                            return LayoutBuilder(
                              builder: (context, constraints) {
                                double cellSize = constraints.maxWidth / 15;
                                return Positioned(
                                  left: coords[0] * cellSize,
                                  top: coords[1] * cellSize,
                                  child: GestureDetector(
                                    onTap: () => moveToken(token),
                                    child: Container(
                                      width: cellSize,
                                      height: cellSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: LudoEngine.colorValues[token.color],
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(1, 2))],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // الشريط السفلي (الزهر)
              Container(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    if (message.isNotEmpty)
                      Text(message, style: const TextStyle(color: Colors.yellow, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // زرار الرمي
                        GestureDetector(
                          onTap: rollDice,
                          child: Container(
                            width: 70, height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 8))],
                            ),
                            child: Center(
                              child: diceValue == 0 
                                ? const Text('🎲', style: TextStyle(fontSize: 40))
                                : Text(
                                    diceValue.toString(), 
                                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: LudoEngine.colorValues[LudoEngine.colors[currentPlayer]]),
                                  ),
                            ),
                          ),
                        ),
                        // زرار التخطي
                        if (hasRolled)
                          ElevatedButton(
                            onPressed: () => endTurn(),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                            child: const Text('تخطي', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// رسام اللوحة
class LudoBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = Colors.grey.shade400;
    double cellSize = size.width / 15;

    // دالة مساعدة لرسم المربعات
    void drawCell(int x, int y, Color color) {
      paint.color = color;
      Rect rect = Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize);
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, borderPaint);
    }

    // 1. رسم المسار الرئيسي
    for (int i = 0; i < LudoEngine.mainPath.length; i++) {
      final pos = LudoEngine.mainPath[i];
      Color color = LudoEngine.safeSpots.contains(i) ? Colors.amber.shade100 : Colors.white;
      drawCell(pos[0], pos[1], color);
    }

    // 2. رسم مسارات النهاية
    for (var color in LudoEngine.colors) {
      for (int i = 0; i < 5; i++) {
        final pos = LudoEngine.getTokenCoords(color, 52 + i, 0);
        drawCell(pos[0].toInt(), pos[1].toInt(), LudoEngine.colorValues[color]!);
      }
    }

    // 3. رسم البيوت الأربعة
    void drawBase(int x, int y, Color color) {
      paint.color = color;
      RRect rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x * cellSize, y * cellSize, 6 * cellSize, 6 * cellSize),
        Radius.circular(cellSize * 0.5),
      );
      canvas.drawRRect(rrect, paint);

      paint.color = Colors.white;
      RRect inner = RRect.fromRectAndRadius(
        Rect.fromLTWH((x + 1) * cellSize, (y + 1) * cellSize, 4 * cellSize, 4 * cellSize),
        Radius.circular(cellSize * 0.3),
      );
      canvas.drawRRect(inner, paint);
    }

    drawBase(0, 0, LudoEngine.colorValues['red']!);
    drawBase(9, 0, LudoEngine.colorValues['green']!);
    drawBase(0, 9, LudoEngine.colorValues['yellow']!);
    drawBase(9, 9, LudoEngine.colorValues['blue']!);

    // 4. رسم المثلثات الوسطى
    Path centerTriangle = Path();
    double cx = 7.5 * cellSize;
    double cy = 7.5 * cellSize;

    // أحمر
    centerTriangle.moveTo(6 * cellSize, 6 * cellSize);
    centerTriangle.lineTo(9 * cellSize, 6 * cellSize);
    centerTriangle.lineTo(cx, cy);
    paint.color = LudoEngine.colorValues['red']!;
    canvas.drawPath(centerTriangle, paint);

    // أخضر
    centerTriangle.reset();
    centerTriangle.moveTo(9 * cellSize, 6 * cellSize);
    centerTriangle.lineTo(9 * cellSize, 9 * cellSize);
    centerTriangle.lineTo(cx, cy);
    paint.color = LudoEngine.colorValues['green']!;
    canvas.drawPath(centerTriangle, paint);

    // أزرق
    centerTriangle.reset();
    centerTriangle.moveTo(9 * cellSize, 9 * cellSize);
    centerTriangle.lineTo(6 * cellSize, 9 * cellSize);
    centerTriangle.lineTo(cx, cy);
    paint.color = LudoEngine.colorValues['blue']!;
    canvas.drawPath(centerTriangle, paint);

    // أصفر
    centerTriangle.reset();
    centerTriangle.moveTo(6 * cellSize, 9 * cellSize);
    centerTriangle.lineTo(6 * cellSize, 6 * cellSize);
    centerTriangle.lineTo(cx, cy);
    paint.color = LudoEngine.colorValues['yellow']!;
    canvas.drawPath(centerTriangle, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
