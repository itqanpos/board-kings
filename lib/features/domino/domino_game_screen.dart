import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/game_ui.dart';
import 'engine/domino_engine.dart';

class DominoGameScreen extends StatefulWidget {
  const DominoGameScreen({super.key, required this.playerCount});

  final int playerCount;

  @override
  State<DominoGameScreen> createState() => _DominoGameScreenState();
}

class _DominoGameScreenState extends State<DominoGameScreen> {
  late DominoGameState _game;
  DominoTile? _selectedTile;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _game = DominoGameState.initial(widget.playerCount, random: Random.secure());
    _message = 'اللاعب ${_game.currentTurnPlayer + 1} يبدأ بالقطعة الافتتاحية';
  }

  int get _player => _game.currentTurnPlayer;
  List<DominoTile> get _activeHand => _game.playerHands[_player] ?? const [];
  bool get _hasMove => DominoEngine.hasAnyValidMove(_game, _player);
  bool get _canDraw => !_hasMove && _game.drawPile.isNotEmpty && _game.winner == null;
  bool get _canPass => !_hasMove && _game.drawPile.isEmpty && _game.winner == null;

  bool _isPlayable(DominoTile tile) {
    if (_game.board.isEmpty) return _game.openingTileId == tile.id;
    return DominoEngine.canPlayTile(_game, tile);
  }

  bool _fitsLeft(DominoTile tile) => _game.board.isEmpty || tile.left == _game.leftEnd || tile.right == _game.leftEnd;
  bool _fitsRight(DominoTile tile) => _game.board.isEmpty || tile.left == _game.rightEnd || tile.right == _game.rightEnd;

  void _selectTile(DominoTile tile) {
    if (!_isPlayable(tile) || _game.winner != null) return;
    final left = _fitsLeft(tile);
    final right = _fitsRight(tile);
    if (left && right && _game.board.isNotEmpty) {
      setState(() => _selectedTile = tile);
      return;
    }
    _placeTile(tile, left);
  }

  void _placeTile(DominoTile tile, bool onLeft) {
    final next = DominoEngine.playTile(_game, _player, tile, onLeft);
    if (identical(next, _game)) return;
    setState(() {
      _game = next;
      _selectedTile = null;
      _message = next.winner == null
          ? 'الدور الآن للاعب ${next.currentTurnPlayer + 1}'
          : 'انتهت الجولة؛ الفائز اللاعب ${next.winner! + 1}';
    });
    if (next.winner != null) _showWinner(next.winner!);
  }

  void _draw() {
    final next = DominoEngine.drawTile(_game, _player);
    if (identical(next, _game)) return;
    setState(() {
      _game = next;
      _message = DominoEngine.hasAnyValidMove(next, _player)
          ? 'وجدت حركة قانونية؛ اختر قطعة للعب'
          : next.drawPile.isEmpty
              ? 'لا توجد قطع أخرى للسحب؛ يمكنك تمرير الدور'
              : 'سُحبت قطعة؛ يمكنك السحب مجدداً أو التمرير إذا انتهى المخزون';
    });
  }

  void _pass() {
    final next = DominoEngine.passTurn(_game, _player, widget.playerCount);
    if (identical(next, _game)) return;
    setState(() {
      _game = next;
      _message = next.winner == null
          ? 'مرّر اللاعب دوره؛ الآن اللاعب ${next.currentTurnPlayer + 1}'
          : 'انتهت الجولة؛ الأقل نقاطاً هو اللاعب ${next.winner! + 1}';
    });
    if (next.winner != null) _showWinner(next.winner!);
  }

  void _restart() {
    setState(() {
      _game = DominoGameState.initial(widget.playerCount, random: Random.secure());
      _selectedTile = null;
      _message = 'اللاعب ${_game.currentTurnPlayer + 1} يبدأ بالقطعة الافتتاحية';
    });
  }

  void _showWinner(int winner) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: panel,
        title: const Text('انتهت الجولة'),
        content: Text('الفائز هو اللاعب ${winner + 1}.', textAlign: TextAlign.center),
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
          title: const Text('الدومينو'),
          leading: IconButton(tooltip: 'إنهاء المباراة', onPressed: () => context.pop(), icon: const Icon(Icons.arrow_forward_rounded)),
          actions: [IconButton(tooltip: 'إعادة المباراة', onPressed: _restart, icon: const Icon(Icons.refresh_rounded))],
        ),
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 3, 14, 12),
            child: Column(
              children: [
                _TurnSummary(player: _player, message: _message, stock: _game.drawPile.length),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(widget.playerCount, (index) {
                    final hand = _game.playerHands[index] ?? const <DominoTile>[];
                    final pips = hand.fold<int>(0, (sum, tile) => sum + tile.totalValue);
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        decoration: BoxDecoration(color: index == _player ? aqua.withOpacity(0.14) : panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: index == _player ? aqua : Colors.transparent)),
                        child: Column(children: [Text('لاعب ${index + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text('${hand.length} قطع • $pips نقطة', style: const TextStyle(color: mutedText, fontSize: 9))]),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                Expanded(
                  flex: 5,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(color: const Color(0xFF152B2C), borderRadius: BorderRadius.circular(20), border: Border.all(color: aqua.withOpacity(0.18))),
                    child: _game.board.isEmpty
                        ? const Center(child: Text('ضع القطعة الافتتاحية هنا', style: TextStyle(color: mutedText)))
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            reverse: false,
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _EndMarker(label: 'طرف ${_game.leftEnd}'),
                                  ..._game.board.map((tile) => DominoTileFace(tile: tile, compact: true)),
                                  _EndMarker(label: 'طرف ${_game.rightEnd}'),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_selectedTile != null) _PlacementPicker(tile: _selectedTile!, leftEnd: _game.leftEnd!, rightEnd: _game.rightEnd!, onLeft: () => _placeTile(_selectedTile!, true), onRight: () => _placeTile(_selectedTile!, false)),
                if (_selectedTile != null) const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: OutlinedButton.icon(onPressed: _canDraw ? _draw : null, icon: const Icon(Icons.add_box_outlined), label: Text('اسحب (${_game.drawPile.length})'))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton.icon(onPressed: _canPass ? _pass : null, icon: const Icon(Icons.skip_next_rounded), label: const Text('مرّر الدور'))),
                  ],
                ),
                const SizedBox(height: 9),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('يد اللاعب ${_player + 1}  •  ${_activeHand.length} قطع', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 98,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _activeHand.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 7),
                    itemBuilder: (context, index) {
                      final tile = _activeHand[index];
                      return DominoTileFace(
                        tile: tile,
                        selected: _selectedTile?.id == tile.id,
                        enabled: _isPlayable(tile),
                        onTap: _isPlayable(tile) ? () => _selectTile(tile) : null,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 5),
                Text(_hasMove ? 'اختر قطعة مضاءة للعب' : _game.drawPile.isNotEmpty ? 'لا توجد حركة؛ اسحب قطعة' : 'لا توجد حركة ولا قطع للسحب؛ مرّر الدور', style: const TextStyle(color: mutedText, fontSize: 11)),
              ],
            ),
          ),
        ),
      );
}

