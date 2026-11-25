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
      diceValue = (1 + (DateTime.now().millisecond % 6));
      hasRolled = true;
      message = 'رمى ${LudoEngine.names[currentPlayer]} الرقم $diceValue';
    });

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
        backgroundColor: const Color(0xFF161622),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.amber, width: 2)),
        title: const Text('🎉 مبروك الفوز الاحترافي!', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Text('الفائز في هذه المعركة هو اللاعب $winnerName!', style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  tokens = getInitialTokens();
                  currentPlayer = 0;
                  hasRolled = false;
                  diceValue = null;
                  message = 'بدأت ملحمة جديدة! دور اللاعب: الأحمر';
                });
              },
              child: const Text('معركة جديدة', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  List<double> _getStackedOffset(Token currentToken, List<Token> allTokens) {
    final baseCoords = LudoEngine.getTokenCoords(currentToken.color, currentToken.pos, currentToken.index);
    if (currentToken.pos == -1) return [baseCoords[0].toDouble(), baseCoords[1].toDouble()];

    final sameSpotTokens = allTokens.where((t) => t.pos == currentToken.pos && t.pos != -1).toList();
    if (sameSpotTokens.length <= 1) return [baseCoords[0].toDouble(), baseCoords[1].toDouble()];

    int indexInSpot = sameSpotTokens.indexWhere((t) => t.id == currentToken.id);
    double offsetX = (indexInSpot == 1 || indexInSpot == 3) ? 0.15 : 0.0;
    double offsetY = (indexInSpot >= 2) ? 0.15 : 0.0;
    return [baseCoords[0].toDouble() + offsetX, baseCoords[1].toDouble() + offsetY];
  }

  @override
  Widget build(BuildContext context) {
    double screenSize = MediaQuery.of(context).size.width > 500 ? 500 : MediaQuery.of(context).size.width - 24;
    double cellSize = screenSize / 15;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B10),
      appBar: AppBar(
        title: const Text('BOARD KINGS — AAA EDITION', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.amber)),
        backgroundColor: const Color(0xFF13131F),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Professional Status HUD
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF161622),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.1), blurRadius: 10)],
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          // Masterpiece Board Area
          Expanded(
            child: Center(
              child: SizedBox(
                width: screenSize,
                height: screenSize,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF13131F),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white12, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black87, blurRadius: 24, spreadRadius: 4),
                      BoxShadow(color: Color(0x22FFFFFF), blurRadius: 4, spreadRadius: 1),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: Size(screenSize, screenSize),
                          painter: AAAProLudoBoardPainter(),
                        ),
                        ...tokens.map((token) {
                          final coords = _getStackedOffset(token, tokens);
                          bool isActivePlayer = token.color == LudoEngine.colors[currentPlayer];
                          return AnimatedPositioned(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                            left: coords[0] * cellSize,
                            top: coords[1] * cellSize,
                            child: GestureDetector(
                              onTap: () => moveToken(token),
                              child: Container(
                                width: cellSize * 0.85,
                                height: cellSize * 0.85,
                                decoration: BoxDecoration(
                                  color: LudoEngine.colorValues[token.color],
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isActivePlayer ? LudoEngine.colorValues[token.color]!.withOpacity(0.8) : Colors.black45,
                                      blurRadius: isActivePlayer ? 10 : 4,
                                      spreadRadius: isActivePlayer ? 2 : 0,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '${token.index + 1}',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
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
          ),
          // Luxury Bottom HUD & Controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF13131F),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('دور اللاعب النشط', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: LudoEngine.colorValues[LudoEngine.colors[currentPlayer]],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: LudoEngine.colorValues[LudoEngine.colors[currentPlayer]]!.withOpacity(0.5), blurRadius: 8)],
                      ),
                      child: Text(
                        LudoEngine.names[currentPlayer]!,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: hasRolled ? null : rollDice,
                  icon: const Icon(Icons.casino, color: Colors.black),
                  label: Text(diceValue == null ? 'رمي النرد الفاخر' : 'الرقم: $diceValue', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
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

class AAAProLudoBoardPainter extends CustomPainter {
  const AAAProLudoBoardPainter({this.style = 'classic'});

  final String style;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final surfaceColor = switch (style) {
      'oak' => const Color(0xFF3A2D26),
      'regal' => const Color(0xFF342824),
      'neon' => const Color(0xFF112B37),
      'galaxy' => const Color(0xFF211E3B),
      'forest' => const Color(0xFF1B332B),
      _ => const Color(0xFF171F2D),
    };
    final accentColor = switch (style) {
      'oak' => const Color(0xFFD5B487),
      'regal' => const Color(0xFFF4C66A),
      'neon' => const Color(0xFF84F4FF),
      'galaxy' => const Color(0xFFB7A6FF),
      'forest' => const Color(0xFF8CE6A7),
      _ => Colors.white,
    };
    canvas.drawRect(Offset.zero & size, paint..color = surfaceColor);
    double cellSize = size.width / 15;

    // 1. Draw Corner Bases with Premium Dark Tint
    void drawBase(double x, double y, Color color) {
      paint.color = color.withOpacity(0.2);
      canvas.drawRect(Rect.fromLTWH(x * cellSize, y * cellSize, cellSize * 6, cellSize * 6), paint);

      // Keep the four player colors intact while styling the neutral base inset.
      paint.color = surfaceColor.withOpacity(0.88);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH((x + 1) * cellSize, (y + 1) * cellSize, cellSize * 4, cellSize * 4),
          const Radius.circular(12),
        ),
        paint,
      );

      // Draw 4 Base Token Circles
      paint.color = color.withOpacity(0.8);
      for (int i = 0; i < 4; i++) {
        double cx = (x + 1.5 + (i % 2) * 2) * cellSize;
        double cy = (y + 1.5 + (i ~/ 2) * 2) * cellSize;
        canvas.drawCircle(Offset(cx, cy), cellSize * 0.7, paint);
      }
    }

    drawBase(0, 0, const Color(0xFFFF334B)); // Red
    drawBase(9, 0, const Color(0xFF00E676)); // Green
    drawBase(0, 9, const Color(0xFFFFD600)); // Yellow
    drawBase(9, 9, const Color(0xFF2979FF)); // Blue

    // 2. Draw Center Home Destination (Triangle Triad)
    paint.color = surfaceColor.withOpacity(0.92);
    canvas.drawRect(Rect.fromLTWH(cellSize * 6, cellSize * 6, cellSize * 3, cellSize * 3), paint);

    // Center triangles
    final pathRed = Path()
      ..moveTo(cellSize * 6, cellSize * 6)
      ..lineTo(cellSize * 9, cellSize * 6)
      ..lineTo(cellSize * 7.5, cellSize * 7.5)
      ..close();
    paint.color = const Color(0xFFFF334B);
    canvas.drawPath(pathRed, paint);

    final pathGreen = Path()
      ..moveTo(cellSize * 9, cellSize * 6)
      ..lineTo(cellSize * 9, cellSize * 9)
      ..lineTo(cellSize * 7.5, cellSize * 7.5)
      ..close();
    paint.color = const Color(0xFF00E676);
    canvas.drawPath(pathGreen, paint);

    final pathBlue = Path()
      ..moveTo(cellSize * 9, cellSize * 9)
      ..lineTo(cellSize * 6, cellSize * 9)
      ..lineTo(cellSize * 7.5, cellSize * 7.5)
      ..close();
    paint.color = const Color(0xFF2979FF);
    canvas.drawPath(pathBlue, paint);

    final pathYellow = Path()
      ..moveTo(cellSize * 6, cellSize * 9)
      ..lineTo(cellSize * 6, cellSize * 6)
      ..lineTo(cellSize * 7.5, cellSize * 7.5)
      ..close();
    paint.color = const Color(0xFFFFD600);
    canvas.drawPath(pathYellow, paint);

    // 3. Draw Grid Lines & Borders with Neon Accent
    paint.style = PaintingStyle.stroke;
    paint.color = accentColor.withOpacity(style == 'classic' ? 0.08 : 0.2);
    paint.strokeWidth = 1;
    for (int i = 0; i <= 15; i++) {
      canvas.drawLine(Offset(i * cellSize, 0), Offset(i * cellSize, size.height), paint);
      canvas.drawLine(Offset(0, i * cellSize), Offset(size.width, i * cellSize), paint);
    }
  }

  @override
  bool shouldRepaint(covariant AAAProLudoBoardPainter oldDelegate) => oldDelegate.style != style;
}
