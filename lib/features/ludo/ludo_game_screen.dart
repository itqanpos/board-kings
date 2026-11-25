import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/local_game_journal.dart';
import '../../ludo_engine.dart' as board;
import '../../ludo_screen.dart' show AAAProLudoBoardPainter;
import '../../shared/widgets/game_ui.dart';
import 'engine/ludo_ai.dart';
import 'engine/ludo_engine.dart';
import '../game_ai_difficulty.dart';
import '../store/data/cosmetic_repository.dart';

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
  bool _aiEnabled = false;
  bool _aiBusy = false;
  GameAiDifficulty _aiDifficulty = GameAiDifficulty.medium;
  Timer? _aiTimer;
  String _tableSkin = 'ludo_table_classic';
  String _diceSkin = 'ludo_dice_classic';
  String _piecesSkin = 'ludo_pieces_classic';

  @override
  void initState() {
    super.initState();
    _loadEquippedCosmetics();
  }

  Future<void> _openCosmetics() async {
    await context.push('/store');
    if (mounted) await _loadEquippedCosmetics();
  }

  Future<void> _loadEquippedCosmetics() async {
    try {
      final items = await CosmeticRepository.loadEquipment('ludo');
      if (!mounted) return;
      setState(() {
        _tableSkin = items['table'] ?? _tableSkin;
        _diceSkin = items['dice'] ?? _diceSkin;
        _piecesSkin = items['pieces'] ?? _piecesSkin;
      });
    } catch (_) {}
  }

  List<LudoPiece> get _legalPieces {
    if (_aiEnabled && _game.currentTurn != LudoColor.red) return const [];
    final die = _game.diceValue;
    if (die == null) return const [];
    return (_game.pieces[_game.currentTurn] ?? const <LudoPiece>[])
        .where((piece) => LudoEngine.isValidMove(_game, _game.currentTurn, piece.id, die))
        .toList();
  }

  void _scheduleAiTurn() {
    if (!_aiEnabled ||
        _aiBusy ||
        _game.currentTurn == LudoColor.red ||
        _game.winner != null) {
      return;
    }
    _aiBusy = true;
    _aiTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      if (!_aiEnabled || _game.currentTurn == LudoColor.red || _game.winner != null) {
        _aiBusy = false;
        return;
      }

      var next = _game;
      if (next.diceValue == null) {
        next = LudoEngine.recordRoll(next, LudoEngine.rollDice());
      }
      if (next.diceValue == null) {
        setState(() {
          _game = next;
          _message = 'ثلاثة أرقام ٦ متتالية؛ انتقل الدور إلى ${_playerNames[next.currentTurn]}';
        });
        _aiBusy = false;
        _scheduleAiTurn();
        return;
      }

      final die = next.diceValue!;
      final pieceId = LudoAi.choosePiece(next, difficulty: _aiDifficulty);
      if (pieceId == null) {
        next = LudoEngine.skipIfNoLegalMove(next);
        setState(() {
          _game = next;
          _message = 'لا توجد حركة قانونية بالرقم $die؛ الدور التالي ${_playerNames[next.currentTurn]}';
        });
      } else {
        final aiColor = next.currentTurn;
        next = LudoEngine.applyMove(next, aiColor, pieceId, die);
        setState(() {
          _game = next;
          _message = next.winner == null
              ? 'حرّك الذكاء الاصطناعي قطعة اللاعب ${_playerNames[aiColor]}'
              : 'فاز اللاعب ${_playerNames[next.winner!]}!';
        });
      }
      _aiBusy = false;
      if (next.winner != null) _showWinner(next.winner!);
      _scheduleAiTurn();
    });
  }

  @override
  void dispose() {
    _aiTimer?.cancel();
    super.dispose();
  }

  void _rollDice() {
    if (_game.diceValue != null ||
        _game.winner != null ||
        (_aiEnabled && _game.currentTurn != LudoColor.red)) {
      return;
    }
    var next = LudoEngine.recordRoll(_game, LudoEngine.rollDice());
    if (next.diceValue == null) {
      setState(() {
        _game = next;
        _message = 'ثلاثة أرقام ٦ متتالية؛ انتقل الدور إلى ${_playerNames[next.currentTurn]}';
      });
      _scheduleAiTurn();
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
    _scheduleAiTurn();
  }

  void _movePiece(LudoPiece piece) {
    if (_aiEnabled && _game.currentTurn != LudoColor.red) return;
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
    _scheduleAiTurn();
  }

  void _restart() {
    _aiTimer?.cancel();
    _aiBusy = false;
    setState(() {
      _game = LudoGameState.initial();
      _message = 'بدأت جولة جديدة؛ ارمِ النرد.';
    });
  }

  void _showWinner(LudoColor winner) {
    unawaited(
      LocalGameJournal.recordResult(
        game: 'ludo',
        playerCount: LudoColor.values.length,
        winner: _playerNames[winner]!,
      ).catchError((Object _) {}),
    );
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
          actions: [
            IconButton(
              tooltip: 'المظاهر',
              onPressed: _openCosmetics,
              icon: const Icon(Icons.storefront_rounded),
            ),
            PopupMenuButton<String>(
              tooltip: 'إعدادات الذكاء الاصطناعي',
              onSelected: (value) {
                setState(() {
                  _aiEnabled = value != 'off';
                  if (value == 'easy') _aiDifficulty = GameAiDifficulty.easy;
                  if (value == 'medium') _aiDifficulty = GameAiDifficulty.medium;
                  if (value == 'hard') _aiDifficulty = GameAiDifficulty.hard;
                });
                if (!_aiEnabled) {
                  _aiTimer?.cancel();
                  _aiBusy = false;
                } else {
                  _scheduleAiTurn();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'off', child: Text('إيقاف الذكاء الاصطناعي')),
                PopupMenuItem(value: 'easy', child: Text('ذكاء اصطناعي سهل')),
                PopupMenuItem(value: 'medium', child: Text('ذكاء اصطناعي متوسط')),
                PopupMenuItem(value: 'hard', child: Text('ذكاء اصطناعي صعب')),
              ],
              icon: Icon(_aiEnabled ? Icons.smart_toy_rounded : Icons.smart_toy_outlined),
            ),
            IconButton(tooltip: 'إعادة المباراة', onPressed: _restart, icon: const Icon(Icons.refresh_rounded)),
          ],
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
                        child: _LudoBoard(
                          game: _game,
                          legalPieceIds: _legalPieces.map((piece) => piece.id).toSet(),
                          onPieceTap: _movePiece,
                          tableSkin: _tableSkin,
                          piecesSkin: _piecesSkin,
                        ),
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
                        decoration: BoxDecoration(
                          color: panel,
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(color: _skinAccent(_diceSkin.replaceFirst('ludo_dice_', '')).withOpacity(0.55)),
                        ),
                        child: Row(
                          children: [
                            AnimatedRotation(
                              turns: _game.diceValue == null ? 0 : _game.diceValue! / 6,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutBack,
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: _diceFaceColor(_diceSkin.replaceFirst('ludo_dice_', '')),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _skinAccent(_diceSkin.replaceFirst('ludo_dice_', '')), width: 1.6),
                                ),
                                child: Center(
                                  child: _game.diceValue == null
                                      ? Icon(Icons.casino_rounded, color: _diceInk(_diceSkin.replaceFirst('ludo_dice_', '')), size: 24)
                                      : Text(
                                          '${_game.diceValue}',
                                          style: TextStyle(color: _diceInk(_diceSkin.replaceFirst('ludo_dice_', '')), fontSize: 20, fontWeight: FontWeight.w900),
                                        ),
                                ),
                              ),
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
                        onPressed: _game.diceValue == null &&
                                _game.winner == null &&
                                (!_aiEnabled || _game.currentTurn == LudoColor.red)
                            ? _rollDice
                            : null,
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
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                child: Text(
                  message,
                  key: ValueKey(message),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: mutedText),
                ),
              ),
            ),
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
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
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
  const _LudoBoard({required this.game, required this.legalPieceIds, required this.onPieceTap, required this.tableSkin, required this.piecesSkin});
  final LudoGameState game;
  final Set<String> legalPieceIds;
  final ValueChanged<LudoPiece> onPieceTap;
  final String tableSkin;
  final String piecesSkin;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _skinAccent(tableSkin.replaceFirst('ludo_table_', '')).withOpacity(0.75), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 22, offset: Offset(0, 9))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cell = constraints.maxWidth / 15;
            final pieces = game.pieces.values.expand((playerPieces) => playerPieces).toList();
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: AAAProLudoBoardPainter(style: tableSkin.replaceFirst('ludo_table_', '')),
                  ),
                ),
                for (final piece in pieces)
                  _LudoToken(
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
    );
  }
}