class _TurnSummary extends StatelessWidget {
  const _TurnSummary({required this.player, required this.message, required this.stock});
  final int player;
  final String message;
  final int stock;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            const Icon(Icons.person_pin_circle_outlined, color: aqua),
            const SizedBox(width: 8),
            Expanded(child: Text('الدور للاعب ${player + 1}  •  $message', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: mutedText))),
            const SizedBox(width: 6),
            Text('المخزون $stock', style: const TextStyle(fontSize: 10, color: aqua, fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

class DominoTileFace extends StatelessWidget {
  const DominoTileFace({super.key, required this.tile, this.enabled = true, this.selected = false, this.compact = false, this.onTap});
  final DominoTile tile;
  final bool enabled;
  final bool selected;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 52.0 : 62.0;
    final height = compact ? 72.0 : 88.0;
    return Semantics(
      button: onTap != null,
      label: 'قطعة دومينو ${tile.left} إلى ${tile.right}${enabled ? '، قابلة للعب' : ''}',
      child: Opacity(
        opacity: enabled ? 1 : 0.42,
        child: Material(
          color: selected ? const Color(0xFF33455B) : const Color(0xFFF2EEE3),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: width,
              height: height,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? coral : const Color(0xFFC9C2B2), width: selected ? 2 : 1)),
              child: Column(
                children: [
                  Expanded(child: Center(child: Text('${tile.left}', style: TextStyle(color: ink, fontSize: compact ? 16 : 20, fontWeight: FontWeight.w900)))),
                  Container(height: 1, color: const Color(0xFFBDB5A5)),
                  Expanded(child: Center(child: Text('${tile.right}', style: TextStyle(color: ink, fontSize: compact ? 16 : 20, fontWeight: FontWeight.w900)))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlacementPicker extends StatelessWidget {
  const _PlacementPicker({required this.tile, required this.leftEnd, required this.rightEnd, required this.onLeft, required this.onRight});
  final DominoTile tile;
  final int leftEnd;
  final int rightEnd;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: OutlinedButton(onPressed: onLeft, child: Text('ضع ${tile.left}–${tile.right} بجانب $leftEnd'))),
          const SizedBox(width: 7),
          Expanded(child: OutlinedButton(onPressed: onRight, child: Text('ضع ${tile.left}–${tile.right} بجانب $rightEnd'))),
        ],
      );
}

class _EndMarker extends StatelessWidget {
  const _EndMarker({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: RotatedBox(quarterTurns: 3, child: Text(label, style: const TextStyle(color: aqua, fontSize: 9, fontWeight: FontWeight.w800))),
      );
}
