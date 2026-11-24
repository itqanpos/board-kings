import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../ludo_engine.dart' as board;
import '../../ludo_screen.dart' show AAAProLudoBoardPainter;
import '../../shared/widgets/game_ui.dart';
import 'engine/ludo_engine.dart';

const Map<LudoColor, Color> _playerColors = {
  LudoColor.red: Color(0xFFFF775F),
  LudoColor.green: Color(0xFF6BD8C8),
  LudoColor.yellow: Color(0xFFF4C66A),
  LudoColor.blue: Color(0xFF789BFF),
};

const Map<LudoColor, String> _playerNames = {
  LudoColor.red: 'الأحمر',
  LudoColor.green: 'الأخضر',
  LudoColor.yellow: 'الأصفر',
  LudoColor.blue: 'الأزرق',
};

class LudoGameScreen extends StatefulWidget {
  const LudoGameScreen({super.key});

  @override
  State<LudoGameScreen> createState() => _LudoGameScreenState();
}

class _LudoGameScreenState extends State<LudoGameScreen> {
  LudoGameState _game = LudoGameState.initial();
  String _message = 'ارمِ النرد لبدء دور اللاعب الأحمر';

  List<LudoPiece> get _legalPieces {
    final die = _game.diceValue;
    if (die == null) return const [];
    return (_game.pieces[_game.currentTurn] ?? const <LudoPiece>[])
        .where((piece) => LudoEngine.isValidMove(_game, _game.currentTurn, piece.id, die))
        .toList();
  }

  void _rollDice() {
    if (_game.diceValue != null || _game.winner != null) return;
    var next = LudoEngine.recordRoll(_game, LudoEngine.rollDice());
    if (next.diceValue == null) {
      setState(() {
        _game = next;
        _message = 'ثلاثة أرقام ٦ متتالية؛ انتقل الدور إلى ${_playerNames[next.currentTurn]}';
      });
      return;
    }

    final rolledValue = next.diceValue!;
    next = LudoEngine.skipIfNoLegalMove(next);
    setState(() {
      _game = next;
      _message = next.diceValue == null
          ? 'لا توجد حركة قانونية بالرقم $rolledValue؛ الدور التالي ${_playerNames[next.currentTurn]}'
          : 'ظهر الرقم $rolledValue؛ اختر قطعة مضيئة للتحرك';
    });
  }

  void _movePiece(LudoPiece piece) {
    final die = _game.diceValue;
    if (die == null || !LudoEngine.isValidMove(_game, _game.currentTurn, piece.id, die)) return;
    final next = LudoEngine.applyMove(_game, _game.currentTurn, piece.id, die);
    setState(() {
      _game = next;
      _message = next.winner == null
          ? (next.currentTurn == piece.color
              ? 'حركة موفقة؛ لديك دور إضافي. ارمِ النرد مجدداً.'
              : 'انتهى الدور؛ اللاعب ${_playerNames[next.currentTurn]} يلعب الآن.')
          : 'فاز اللاعب ${_playerNames[next.winner!]}!';
    });
    if (next.winner != null) _showWinner(next.winner!);
  }

  void _restart() {
    setState(() {
      _game = LudoGameState.initial();
      _message = 'بدأت جولة جديدة؛ ارمِ النرد.';
    });
  }