List<LudoPiece> _piecesAtSameVisualSquare(LudoPiece piece, List<LudoPiece> pieces) {
  final matching = pieces.where((candidate) {
    if (piece.position == -1 || candidate.position == -1) {
      return piece.id == candidate.id;
    }
    if (piece.position < board.LudoEngine.trackLength &&
        candidate.position < board.LudoEngine.trackLength) {
      return board.LudoEngine.getAbsoluteTrackPosition(
            piece.color.name,
            piece.position,
          ) ==
          board.LudoEngine.getAbsoluteTrackPosition(
            candidate.color.name,
            candidate.position,
          );
    }
    if (piece.position == 58 || candidate.position == 58) {
      return piece.position == 58 && candidate.position == 58;
    }
    return piece.color == candidate.color && piece.position == candidate.position;
  }).toList()
    ..sort((a, b) {
      final colorOrder = a.color.index.compareTo(b.color.index);
      return colorOrder != 0 ? colorOrder : a.index.compareTo(b.index);
    });
  return matching;
}

int _stackIndex(LudoPiece piece, List<LudoPiece> pieces) =>
    _piecesAtSameVisualSquare(piece, pieces).indexWhere((candidate) => candidate.id == piece.id);

Color _diceFaceColor(String style) => switch (style) {
      'gold' || 'crown' => const Color(0xFFF4C66A),
      'crystal' => const Color(0xFFB8EAEB),
      'flame' => const Color(0xFF9C4936),
      'neon' => const Color(0xFF153D4D),
      _ => const Color(0xFF354962),
    };

