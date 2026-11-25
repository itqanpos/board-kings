import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../ludo_engine.dart' as board;
import '../engine/ludo_engine.dart';
import 'ludo_style.dart';

class LudoBoardView extends StatelessWidget {
  const LudoBoardView({
    super.key,
    required this.game,
    required this.legalPieceIds,
    required this.onPieceTap,
    required this.tableSkin,
    required this.piecesSkin,
  });

  final LudoGameState game;
  final Set<String> legalPieceIds;
  final ValueChanged<LudoPiece> onPieceTap;
  final String tableSkin;
  final String piecesSkin;

  @override
  Widget build(BuildContext context) {
    final pieces = game.pieces.values.expand((entries) => entries).toList();
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFE09A), Color(0xFF9A541D), Color(0xFFFFC95C), Color(0xFF4C2514)]),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.48), blurRadius: 24, offset: const Offset(0, 12)),
          BoxShadow(color: ludoGold.withOpacity(0.15), blurRadius: 24, spreadRadius: 1),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: const Color(0xFF2D1710), borderRadius: BorderRadius.circular(19), border: Border.all(color: const Color(0xFF60391D))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cell = constraints.maxWidth / 15;
              return Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(painter: LudoPremiumBoardPainter(style: tableSkin.replaceFirst('ludo_table_', ''))),
                  for (final piece in pieces)
                    _LudoPawn(
                      key: ValueKey(piece.id),
                      piece: piece,
                      cell: cell,
                      highlighted: legalPieceIds.contains(piece.id),
                      onTap: () => onPieceTap(piece),
                      stackIndex: _stackIndex(piece, pieces),
                      stackSize: _piecesAtSameVisualSquare(piece, pieces).length,
                      appearanceStyle: piecesSkin.replaceFirst('ludo_pieces_', ''),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class LudoPremiumBoardPainter extends CustomPainter {
  const LudoPremiumBoardPainter({this.style = 'classic'});

  final String style;

  static const List<List<int>> _track = [
    [6, 13], [6, 12], [6, 11], [6, 10], [6, 9], [5, 8], [4, 8], [3, 8], [2, 8], [1, 8], [0, 8], [0, 7], [0, 6],
    [1, 6], [2, 6], [3, 6], [4, 6], [5, 6], [6, 5], [6, 4], [6, 3], [6, 2], [6, 1], [6, 0], [7, 0], [8, 0],
    [8, 1], [8, 2], [8, 3], [8, 4], [8, 5], [9, 6], [10, 6], [11, 6], [12, 6], [13, 6], [14, 6], [14, 7], [14, 8],
    [13, 8], [12, 8], [11, 8], [10, 8], [9, 8], [8, 9], [8, 10], [8, 11], [8, 12], [8, 13], [8, 14], [7, 14], [6, 14],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 15;
    final background = style == 'oak' || style == 'regal' ? const Color(0xFF3A251A) : const Color(0xFF211A18);
    final paint = Paint()..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paint..color = background);

    final baseColors = <Rect, Color>{
      Rect.fromLTWH(0, 0, cell * 6, cell * 6): ludoPlayerColors[LudoColor.red]!,
      Rect.fromLTWH(cell * 9, 0, cell * 6, cell * 6): ludoPlayerColors[LudoColor.green]!,
      Rect.fromLTWH(0, cell * 9, cell * 6, cell * 6): ludoPlayerColors[LudoColor.yellow]!,
      Rect.fromLTWH(cell * 9, cell * 9, cell * 6, cell * 6): ludoPlayerColors[LudoColor.blue]!,
    };
    for (final entry in baseColors.entries) {
      canvas.drawRect(entry.key, paint..color = entry.value.withOpacity(0.82));
      final inset = entry.key.deflate(cell * 0.82);
      canvas.drawRRect(RRect.fromRectAndRadius(inset, Radius.circular(cell * 0.42)), paint..color = const Color(0xFFFFF5DF));
      for (var index = 0; index < 4; index++) {
        final center = Offset(
          entry.key.left + cell * (1.5 + (index % 2) * 2),
          entry.key.top + cell * (1.5 + (index ~/ 2) * 2),
        );
        canvas.drawCircle(center, cell * 0.42, paint..color = entry.value.withOpacity(0.17));
        canvas.drawCircle(center, cell * 0.32, Paint()..color = Colors.white.withOpacity(0.84));
        canvas.drawCircle(center, cell * 0.24, Paint()..color = entry.value.withOpacity(0.32));
      }
    }

    final trackPaint = Paint()..color = const Color(0xFFFFF8E9);
    final linePaint = Paint()..color = const Color(0xFF493828)..style = PaintingStyle.stroke..strokeWidth = math.max(0.65, cell * 0.025).toDouble();
    for (final square in _track) {
      final rect = Rect.fromLTWH(square[0] * cell, square[1] * cell, cell, cell).deflate(cell * 0.035);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.055)), trackPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.055)), linePaint);
    }

    final lanes = <LudoColor, List<Offset>>{
      LudoColor.red: [for (var x = 1; x <= 6; x++) Offset(x.toDouble(), 7)],
      LudoColor.green: [for (var y = 1; y <= 6; y++) Offset(7, y.toDouble())],
      LudoColor.yellow: [for (var x = 13; x >= 8; x--) Offset(x.toDouble(), 7)],
      LudoColor.blue: [for (var y = 13; y >= 8; y--) Offset(7, y.toDouble())],
    };
    for (final entry in lanes.entries) {
      for (final point in entry.value) {
        final rect = Rect.fromLTWH(point.dx * cell, point.dy * cell, cell, cell).deflate(cell * 0.035);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.055)), Paint()..color = ludoPlayerColors[entry.key]!);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.055)), linePaint);
      }
    }

    final startIndices = <LudoColor, int>{LudoColor.red: 0, LudoColor.green: 13, LudoColor.yellow: 26, LudoColor.blue: 39};
    for (final entry in startIndices.entries) {
      final point = _track[entry.value];
      final rect = Rect.fromLTWH(point[0] * cell, point[1] * cell, cell, cell).deflate(cell * 0.08);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.08)), Paint()..color = ludoPlayerColors[entry.key]!);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.08)), linePaint);
    }

    final center = Offset(cell * 7.5, cell * 7.5);
    final corners = <(Offset, Color)>[
      (Offset(cell * 6, cell * 6), ludoPlayerColors[LudoColor.green]!),
      (Offset(cell * 9, cell * 6), ludoPlayerColors[LudoColor.yellow]!),
      (Offset(cell * 9, cell * 9), ludoPlayerColors[LudoColor.blue]!),
      (Offset(cell * 6, cell * 9), ludoPlayerColors[LudoColor.red]!),
    ];
    for (var index = 0; index < corners.length; index++) {
      final path = Path()
        ..moveTo(corners[index].$1.dx, corners[index].$1.dy)
        ..lineTo(corners[(index + 1) % corners.length].$1.dx, corners[(index + 1) % corners.length].$1.dy)
        ..lineTo(center.dx, center.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = corners[index].$2);
    }
    canvas.drawCircle(center, cell * 0.28, Paint()..color = ludoGold);
    canvas.drawCircle(center, cell * 0.16, Paint()..color = const Color(0xFFFFF2D0));

    for (final safeIndex in const [0, 8, 13, 21, 26, 34, 39, 47]) {
      final point = _track[safeIndex];
      final centerPoint = Offset((point[0] + 0.5) * cell, (point[1] + 0.5) * cell);
      canvas.drawCircle(centerPoint, cell * 0.12, Paint()..color = ludoGold.withOpacity(0.9));
    }

    canvas.drawRect(Offset.zero & size, Paint()..style = PaintingStyle.stroke..strokeWidth = math.max(1, cell * 0.07).toDouble()..color = const Color(0xFFFFD47E));
  }

  @override
  bool shouldRepaint(covariant LudoPremiumBoardPainter oldDelegate) => oldDelegate.style != style;
}

