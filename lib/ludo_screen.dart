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

  // روابط صور القطع 3D
  final Map<String, String> tokenImages = {
    'red': 'https://cdn-icons-png.flaticon.com/512/3097/3097180.png',
    'green': 'https://cdn-icons-png.flaticon.com/512/3097/3097193.png',
    'blue': 'https://cdn-icons-png.flaticon.com/512/3097/3097178.png',
    'yellow': 'https://cdn-icons-png.flaticon.com/512/3097/3097185.png',
  };

  // روابط صور الزهر
  final Map<int, String> diceImages = {
    1: 'https://cdn-icons-png.flaticon.com/512/123/123402.png',
    2: 'https://cdn-icons-png.flaticon.com/512/123/123400.png',
    3: 'https://cdn-icons-png.flaticon.com/512/123/123399.png',
    4: 'https://cdn-icons-png.flaticon.com/512/123/123398.png',
    5: 'https://cdn-icons-png.flaticon.com/512/123/123397.png',
    6: 'https://cdn-icons-png.flaticon.com/512/123/123396.png',
  };

  // روابط صور اللاعبين
  final List<String> avatarImages = [
    'https://api.dicebear.com/7.x/avataaars/png?seed=Felix',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Aneka',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Jack',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Lily',
  ];

  void rollDice() {
    if (hasRolled) return;
    
    final roll = (DateTime.now().millisecondsSinceEpoch % 6) + 1;
    setState(() {
      diceValue = roll;
      hasRolled = true;
      message = '';
    });

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

      if (token.pos < 52) {
        int absPos = (token.pos + LudoEngine.startOffsets[token.color]!) % 52;
        if (!LudoEngine.safeSpots.contains(absPos)) {
          for (var other in tokens) {
            if (other.color != token.color && other.pos != -1 && other.pos < 52) {
              int otherAbsPos = (other.pos + LudoEngine.startOffsets[other.color]!) % 52;
              if (otherAbsPos == absPos) {
                other.pos = -1; 
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
            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)], // خلفية نجيلة داكنة وفخمة
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. شريط اللاعبين العلوي
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                color: Colors.black.withOpacity(0.2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (index) {
                    bool isActive = currentPlayer == index;
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isActive ? LudoEngine.colorValues[LudoEngine.colors[index]]! : Colors.white30,
                              width: isActive ? 3 : 2,
                            ),
                            boxShadow: isActive ? [BoxShadow(color: LudoEngine.colorValues[LudoEngine.colors[index]]!, blurRadius: 10)] : [],
                          ),
                          child: CircleAvatar(
                            radius: isActive ? 22 : 18,
                            backgroundImage: NetworkImage(avatarImages[index]),
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          LudoEngine.names[index]!,
                          style: TextStyle(
                            color: isActive ? Colors.yellow : Colors.white70,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
              
              // 2. اللوحة الخشبية
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF5D4037), width: 8), // إطار خشبي
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 20, offset: Offset(0, 10))],
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          double cellSize = constraints.maxWidth / 15;
                          return Stack(
                            children: [
                              CustomPaint(
                                size: Size.infinite,
                                painter: LudoBoardPainter(),
                              ),
                              // القطع
                              ...tokens.map((token) {
                                int tokenIndex = int.parse(token.id.split('-')[1]);
                                final coords = LudoEngine.getTokenCoords(token.color, token.pos, tokenIndex);
                                
                                return Positioned(
                                  left: coords[0] * cellSize,
                                  top: coords[1] * cellSize,
                                  child: GestureDetector(
                                    onTap: () => moveToken(token),
                                    child: Container(
                                      width: cellSize,
                                      height: cellSize,
                                      padding: EdgeInsets.all(cellSize * 0.1),
                                      child: Image.network(
                                        tokenImages[token.color]!,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          );
                        }
                      ),
                    ),
                  ),
                ),
              ),

              // 3. الشريط السفلي (التحكم)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Column(
                  children: [
                    if (message.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(message, style: const TextStyle(color: Colors.yellow, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // أزرار الشات والصوت
                        Row(
                          children: [
                            _buildCircleBtn(Icons.mic),
                            const SizedBox(width: 10),
                            _buildCircleBtn(Icons.chat_bubble),
                          ],
                        ),
                        
                        // الزهر وزر الرمي
                        GestureDetector(
                          onTap: rollDice,
                          child: Container(
                            width: 75, height: 75,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 8))],
                            ),
                            child: diceValue == 0 
                              ? const Center(child: Text('🎲', style: TextStyle(fontSize: 45)))
                              : Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.network(diceImages[diceValue]!),
                                ),
                          ),
                        ),

                        // زر التخطي
                        hasRolled 
                          ? ElevatedButton(
                              onPressed: () => endTurn(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              ),
                              child: const Text('تخطي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            )
                          : const SizedBox(width: 70), // مساحة فارغة للحفاظ على التوازن
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

  Widget _buildCircleBtn(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white30, width: 2),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

// رسام اللوحة (محسن بألوان وظلال)
class LudoBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = Colors.grey.shade300;
    double cellSize = size.width / 15;

    // دالة مساعدة لرسم المربعات
    void drawCell(int x, int y, Color color, {bool isSafe = false}) {
      paint.color = color;
      Rect rect = Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize);
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, borderPaint);
      
      if (isSafe) {
        // رسم نجمة صغيرة أو علامة للخانات الآمنة
        final starPaint = Paint()..color = Colors.grey.shade400;
        canvas.drawCircle(Offset((x + 0.5) * cellSize, (y + 0.5) * cellSize), cellSize * 0.15, starPaint);
      }
    }

    // 1. المسار الرئيسي
    for (int i = 0; i < LudoEngine.mainPath.length; i++) {
      final pos = LudoEngine.mainPath[i];
      bool isSafe = LudoEngine.safeSpots.contains(i);
      drawCell(pos[0], pos[1], Colors.white, isSafe: isSafe);
    }

    // 2. مسارات النهاية
    for (var color in LudoEngine.colors) {
      for (int i = 0; i < 5; i++) {
        final pos = LudoEngine.getTokenCoords(color, 52 + i, 0);
        drawCell(pos[0].toInt(), pos[1].toInt(), LudoEngine.colorValues[color]!);
      }
    }

    // 3. البيوت (مع تأثير الظل الداخلي)
    void drawBase(int x, int y, Color color) {
      paint.color = color;
      RRect rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x * cellSize, y * cellSize, 6 * cellSize, 6 * cellSize),
        Radius.circular(cellSize * 0.8),
      );
      canvas.drawRRect(rrect, paint);

      // المربع الأبيض الداخلي
      paint.color = Colors.white;
      RRect inner = RRect.fromRectAndRadius(
        Rect.fromLTWH((x + 1) * cellSize, (y + 1) * cellSize, 4 * cellSize, 4 * cellSize),
        Radius.circular(cellSize * 0.5),
      );
      canvas.drawRRect(inner, paint);
    }

    drawBase(0, 0, LudoEngine.colorValues['red']!);
    drawBase(9, 0, LudoEngine.colorValues['green']!);
    drawBase(0, 9, LudoEngine.colorValues['yellow']!);
    drawBase(9, 9, LudoEngine.colorValues['blue']!);

    // 4. المثلثات الوسطى
    Path centerTriangle = Path();
    double cx = 7.5 * cellSize;
    double cy = 7.5 * cellSize;

    centerTriangle.moveTo(6 * cellSize, 6 * cellSize);
    centerTriangle.lineTo(9 * cellSize, 6 * cellSize);
    centerTriangle.lineTo(cx, cy);
    paint.color = LudoEngine.colorValues['red']!;
    canvas.drawPath(centerTriangle, paint);

    centerTriangle.reset();
    centerTriangle.moveTo(9 * cellSize, 6 * cellSize);
    centerTriangle.lineTo(9 * cellSize, 9 * cellSize);
    centerTriangle.lineTo(cx, cy);
    paint.color = LudoEngine.colorValues['green']!;
    canvas.drawPath(centerTriangle, paint);

    centerTriangle.reset();
    centerTriangle.moveTo(9 * cellSize, 9 * cellSize);
    centerTriangle.lineTo(6 * cellSize, 9 * cellSize);
    centerTriangle.lineTo(cx, cy);
    paint.color = LudoEngine.colorValues['blue']!;
    canvas.drawPath(centerTriangle, paint);

    centerTriangle.reset();
    centerTriangle.moveTo(6 * cellSize, 9 * cellSize);
    centerTriangle.lineTo(6 * cellSize, 6 * cellSize);
    centerTriangle.lineTo(cx, cy);
    paint.color = LudoEngine.colorValues['yellow']!;
    canvas.drawPath(centerTriangle, paint);
    
    // حدود المثلثات
    final linePaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawLine(Offset(6 * cellSize, 6 * cellSize), Offset(9 * cellSize, 9 * cellSize), linePaint);
    canvas.drawLine(Offset(9 * cellSize, 6 * cellSize), Offset(6 * cellSize, 9 * cellSize), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
