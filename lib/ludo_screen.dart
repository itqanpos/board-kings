import 'dart:async';
import 'dart:ui' as ui;
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
  bool isRolling = false;
  bool isMoving = false;
  String message = '';

  final Map<String, String> tokenImages = {
    'red': 'https://cdn-icons-png.flaticon.com/512/3097/3097180.png',
    'green': 'https://cdn-icons-png.flaticon.com/512/3097/3097193.png',
    'blue': 'https://cdn-icons-png.flaticon.com/512/3097/3097178.png',
    'yellow': 'https://cdn-icons-png.flaticon.com/512/3097/3097185.png',
  };

  final Map<int, String> diceImages = {
    1: 'https://cdn-icons-png.flaticon.com/512/123/123402.png',
    2: 'https://cdn-icons-png.flaticon.com/512/123/123400.png',
    3: 'https://cdn-icons-png.flaticon.com/512/123/123399.png',
    4: 'https://cdn-icons-png.flaticon.com/512/123/123398.png',
    5: 'https://cdn-icons-png.flaticon.com/512/123/123397.png',
    6: 'https://cdn-icons-png.flaticon.com/512/123/123396.png',
  };

  final List<String> avatarImages = [
    'https://api.dicebear.com/7.x/avataaars/png?seed=Felix',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Aneka',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Jack',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Lily',
  ];

  void rollDice() async {
    if (hasRolled || isRolling || isMoving) return;
    
    setState(() {
      isRolling = true;
      message = '';
    });

    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        setState(() {
          diceValue = (DateTime.now().millisecondsSinceEpoch % 6) + 1;
        });
      }
    }

    final finalRoll = (DateTime.now().millisecondsSinceEpoch % 6) + 1;
    
    if (mounted) {
      setState(() {
        diceValue = finalRoll;
        isRolling = false;
        hasRolled = true;
      });

      bool hasValidMove = false;
      for (var token in tokens) {
        if (token.color == LudoEngine.colors[currentPlayer]) {
          if (token.pos == -1 && finalRoll == 6) hasValidMove = true;
          if (token.pos != -1 && token.pos + finalRoll <= 57) hasValidMove = true;
        }
      }

      if (!hasValidMove) {
        setState(() => message = 'لا توجد حركات متاحة');
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) endTurn();
      }
    }
  }

  void endTurn({bool extraTurn = false}) {
    if (mounted) {
      setState(() {
        diceValue = 0;
        hasRolled = false;
        if (!extraTurn) {
          currentPlayer = (currentPlayer + 1) % 4;
        }
      });
    }
  }

  void moveToken(Token token) async {
    if (!hasRolled || isMoving) return;
    if (token.color != LudoEngine.colors[currentPlayer]) return;

    setState(() {
      isMoving = true;
      hasRolled = false;
    });

    int targetPos = token.pos == -1 ? 0 : token.pos + diceValue;
    if (targetPos > 57) {
      setState(() => isMoving = false);
      return;
    }

    if (token.pos == -1) {
      setState(() => token.pos = 0);
      await Future.delayed(const Duration(milliseconds: 300));
    } else {
      int steps = targetPos - token.pos;
      for (int i = 0; i < steps; i++) {
        await Future.delayed(const Duration(milliseconds: 150));
        if (mounted) setState(() => token.pos += 1);
      }
    }

    // فحص الأكل
    if (token.pos < 52) {
      int absPos = (token.pos + LudoEngine.startOffsets[token.color]!) % 52;
      if (!LudoEngine.safeSpots.contains(absPos)) {
        for (var other in tokens) {
          if (other.color != token.color && other.pos != -1 && other.pos < 52) {
            int otherAbsPos = (other.pos + LudoEngine.startOffsets[other.color]!) % 52;
            if (otherAbsPos == absPos) {
              if (mounted) setState(() { other.pos = -1; message = 'تم أكل قطعة ${LudoEngine.names[other.index]}!'; });
            }
          }
        }
      }
    }

    if (mounted) {
      setState(() => isMoving = false);
      endTurn(extraTurn: diceValue == 6);
    }
  }

  // دالة لحساب مكان القطع لو أكتر من قطعة في نفس الخانة
  List<Offset> _getStackedTokenOffsets(List<Token> allTokens, Token currentToken) {
    List<Token> tokensInSameSpot = allTokens.where((t) => t.pos == currentToken.pos && t.pos != -1).toList();
    if (tokensInSameSpot.length <= 1) return [Offset.zero];

    int index = tokensInSameSpot.indexOf(currentToken);
    // توزيع القطع بشكل دائري أو جانبي لو أكتر من واحدة
    double offsetX = (index % 2 == 0 ? -0.15 : 0.15);
    double offsetY = (index < 2 ? -0.15 : 0.15);
    return [Offset(offsetX, offsetY)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3B1E), Color(0xFF0D1A0D)], // خلفية خشبية داكنة
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. شريط اللاعبين
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1))
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (index) {
                    bool isActive = currentPlayer == index;
                    return Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isActive ? LudoEngine.colorValues[LudoEngine.colors[index]]! : Colors.white24,
                              width: isActive ? 3 : 2,
                            ),
                            boxShadow: isActive ? [BoxShadow(color: LudoEngine.colorValues[LudoEngine.colors[index]]!, blurRadius: 12, spreadRadius: 2)] : [],
                          ),
                          child: CircleAvatar(
                            radius: isActive ? 24 : 20,
                            backgroundImage: NetworkImage(avatarImages[index]),
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          LudoEngine.names[index]!,
                          style: TextStyle(
                            color: isActive ? Colors.yellow : Colors.white60,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
              
              // 2. اللوحة
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF3E2723), width: 10), // إطار خشبي غامق
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 25, offset: Offset(0, 15))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            double cellSize = constraints.maxWidth / 15;
                            return Stack(
                              children: [
                                CustomPaint(
                                  size: Size.infinite,
                                  painter: LudoBoardPainter(),
                                ),
                                ...tokens.map((token) {
                                  int tokenIndex = int.parse(token.id.split('-')[1]);
                                  final coords = LudoEngine.getTokenCoords(token.color, token.pos, tokenIndex);
                                  
                                  // حساب الإزاحة لو أكتر من قطعة في نفس المكان
                                  final offset = _getStackedTokenOffsets(tokens, token).first;

                                  bool canMove = hasRolled && !isMoving && token.color == LudoEngine.colors[currentPlayer] && (token.pos == -1 ? diceValue == 6 : token.pos + diceValue <= 57);

                                  return AnimatedPositioned(
                                    duration: const Duration(milliseconds: 150),
                                    curve: Curves.easeInOut,
                                    left: (coords[0] + offset.dx) * cellSize,
                                    top: (coords[1] + offset.dy) * cellSize,
                                    child: GestureDetector(
                                      onTap: () => moveToken(token),
                                      child: Container(
                                        width: cellSize,
                                        height: cellSize,
                                        padding: EdgeInsets.all(cellSize * 0.05),
                                        child: AnimatedScale(
                                          scale: canMove ? 1.3 : 1.0,
                                          duration: const Duration(milliseconds: 200),
                                          child: Image.network(
                                            tokenImages[token.color]!,
                                            fit: BoxFit.contain,
                                          ),
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
              ),

              // 3. الشريط السفلي
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    if (message.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(message, style: const TextStyle(color: Colors.yellow, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _buildCircleBtn(Icons.mic),
                            const SizedBox(width: 10),
                            _buildCircleBtn(Icons.chat_bubble),
                          ],
                        ),
                        
                        // الزهر
                        GestureDetector(
                          onTap: rollDice,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isRolling ? 65 : 80,
                            height: isRolling ? 65 : 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 12, offset: Offset(0, 8))],
                              border: Border.all(color: Colors.grey.shade300, width: 2),
                            ),
                            child: diceValue == 0 
                              ? const Center(child: Text('🎲', style: TextStyle(fontSize: 45)))
                              : Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.network(diceImages[diceValue]!),
                                ),
                          ),
                        ),

                        hasRolled && !isMoving
                          ? ElevatedButton(
                              onPressed: () => endTurn(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade600,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                elevation: 5,
                              ),
                              child: const Text('تخطي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            )
                          : const SizedBox(width: 70),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

// رسام اللوحة النهائي
class LudoBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = Colors.black26;
    double cellSize = size.width / 15;

    void drawCell(int x, int y, Color color, {bool isSafe = false}) {
      paint.color = color;
      Rect rect = Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize);
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, borderPaint);
      
      if (isSafe) {
        final starPaint = Paint()..color = Colors.grey.shade400;
        Path star = Path();
        double cx = (x + 0.5) * cellSize;
        double cy = (y + 0.5) * cellSize;
        double r = cellSize * 0.25;
        star.moveTo(cx, cy - r);
        star.lineTo(cx + r * 0.3, cy - r * 0.3);
        star.lineTo(cx + r, cy - r * 0.3);
        star.lineTo(cx + r * 0.4, cy + r * 0.2);
        star.lineTo(cx + r * 0.6, cy + r);
        star.lineTo(cx, cy + r * 0.4);
        star.lineTo(cx - r * 0.6, cy + r);
        star.lineTo(cx - r * 0.4, cy + r * 0.2);
        star.lineTo(cx - r, cy - r * 0.3);
        star.lineTo(cx - r * 0.3, cy - r * 0.3);
        star.close();
        canvas.drawPath(star, starPaint);
      }
    }

    // المسار
    for (int i = 0; i < LudoEngine.mainPath.length; i++) {
      final pos = LudoEngine.mainPath[i];
      bool isSafe = LudoEngine.safeSpots.contains(i);
      drawCell(pos[0], pos[1], Colors.white, isSafe: isSafe);
    }

    // مسارات النهاية
    for (var color in LudoEngine.colors) {
      for (int i = 0; i < 5; i++) {
        final pos = LudoEngine.getTokenCoords(color, 52 + i, 0);
        drawCell(pos[0].toInt(), pos[1].toInt(), LudoEngine.colorValues[color]!);
      }
    }

    // البيوت
    void drawBase(int x, int y, Color color) {
      Rect baseRect = Rect.fromLTWH(x * cellSize, y * cellSize, 6 * cellSize, 6 * cellSize);
      
      paint.shader = ui.Gradient.linear(
        baseRect.topLeft,
        baseRect.bottomRight,
        [color.withOpacity(0.9), color.withOpacity(0.6)],
      );
      
      RRect rrect = RRect.fromRectAndRadius(baseRect, Radius.circular(cellSize * 0.5));
      canvas.drawRRect(rrect, paint);
      paint.shader = null;

      paint.color = Colors.white;
      RRect inner = RRect.fromRectAndRadius(
        Rect.fromLTWH((x + 1.2) * cellSize, (y + 1.2) * cellSize, 3.6 * cellSize, 3.6 * cellSize),
        Radius.circular(cellSize * 0.3),
      );
      canvas.drawRRect(inner, paint);
      
      // ظل داخلي للبيت
      paint.style = PaintingStyle.stroke;
      paint.color = Colors.black.withOpacity(0.15);
      paint.strokeWidth = 6;
      canvas.drawRRect(inner, paint);
      paint.style = PaintingStyle.fill;
    }

    drawBase(0, 0, LudoEngine.colorValues['red']!);
    drawBase(9, 0, LudoEngine.colorValues['green']!);
    drawBase(0, 9, LudoEngine.colorValues['yellow']!);
    drawBase(9, 9, LudoEngine.colorValues['blue']!);

    // المثلثات
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
    
    final linePaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawLine(Offset(6 * cellSize, 6 * cellSize), Offset(9 * cellSize, 9 * cellSize), linePaint);
    canvas.drawLine(Offset(9 * cellSize, 6 * cellSize), Offset(6 * cellSize, 9 * cellSize), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