class _LudoPawn extends StatelessWidget {
  const _LudoPawn({super.key, required this.piece, required this.cell, required this.highlighted, required this.onTap, required this.stackIndex, required this.stackSize, required this.appearanceStyle});

  final LudoPiece piece;
  final double cell;
  final bool highlighted;
  final VoidCallback onTap;
  final int stackIndex;
  final int stackSize;
  final String appearanceStyle;

  @override
  Widget build(BuildContext context) {
    final point = board.LudoEngine.getTokenCoords(piece.color.name, piece.position, piece.index, stackIndex: stackIndex, stackSize: stackSize);
    final size = cell * (stackSize == 1 ? 0.8 : 0.8 / math.sqrt(stackSize).ceil());
    final color = ludoPlayerColors[piece.color]!;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
      left: point[0] * cell + (cell - size) / 2,
      top: point[1] * cell + (cell - size) / 2,
      width: size,
      height: size,
      child: Semantics(
        button: highlighted,
        label: '${ludoPlayerNames[piece.color]}، قطعة ${piece.index + 1}${highlighted ? '، حركة قانونية' : ''}',
        child: GestureDetector(
          onTap: highlighted ? onTap : null,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: highlighted ? 1.09 : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withOpacity(highlighted ? 0.62 : 0.26), blurRadius: highlighted ? 13 : 6, spreadRadius: highlighted ? 2 : 0)],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(bottom: 1, child: Container(width: size * 0.84, height: size * 0.24, decoration: BoxDecoration(gradient: LinearGradient(colors: [Color.lerp(color, Colors.white, 0.34)!, color, Color.lerp(color, Colors.black, 0.3)!]), borderRadius: BorderRadius.circular(99), border: Border.all(color: ludoGold.withOpacity(highlighted ? 0.95 : 0.45), width: math.max(0.6, size * 0.035).toDouble()), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 2))]))),
                  Positioned(bottom: size * 0.16, child: CustomPaint(size: Size(size * 0.72, size * 0.6), painter: _PawnBodyPainter(color: color, highlighted: highlighted, skin: appearanceStyle))),
                  Positioned(top: size * 0.02, child: Container(width: size * 0.34, height: size * 0.34, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color.lerp(color, Colors.white, 0.62)!, color, Color.lerp(color, Colors.black, 0.18)!]), border: Border.all(color: Colors.white.withOpacity(0.72), width: math.max(0.7, size * 0.04).toDouble()), boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 1))]))),
                  if (highlighted) Positioned(top: 0, right: size * 0.04, child: Icon(Icons.auto_awesome_rounded, size: size * 0.2, color: ludoCream)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PawnBodyPainter extends CustomPainter {
  const _PawnBodyPainter({required this.color, required this.highlighted, required this.skin});
  final Color color;
  final bool highlighted;
  final String skin;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..cubicTo(size.width * 0.4, size.height * 0.33, size.width * 0.22, size.height * 0.54, size.width * 0.1, size.height * 0.78)
      ..quadraticBezierTo(size.width * 0.06, size.height, size.width * 0.25, size.height)
      ..lineTo(size.width * 0.75, size.height)
      ..quadraticBezierTo(size.width * 0.94, size.height, size.width * 0.9, size.height * 0.78)
      ..cubicTo(size.width * 0.78, size.height * 0.54, size.width * 0.6, size.height * 0.33, size.width * 0.5, 0)
      ..close();
    final rect = Offset.zero & size;
    canvas.drawShadow(path, Colors.black.withOpacity(0.52), 4, true);
    canvas.drawPath(path, Paint()..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color.lerp(color, Colors.white, 0.5)!, color, Color.lerp(color, Colors.black, 0.37)!]).createShader(rect));
    canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = math.max(0.7, size.width * 0.035).toDouble()..color = highlighted || skin == 'gold' ? ludoGold : Colors.white.withOpacity(0.68));
    canvas.drawLine(Offset(size.width * 0.33, size.height * 0.72), Offset(size.width * 0.5, size.height * 0.18), Paint()..strokeCap = StrokeCap.round..strokeWidth = math.max(0.7, size.width * 0.045).toDouble()..color = Colors.white.withOpacity(0.24));
  }

  @override
  bool shouldRepaint(covariant _PawnBodyPainter oldDelegate) => oldDelegate.color != color || oldDelegate.highlighted != highlighted || oldDelegate.skin != skin;
}

List<LudoPiece> _piecesAtSameVisualSquare(LudoPiece piece, List<LudoPiece> pieces) {
  final matching = pieces.where((candidate) {
    if (piece.position == -1 || candidate.position == -1) return piece.id == candidate.id;
    if (piece.position < board.LudoEngine.trackLength && candidate.position < board.LudoEngine.trackLength) {
      return board.LudoEngine.getAbsoluteTrackPosition(piece.color.name, piece.position) == board.LudoEngine.getAbsoluteTrackPosition(candidate.color.name, candidate.position);
    }
    if (piece.position == 58 || candidate.position == 58) return piece.position == 58 && candidate.position == 58;
    return piece.color == candidate.color && piece.position == candidate.position;
  }).toList()..sort((a, b) {
      final colorOrder = a.color.index.compareTo(b.color.index);
      return colorOrder != 0 ? colorOrder : a.index.compareTo(b.index);
    });
  return matching;
}

int _stackIndex(LudoPiece piece, List<LudoPiece> pieces) => _piecesAtSameVisualSquare(piece, pieces).indexWhere((candidate) => candidate.id == piece.id);
