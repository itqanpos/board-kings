import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/game_ui.dart';
import '../game_ai_difficulty.dart';
import '../store/data/cosmetic_repository.dart';
import 'engine/domino_ai.dart';
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
  bool _aiEnabled = false;
  bool _aiBusy = false;
  GameAiDifficulty _aiDifficulty = GameAiDifficulty.medium;
  Timer? _aiTimer;
  String _tableSkin = 'domino_table_classic';
  String _tilesSkin = 'domino_tiles_classic';

  @override
  void initState() {
    super.initState();
    _game = DominoGameState.initial(widget.playerCount, random: Random.secure());
    _message = 'اللاعب ${_game.currentTurnPlayer + 1} يبدأ بالقطعة الافتتاحية';
    _loadEquippedCosmetics();
  }

  Future<void> _openCosmetics() async {
    await context.push('/store');
    if (mounted) await _loadEquippedCosmetics();
  }

  Future<void> _loadEquippedCosmetics() async {
    try {
      final items = await CosmeticRepository.loadEquipment('domino');
      if (!mounted) return;
      setState(() {
        _tableSkin = items['table'] ?? _tableSkin;
        _tilesSkin = items['tiles'] ?? _tilesSkin;
      });
    } catch (_) {}
  }

  int get _player => _game.currentTurnPlayer;
  bool get _isAiTurn => _aiEnabled && _player != 0;
  List<DominoTile> get _activeHand =>
      _isAiTurn ? const [] : _game.playerHands[_player] ?? const [];
  bool get _hasMove => DominoEngine.hasAnyValidMove(_game, _player);
  bool get _canDraw => !_isAiTurn && !_hasMove && _game.drawPile.isNotEmpty && _game.winner == null;
  bool get _canPass => !_isAiTurn && !_hasMove && _game.drawPile.isEmpty && _game.winner == null;

  void _scheduleAiTurn() {
    if (!_isAiTurn || _aiBusy || _game.winner != null) return;
    _aiBusy = true;
    _aiTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      if (!_isAiTurn || _game.winner != null) {
        _aiBusy = false;
        return;
      }

      final player = _player;
      var next = _game;
      while (!DominoEngine.hasAnyValidMove(next, player) &&
          next.drawPile.isNotEmpty) {
        final drawn = DominoEngine.drawTile(next, player);
        if (identical(drawn, next)) break;
        next = drawn;
      }

      if (DominoEngine.hasAnyValidMove(next, player)) {
        final move = DominoAi.chooseMove(next, difficulty: _aiDifficulty);
        if (move != null) {
          final tile = next.playerHands[player]!
              .firstWhere((candidate) => candidate.id == move.tileId);
          next = DominoEngine.playTile(next, player, tile, move.playOnLeft);
        }
      } else if (next.drawPile.isEmpty) {
        next = DominoEngine.passTurn(next, player, widget.playerCount);
      }

      setState(() {
        _game = next;
        _selectedTile = null;
        _message = next.winner == null
            ? 'انتهى دور الذكاء الاصطناعي؛ الآن اللاعب ${next.currentTurnPlayer + 1}'
            : 'انتهت الجولة؛ الفائز اللاعب ${next.winner! + 1}';
      });
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

  bool _isPlayable(DominoTile tile) {
    if (_isAiTurn || _game.winner != null) return false;
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
    if (_isAiTurn) return;
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
    _scheduleAiTurn();
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
    _scheduleAiTurn();
  }

  void _restart() {
    _aiTimer?.cancel();
    _aiBusy = false;
    setState(() {
      _game = DominoGameState.initial(widget.playerCount, random: Random.secure());
      _selectedTile = null;
      _message = 'اللاعب ${_game.currentTurnPlayer + 1} يبدأ بالقطعة الافتتاحية';
    });
    _scheduleAiTurn();
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
                    decoration: BoxDecoration(
                      color: _tableFill(_tableSkin),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _skinAccent(_tableSkin.replaceFirst('domino_table_', '')).withOpacity(0.65), width: 2),
                    ),
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
                                  ..._game.board.map((tile) => DominoTileFace(tile: tile, compact: true, styleId: _tilesSkin.replaceFirst('domino_tiles_', ''))),
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
                  child: Text(
                    _isAiTurn
                        ? 'الذكاء الاصطناعي يفكر...'
                        : 'يد اللاعب ${_player + 1}  •  ${_activeHand.length} قطع',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
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
                        styleId: _tilesSkin.replaceFirst('domino_tiles_', ''),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _isAiTurn
                      ? 'دور الذكاء الاصطناعي'
                      : _hasMove
                          ? 'اختر قطعة مضاءة للعب'
                          : _game.drawPile.isNotEmpty
                              ? 'لا توجد حركة؛ اسحب قطعة'
                              : 'لا توجد حركة ولا قطع للسحب؛ مرّر الدور',
                  style: const TextStyle(color: mutedText, fontSize: 11),
                ),
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
  const DominoTileFace({super.key, required this.tile, this.enabled = true, this.selected = false, this.compact = false, this.onTap, this.styleId = 'classic'});
  final DominoTile tile;
  final bool enabled;
  final bool selected;
  final bool compact;
  final VoidCallback? onTap;
  final String styleId;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 52.0 : 62.0;
    final height = compact ? 72.0 : 88.0;
    final darkFace = styleId == 'obsidian' || styleId == 'neon';
    final faceColor = selected ? const Color(0xFF33455B) : _tileFaceColor(styleId);
    final numberColor = darkFace || selected ? const Color(0xFFF5F0E8) : ink;
    final strokeColor = selected ? coral : _skinAccent(styleId);
    return Semantics(
      button: onTap != null,
      label: 'قطعة دومينو ${tile.left} إلى ${tile.right}${enabled ? '، قابلة للعب' : ''}',
      child: Opacity(
        opacity: enabled ? 1 : 0.42,
        child: Material(
          color: faceColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: width,
              height: height,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: strokeColor, width: selected ? 2 : 1.5)),
              child: Column(
                children: [
                  Expanded(child: Center(child: Text('${tile.left}', style: TextStyle(color: numberColor, fontSize: compact ? 16 : 20, fontWeight: FontWeight.w900)))),
                  Container(height: 1, color: const Color(0xFFBDB5A5)),
                  Expanded(child: Center(child: Text('${tile.right}', style: TextStyle(color: numberColor, fontSize: compact ? 16 : 20, fontWeight: FontWeight.w900)))),
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

Color _tableFill(String id) => switch (id) {
      'domino_table_oak' => const Color(0xFF403126),
      'domino_table_marble' => const Color(0xFF1C2734),
      'domino_table_royal' => const Color(0xFF382A2B),
      'domino_table_desert' => const Color(0xFF594636),
      'domino_table_winter' => const Color(0xFF213949),
      _ => const Color(0xFF152B2C),
    };

Color _tileFaceColor(String style) => switch (style) {
      'oak' => const Color(0xFFD8BC92),
      'ivory' => const Color(0xFFF6EAD0),
      'gold' => const Color(0xFFE5C16B),
      'obsidian' => const Color(0xFF202936),
      'neon' => const Color(0xFF274750),
      _ => const Color(0xFFF2EEE3),
    };

class _EndMarker extends StatelessWidget {
  const _EndMarker({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: RotatedBox(quarterTurns: 3, child: Text(label, style: const TextStyle(color: aqua, fontSize: 9, fontWeight: FontWeight.w800))),
      );
}