  void _showWinner(LudoColor winner) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: panel,
        title: const Text('انتهت الجولة'),
        content: Text('الفائز هو ${_playerNames[winner]}.', textAlign: TextAlign.center),
        actions: [
          TextButton(onPressed: () { Navigator.pop(dialogContext); _restart(); }, child: const Text('جولة جديدة')),
          TextButton(onPressed: () { Navigator.pop(dialogContext); context.pop(); }, child: const Text('إنهاء')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('لودو'),
          leading: IconButton(tooltip: 'إنهاء المباراة', onPressed: () => context.pop(), icon: const Icon(Icons.arrow_forward_rounded)),
          actions: [IconButton(tooltip: 'إعادة المباراة', onPressed: _restart, icon: const Icon(Icons.refresh_rounded))],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 3, 16, 9),
                child: Column(
                  children: [
                    _PlayerTurnBar(current: _game.currentTurn, message: _message),
                    const SizedBox(height: 10),
                    Row(
                      children: LudoColor.values.map((color) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: _PlayerPill(
                            color: color,
                            active: color == _game.currentTurn,
                            progress: _game.pieces[color]!.where((piece) => piece.position == LudoEngine.finishPosition).length,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final side = math.min(math.min(constraints.maxWidth, constraints.maxHeight), 500.0);
                    return Center(
                      child: SizedBox.square(
                        dimension: side,
                        child: _LudoBoard(game: _game, legalPieceIds: _legalPieces.map((piece) => piece.id).toSet(), onPieceTap: _movePiece),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 9, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(17)),
                        child: Row(
                          children: [
                            AnimatedRotation(
                              turns: _game.diceValue == null ? 0 : _game.diceValue! / 6,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutBack,
                              child: const Icon(Icons.casino_rounded, color: aqua, size: 27),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: Text(
                                  _game.diceValue == null ? 'النرد جاهز' : 'النتيجة ${_game.diceValue}',
                                  key: ValueKey<int?>(_game.diceValue),
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _game.diceValue == null && _game.winner == null ? _rollDice : null,
                        icon: const Icon(Icons.casino_rounded),
                        label: const Text('ارمِ النرد'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _PlayerTurnBar extends StatelessWidget {
  const _PlayerTurnBar({required this.current, required this.message});
  final LudoColor current;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(15)),
        child: Row(
          children: [
            Container(width: 10, height: 34, decoration: BoxDecoration(color: _playerColors[current], borderRadius: BorderRadius.circular(8))),
            const SizedBox(width: 11),
            Expanded(child: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: mutedText))),
          ],
        ),
      );
}

class _PlayerPill extends StatelessWidget {
  const _PlayerPill({required this.color, required this.active, required this.progress});
  final LudoColor color;
  final bool active;
  final int progress;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
        decoration: BoxDecoration(
          color: active ? _playerColors[color]!.withOpacity(0.17) : panel,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: active ? _playerColors[color]! : Colors.transparent, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(color: _playerColors[color], shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Flexible(child: Text(_playerNames[color]!, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
            const SizedBox(width: 3),
            Text('$progress/4', style: const TextStyle(fontSize: 9, color: mutedText)),
            if (progress == 4) const Icon(Icons.check, size: 12, color: aqua),
          ],
        ),
      );
}

class _LudoBoard extends StatelessWidget {
  const _LudoBoard({required this.game, required this.legalPieceIds, required this.onPieceTap});
  final LudoGameState game;
  final Set<String> legalPieceIds;
  final ValueChanged<LudoPiece> onPieceTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 22, offset: Offset(0, 9))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cell = constraints.maxWidth / 15;
            return Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: AAAProLudoBoardPainter())),
                for (final pieces in game.pieces.values)
                  for (final piece in pieces)
                    _LudoToken(piece: piece, cell: cell, highlighted: legalPieceIds.contains(piece.id), onTap: () => onPieceTap(piece)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LudoToken extends StatelessWidget {
  const _LudoToken({required this.piece, required this.cell, required this.highlighted, required this.onTap});
  final LudoPiece piece;
  final double cell;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final point = board.LudoEngine.getTokenCoords(piece.color.name, piece.position, piece.index);
    final size = cell * 0.84;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      left: point[0] * cell + (cell - size) / 2,
      top: point[1] * cell + (cell - size) / 2,
      width: size,
      height: size,
      child: Semantics(
        button: highlighted,
        label: '${_playerNames[piece.color]}، قطعة ${piece.index + 1}${highlighted ? '، حركة قانونية' : ''}',
        child: GestureDetector(
          onTap: highlighted ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: _playerColors[piece.color],
              shape: BoxShape.circle,
              border: Border.all(color: highlighted ? Colors.white : const Color(0xFFE9E7E1), width: highlighted ? 2.5 : 1.1),
              boxShadow: [BoxShadow(color: _playerColors[piece.color]!.withOpacity(highlighted ? 0.62 : 0.27), blurRadius: highlighted ? 12 : 5, spreadRadius: highlighted ? 1 : 0)],
            ),
            child: Center(child: Text('${piece.index + 1}', style: const TextStyle(color: ink, fontSize: 9, fontWeight: FontWeight.w900))),
          ),
        ),
      ),
    );
  }
}