Color _diceInk(String style) => switch (style) {
      'gold' || 'crown' || 'crystal' => ink,
      _ => const Color(0xFFF7F4ED),
    };

Color _skinAccent(String style) => switch (style) {
      'gold' || 'crown' || 'regal' => gold,
      'crystal' => const Color(0xFF9CEBEB),
      'neon' => const Color(0xFF84F4FF),
      'flame' => const Color(0xFFFFA16B),
      'galaxy' => const Color(0xFFB7A6FF),
      'oak' || 'desert' || 'ivory' => const Color(0xFFD5B487),
      'forest' => const Color(0xFF8CE6A7),
      _ => aqua,
    };

class _LudoToken extends StatelessWidget {
  const _LudoToken({
    required this.piece,
    required this.cell,
    required this.highlighted,
    required this.onTap,
    required this.stackIndex,
    required this.stackSize,
    required this.appearanceStyle,
  });
  final LudoPiece piece;
  final double cell;
  final bool highlighted;
  final VoidCallback onTap;
  final int stackIndex;
  final int stackSize;
  final String appearanceStyle;

  @override
  Widget build(BuildContext context) {
    final point = board.LudoEngine.getTokenCoords(
      piece.color.name,
      piece.position,
      piece.index,
      stackIndex: stackIndex,
      stackSize: stackSize,
    );
    final size = cell * (stackSize == 1 ? 0.84 : 0.84 / math.sqrt(stackSize).ceil());
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
              border: Border.all(
                color: highlighted ? Colors.white : _skinAccent(appearanceStyle),
                width: highlighted ? 2.5 : appearanceStyle == 'classic' ? 1.1 : 2,
              ),
              boxShadow: [BoxShadow(color: _playerColors[piece.color]!.withOpacity(highlighted ? 0.62 : 0.27), blurRadius: highlighted ? 12 : 5, spreadRadius: highlighted ? 1 : 0)],
            ),
            child: Center(child: Text('${piece.index + 1}', style: const TextStyle(color: ink, fontSize: 9, fontWeight: FontWeight.w900))),
          ),
        ),
      ),
    );
  }
}
