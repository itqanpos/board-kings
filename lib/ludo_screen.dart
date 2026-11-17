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
  bool hasRolled = hasRolled = false;
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
      Future.delayed(const Duration(milliseconds: 1500), () {
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
              message = 'تم أكل قطعة المنافس وإعادتها للقاعدة!';
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
      _showWinDialog(LudoEngine.names[currentPlayer]!);
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

  void _showWinDialog(String winnerName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: const Text('🎉 مبروك الفوز!', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Text('الفائز في هذه الجولة هو اللاعب $winnerName!', style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  tokens = getInitialTokens();
                  currentPlayer = 0;
                  hasRolled = false;
                  diceValue = null;
                  message = 'بدأت لعبة جديدة! دور اللاعب: الأحمر';
                });
              },
              child: const Text('إعادة اللعب'),
            ),
          ),
        ],
      ),
    );
  }

  // Calculate stacked offsets if multiple tokens are on the exact same board coordinate
  List<double> _getStackedOffset(Token currentToken, List<Token> allTokens) {
    final baseCoords = LudoEngine.getTokenCoords(currentToken.color, currentToken.pos, currentToken.index);
    if (currentToken.pos == -1) return [baseCoords[0].toDouble(), baseCoords[1].toDouble()];

    final sameSpotTokens = allTokens.where((t) => t.pos == currentToken.pos && t.pos != -1).toList();
    if (sameSpotTokens.length <= 1) return [baseCoords[0].toDouble(), baseCoords[1].toDouble()];

    int indexInSpot = sameSpotTokens.indexWhere((t) => t.id == currentToken.id);
    double offsetX = 0.0;
    double offsetY = 0.0;
    if (indexInSpot == 1) {
      offsetX = 0.2;
    } else if (indexInSpot == 2) {
      offsetY = 0.2;
    } else if (indexInSpot == 3) {
      offsetX = 0.2;
      offsetY = 0.2;
    }
    return [baseCoords[0].toDouble() + offsetX, baseCoords[1].toDouble() + offsetY];
  }

  @override
  Widget build(BuildContext context) {
    double screenSize = MediaQuery.of(context).size.width > 500 ? 500 : MediaQuery.of(context).size.width;
    double cellSize = screenSize / 15;

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
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D44),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
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
              child: SizedBox(
                width: screenSize,
                height: screenSize,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, spreadRadius: 2)],
                  ),
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: Size(screenSize, screenSize),
                        painter: LudoBoardPainter(),
                      ),
                      // Render Tokens with Stacked Offsets
                      ...tokens.map((token) {
                        final coords = _getStackedOffset(token, tokens);
                        return AnimatedPositioned(
                          duration: const Duration(milliseconds: 300),
                          left: coords[0] * cellSize,
                          top: coords[1] * cellSize,
                          child: GestureDetector(
                            onTap: () => moveToken(token),
                            child: Container(
                              width: cellSize * 0.8,
                              height: cellSize * 0.8,
                              decoration: BoxDecoration(
                                color: LudoEngine.colorValues[token.color],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, spreadRadius: 1)],
                              ),
                              child: Center(
                                child: Text(
                                  '${token.index + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
                    const Text('اللاعب الحالي', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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

    // Draw Center Home
    paint.color = Colors.grey.shade200;
    canvas.drawRect(Rect.fromLTWH(cellSize * 6, cellSize * 6, cellSize * 3, cellSize * 3), paint);

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
