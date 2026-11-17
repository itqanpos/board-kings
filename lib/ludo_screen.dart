import 'package:flutter/material.dart';
import 'ludo_engine.dart';

class LudoScreen extends StatefulWidget {
  const LudoScreen({super.key});

  @override
  State<LudoScreen> createState() => _LudoScreenState();
}

class _LudoScreenState extends State<LudoScreen> {
  List<Token> tokens = getInitialTokens();
  int currentPlayer = 0; // 0: red, 1: green, 2: yellow, 3: blue
  int? diceValue;
  bool hasRolled = false;
  bool isMoving = false;
  String message = 'دور اللاعب: الأحمر';

  void rollDice() {
    if (hasRolled || isMoving) return;
    setState(() {
      diceValue = LudoEngine.rollDice();
      hasRolled = true;
      message = 'رمى ${LudoEngine.names[currentPlayer]} الرقم $diceValue';
    });

    // Check if player has any valid moves
    bool canAnyMove = tokens
        .where((t) => t.color == LudoEngine.colors[currentPlayer])
        .any((t) => t.pos == -1 ? diceValue == 6 : t.pos + diceValue! <= 58);

    if (!canAnyMove) {
      Future.delayed(const Duration(seconds: 1500), () {
        if (mounted) {
          setState(() {
            hasRolled = false;
            diceValue = null;
            currentPlayer = (currentPlayer + 1) % 4;
            message = 'لا توجد حركة متاحة! دور اللاعب: ${LudoEngine.names[currentPlayer]}';
          });
        }
      });
    }
  }

  void moveToken(Token token) async {
    if (!hasRolled || isMoving) return;
    if (token.color != LudoEngine.colors[currentPlayer]) {
      setState(() => message = 'ليس دورك يا ${token.color}!');
      return;
    }

    int dice = diceValue!;
    if (token.pos == -1 && dice != 6) {
      setState(() => message = 'تحتاج إلى رقم 6 لإخراج القطعة!');
      return;
    }

    if (token.pos != -1 && token.pos + dice > 58) {
      setState(() => message = 'الرقم أكبر من المتبقي للوصول!');
      return;
    }

    setState(() => isMoving = true);

    int targetPos = token.pos == -1 ? 0 : token.pos + dice;

    // Check for captures
    if (targetPos <= 51 && !LudoEngine.safeSpots.contains(targetPos)) {
      for (var other in tokens) {
        if (other.color != token.color && other.pos != -1 && other.pos <= 51) {
          int otherAbsPos = (other.pos + LudoEngine.startOffsets[other.color]!) % 52;
          int currentAbsPos = (targetPos + LudoEngine.startOffsets[token.color]!) % 52;
          if (otherAbsPos == currentAbsPos) {
            setState(() {
              other.pos = -1;
              message = 'تم أكل قطعة المنافس!';
            });
          }
        }
      }
    }

    setState(() {
      token.pos = targetPos;
    });

    // Check Win
    bool playerWon = tokens
        .where((t) => t.color == LudoEngine.colors[currentPlayer])
        .every((t) => t.pos == 58);

    if (playerWon) {
      setState(() {
        message = '🎉 الفائز هو اللاعب ${LudoEngine.names[currentPlayer]}!';
      });
      return;
    }

    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      isMoving = false;
      hasRolled = false;
      diceValue = null;
      if (dice != 6) {
        currentPlayer = (currentPlayer + 1) % 4;
      } else {
        message = 'حصلت على 6! لك دور إضافي.';
      }
      if (!playerWon) {
        message += ' | دور اللاعب: ${LudoEngine.names[currentPlayer]}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: const Text('BOARD KINGS — LUDO', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2D2D44),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Status Header
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D44),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          // Game Board Area
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, spreadRadius: 2)],
                  ),
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: Size.infinite,
                        painter: LudoBoardPainter(),
                      ),
                      // Render Tokens
                      ...tokens.map((token) {
                        final coords = LudoEngine.getTokenCoords(token.color, token.pos, token.index);
                        return AnimatedPositioned(
                          duration: const Duration(milliseconds: 300),
                          left: coords[0] * (MediaQuery.of(context).size.width / 15),
                          top: coords[1] * (MediaQuery.of(context).size.width / 15),
                          child: GestureDetector(
                            onTap: () => moveToken(token),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: LudoEngine.colorValues[token.color],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                              ),
                              child: Center(
                                child: Text(
                                  '${token.index + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Controls & Dice Area
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2D2D44),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('اللاعب الحالي', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: LudoEngine.colorValues[LudoEngine.colors[currentPlayer]],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        LudoEngine.names[currentPlayer]!,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: hasRolled ? null : rollDice,
                  icon: const Icon(Icons.casino),
                  label: Text(diceValue == null ? 'رمي النرد' : 'الرقم: $diceValue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LudoBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    double cellSize = size.width / 15;

    // Draw Bases
    paint.color = Colors.red.shade100;
    canvas.drawRect(Rect.fromLTWH(0, 0, cellSize * 6, cellSize * 6), paint);

    paint.color = Colors.green.shade100;
    canvas.drawRect(Rect.fromLTWH(cellSize * 9, 0, cellSize * 6, cellSize * 6), paint);

    paint.color = Colors.amber.shade100;
    canvas.drawRect(Rect.fromLTWH(0, cellSize * 9, cellSize * 6, cellSize * 6), paint);

    paint.color = Colors.blue.shade100;
    canvas.drawRect(Rect.fromLTWH(cellSize * 9, cellSize * 9, cellSize * 6, cellSize * 6), paint);

    // Draw Grid Lines / Safe spots decoration
    paint.style = PaintingStyle.stroke;
    paint.color = Colors.grey.shade400;
    for (int i = 0; i <= 15; i++) {
      canvas.drawLine(Offset(i * cellSize, 0), Offset(i * cellSize, size.height), paint);
      canvas.drawLine(Offset(0, i * cellSize), Offset(size.width, i * cellSize), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
