import 'dart:async';
import 'dart:math';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/local_game_journal.dart';
import '../../shared/widgets/game_ui.dart';
import '../game_ai_difficulty.dart';
import '../store/data/cosmetic_repository.dart';
import 'engine/domino_ai.dart';
import 'engine/domino_engine.dart';

const List<Color> _seatColors = [
  aqua,
  coral,
  gold,
  Color(0xFF9B8BFF),
];

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
  Timer? _turnTimer;
  final List<DominoGameState> _history = [];
  int _remainingSeconds = 30;
  int _clockPlayer = -1;
  bool _soundEnabled = true;
  String _tableSkin = 'domino_table_classic';
  String _tilesSkin = 'domino_tiles_classic';

  @override
  void initState() {
    super.initState();
    _game = DominoGameState.initial(widget.playerCount, random: Random.secure());
    _message = 'اللاعب ${_game.currentTurnPlayer + 1} يبدأ بالقطعة الافتتاحية';
    _startTurnClock();
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
  String get _turnHint {
    if (_isAiTurn) return 'دور الذكاء الاصطناعي';
    if (_selectedTile != null) return 'اختر الطرف الذي تريد وضع القطعة عنده';
    if (_hasMove) return 'اختر قطعة مضاءة للعب';
    if (_game.drawPile.isNotEmpty) return 'لا توجد حركة؛ اسحب قطعة';
    return 'لا توجد حركة ولا قطع للسحب؛ مرّر الدور';
  }

  void _startTurnClock() {
    _turnTimer?.cancel();
    _clockPlayer = _player;
    _remainingSeconds = 30;
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _game.winner != null) return;
      if (_clockPlayer != _player) {
        setState(() {
          _clockPlayer = _player;
          _remainingSeconds = 30;
        });
      } else if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _rememberGame() {
    _history.add(_game);
    if (_history.length > 60) _history.removeAt(0);
  }

  void _playClick() {
    if (_soundEnabled) unawaited(SystemSound.play(SystemSoundType.click));
  }

  void _undo() {
    if (_history.isEmpty) return;
    _aiTimer?.cancel();
    _aiBusy = false;
    setState(() {
      _game = _history.removeLast();
      _selectedTile = null;
      _message = 'تم التراجع عن الحركة الأخيرة';
    });
    _playClick();
    _scheduleAiTurn();
  }

  Future<void> _openQuickChat() async {
    const messages = [
      'حركة جميلة!',
      'حظاً موفقاً',
      'دوري الآن',
      'لنلعب جولة أخرى',
    ];
    final message = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: panel,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('الدردشة السريعة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              for (final text in messages)
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline_rounded, color: aqua),
                  title: Text(text),
                  onTap: () => Navigator.pop(sheetContext, text),
                ),
            ],
          ),
        ),
      ),
    );
    if (message != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('رسالة سريعة: $message'), duration: const Duration(seconds: 2)),
      );
    }
  }

  Future<void> _openSettings() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refreshDialog) => AlertDialog(
          backgroundColor: panel,
          title: const Text('إعدادات المباراة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('الأصوات'),
                value: _soundEnabled,
                onChanged: (value) {
                  setState(() => _soundEnabled = value);
                  refreshDialog(() {});
                  _playClick();
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('اللاعبون الآليون'),
                value: _aiEnabled,
                onChanged: (value) {
                  setState(() => _aiEnabled = value);
                  refreshDialog(() {});
                  if (value) {
                    _scheduleAiTurn();
                  } else {
                    _aiTimer?.cancel();
                    _aiBusy = false;
                  }
                },
              ),
              if (_aiEnabled)
                DropdownButtonFormField<GameAiDifficulty>(
                  value: _aiDifficulty,
                  decoration: const InputDecoration(labelText: 'مستوى الذكاء الاصطناعي'),
                  items: const [
                    DropdownMenuItem(value: GameAiDifficulty.easy, child: Text('سهل')),
                    DropdownMenuItem(value: GameAiDifficulty.medium, child: Text('متوسط')),
                    DropdownMenuItem(value: GameAiDifficulty.hard, child: Text('صعب')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _aiDifficulty = value);
                    refreshDialog(() {});
                  },
                ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('تم'))],
        ),
      ),
    );
  }

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

      if (!identical(next, _game)) _rememberGame();
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
    _turnTimer?.cancel();
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
    _rememberGame();
    _playClick();
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
    _rememberGame();
    _playClick();
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
    _rememberGame();
    _playClick();
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
    _history.clear();
    setState(() {
      _game = DominoGameState.initial(widget.playerCount, random: Random.secure());
      _selectedTile = null;
      _clockPlayer = _game.currentTurnPlayer;
      _remainingSeconds = 30;
      _message = 'اللاعب ${_game.currentTurnPlayer + 1} يبدأ بالقطعة الافتتاحية';
    });
    _scheduleAiTurn();
  }

  void _showWinner(int winner) {
    unawaited(
      LocalGameJournal.recordResult(
        game: 'domino',
        playerCount: widget.playerCount,
        winner: 'اللاعب ${winner + 1}',
      ).catchError((Object _) {}),
    );
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

  void _onMenuSelection(String value) {
    switch (value) {
      case 'undo':
        _undo();
        break;
      case 'chat':
        unawaited(_openQuickChat());
        break;
      case 'sound':
        setState(() => _soundEnabled = !_soundEnabled);
        _playClick();
        break;
      case 'settings':
        unawaited(_openSettings());
        break;
      case 'cosmetics':
        unawaited(_openCosmetics());
        break;
      case 'restart':
        _restart();
        break;
      case 'off':
      case 'easy':
      case 'medium':
      case 'hard':
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
        break;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('الدومينو'),
          leading: IconButton(tooltip: 'إنهاء المباراة', onPressed: () => context.pop(), icon: const Icon(Icons.arrow_forward_rounded)),
          actions: MediaQuery.sizeOf(context).width < 620
              ? [
                  PopupMenuButton<String>(
                    tooltip: 'أدوات المباراة',
                    onSelected: _onMenuSelection,
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'undo', enabled: _history.isNotEmpty, child: const Text('تراجع عن الحركة')),
                      const PopupMenuItem(value: 'chat', child: Text('الدردشة السريعة')),
                      PopupMenuItem(value: 'sound', child: Text(_soundEnabled ? 'كتم الصوت' : 'تشغيل الصوت')),
                      const PopupMenuItem(value: 'settings', child: Text('إعدادات المباراة')),
                      const PopupMenuItem(value: 'cosmetics', child: Text('المظاهر')),
                      const PopupMenuItem(value: 'easy', child: Text('ذكاء اصطناعي سهل')),
                      const PopupMenuItem(value: 'medium', child: Text('ذكاء اصطناعي متوسط')),
                      const PopupMenuItem(value: 'hard', child: Text('ذكاء اصطناعي صعب')),
                      const PopupMenuItem(value: 'off', child: Text('إيقاف الذكاء الاصطناعي')),
                      const PopupMenuItem(value: 'restart', child: Text('إعادة المباراة')),
                    ],
                  ),
                ]
              : [
                  IconButton(tooltip: 'تراجع', onPressed: _history.isEmpty ? null : _undo, icon: const Icon(Icons.undo_rounded)),
                  IconButton(tooltip: 'الدردشة السريعة', onPressed: _openQuickChat, icon: const Icon(Icons.chat_bubble_outline_rounded)),
                  IconButton(tooltip: _soundEnabled ? 'كتم الصوت' : 'تشغيل الصوت', onPressed: () { setState(() => _soundEnabled = !_soundEnabled); _playClick(); }, icon: Icon(_soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded)),
                  IconButton(tooltip: 'إعدادات المباراة', onPressed: _openSettings, icon: const Icon(Icons.settings_rounded)),
                  IconButton(tooltip: 'المظاهر', onPressed: _openCosmetics, icon: const Icon(Icons.storefront_rounded)),
                  PopupMenuButton<String>(
                    tooltip: 'مستوى الذكاء الاصطناعي',
                    onSelected: _onMenuSelection,
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final shortScreen = constraints.maxHeight < 610;
              final content = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                _TurnSummary(player: _player, message: _message, stock: _game.drawPile.length, seconds: _remainingSeconds),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(widget.playerCount, (index) {
                    final hand = _game.playerHands[index] ?? const <DominoTile>[];
                    final pips = hand.fold<int>(0, (sum, tile) => sum + tile.totalValue);
                    final accent = _seatColors[index % _seatColors.length];
                    final active = index == _player;
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
                        decoration: BoxDecoration(
                          gradient: active ? LinearGradient(colors: [accent.withOpacity(0.2), panel]) : null,
                          color: active ? null : panel,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: active ? accent.withOpacity(0.8) : Colors.white.withOpacity(0.05), width: active ? 1.3 : 1),
                          boxShadow: active ? [BoxShadow(color: accent.withOpacity(0.1), blurRadius: 12)] : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(width: 7, height: 7, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                Flexible(child: Text('لاعب ${index + 1}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: active ? accent : Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text('${hand.length} قطع • $pips نقطة', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: mutedText, fontSize: 9.5)),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: shortScreen ? 190 : (constraints.maxHeight * 0.42).clamp(255.0, 410.0).toDouble(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF9B7045), Color(0xFF3D291B), Color(0xFF785331)],
                      ),
                      borderRadius: BorderRadius.circular(23),
                      border: Border.all(color: gold, width: 1.5),
                      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 18, offset: Offset(0, 8))],
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            _tableFill(_tableSkin),
                            Color.lerp(_tableFill(_tableSkin), ink, 0.3)!,
                            _tableFill(_tableSkin),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _skinAccent(_tableSkin.replaceFirst('domino_table_', '')).withOpacity(0.72)),
                      ),
                        child: _game.board.isEmpty
                          ? _DominoDropTarget(
                              canAccept: _isPlayable,
                              onAccept: (tile) => _placeTile(tile, false),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 62,
                                    height: 62,
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.1))),
                                    child: const Icon(Icons.extension_rounded, color: Colors.white70, size: 29),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text('الطاولة جاهزة', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                                  const SizedBox(height: 5),
                                  const Text('اسحب القطعة الافتتاحية إلى الطاولة', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            reverse: false,
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _DominoDropTarget(
                                    canAccept: (tile) => _isPlayable(tile) && _fitsLeft(tile),
                                    onAccept: (tile) => _placeTile(tile, true),
                                    child: _EndMarker(label: 'طرف ${_game.leftEnd}'),
                                  ),
                                  ..._game.board.map((tile) => TweenAnimationBuilder<double>(
                                        key: ValueKey('${tile.id}-${tile.left}-${tile.right}'),
                                        tween: Tween(begin: 0.65, end: 1),
                                        duration: const Duration(milliseconds: 280),
                                        curve: Curves.easeOutBack,
                                        builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                                        child: DominoTileFace(tile: tile, compact: true, styleId: _tilesSkin.replaceFirst('domino_tiles_', '')),
                                      )),
                                  _DominoDropTarget(
                                    canAccept: (tile) => _isPlayable(tile) && _fitsRight(tile),
                                    onAccept: (tile) => _placeTile(tile, false),
                                    child: _EndMarker(label: 'طرف ${_game.rightEnd}'),
                                  ),
                                ],
                              ),
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
                      final playable = _isPlayable(tile);
                      final face = DominoTileFace(
                        tile: tile,
                        selected: _selectedTile?.id == tile.id,
                        enabled: playable,
                        onTap: playable ? () => _selectTile(tile) : null,
                        styleId: _tilesSkin.replaceFirst('domino_tiles_', ''),
                      );
                      if (!playable) return face;
                      return Draggable<DominoTile>(
                        data: tile,
                        feedback: Material(
                          type: MaterialType.transparency,
                          child: DominoTileFace(tile: tile, selected: true, styleId: _tilesSkin.replaceFirst('domino_tiles_', '')),
                        ),
                        childWhenDragging: Opacity(opacity: 0.28, child: face),
                        child: face,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _turnHint,
                  style: const TextStyle(color: mutedText, fontSize: 11),
                ),
              ],
              );
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 3, 14, 18),
                    child: SingleChildScrollView(child: content),
                  ),
                ),
              );
            },
          ),
        ),
      );
}

class _DominoDropTarget extends StatelessWidget {
  const _DominoDropTarget({
    required this.canAccept,
    required this.onAccept,
    required this.child,
  });

  final bool Function(DominoTile tile) canAccept;
  final ValueChanged<DominoTile> onAccept;
  final Widget child;

  @override
  Widget build(BuildContext context) => DragTarget<DominoTile>(
        onWillAcceptWithDetails: (details) => canAccept(details.data),
        onAcceptWithDetails: (details) => onAccept(details.data),
        builder: (context, candidates, rejected) {
          final hovering = candidates.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            decoration: BoxDecoration(
              color: hovering ? gold.withOpacity(0.22) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hovering ? gold : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: child,
          );
        },
      );
}

class _TurnSummary extends StatelessWidget {
  const _TurnSummary({required this.player, required this.message, required this.stock, required this.seconds});
  final int player;
  final String message;
  final int stock;
  final int seconds;

  @override
  Widget build(BuildContext context) {
    final accent = _seatColors[player % _seatColors.length];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.centerRight, end: Alignment.centerLeft, colors: [accent.withOpacity(0.2), panel]),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: accent.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: accent.withOpacity(0.17), shape: BoxShape.circle, border: Border.all(color: accent.withOpacity(0.6))),
            child: Icon(Icons.person_rounded, color: accent, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('دور اللاعب ${player + 1}', style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 7),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: accent.withOpacity(0.14), borderRadius: BorderRadius.circular(20)), child: Text('يلعب الآن', style: TextStyle(color: accent, fontSize: 9, fontWeight: FontWeight.w800))),
                  ],
                ),
                const SizedBox(height: 3),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                  child: Text(message, key: ValueKey(message), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: mutedText)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: seconds <= 10 ? coral.withOpacity(0.16) : panelRaised,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: seconds <= 10 ? coral.withOpacity(0.65) : Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_bottom_rounded, color: seconds <= 10 ? coral : gold, size: 14),
                    const SizedBox(width: 4),
                    Text('0:${seconds.toString().padLeft(2, '0')}', style: TextStyle(color: seconds <= 10 ? coral : Colors.white, fontSize: 11, fontWeight: FontWeight.w900, fontFeatures: const [FontFeature.tabularFigures()])),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(color: panelRaised, borderRadius: BorderRadius.circular(12)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.inventory_2_outlined, color: aqua, size: 14), const SizedBox(height: 2), Text('$stock', style: const TextStyle(color: aqua, fontSize: 10, fontWeight: FontWeight.w900))]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DominoTileFace extends StatelessWidget {
  const DominoTileFace({
    super.key,
    required this.tile,
    this.enabled = true,
    this.selected = false,
    this.compact = false,
    this.onTap,
    this.styleId = 'classic',
  });

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
      child: AnimatedScale(
        scale: selected ? 1.04 : 1,
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOutBack,
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [faceColor, Color.lerp(faceColor, ink, darkFace ? 0.1 : 0.06)!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: strokeColor, width: selected ? 2 : 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 7, offset: const Offset(0, 3)),
                    if (selected) BoxShadow(color: coral.withOpacity(0.28), blurRadius: 14),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: _DominoPipFace(value: tile.left, color: numberColor, dotSize: compact ? 4 : 6),
                      ),
                    ),
                    Container(height: 1, color: const Color(0xFFBDB5A5)),
                    Expanded(
                      child: Center(
                        child: _DominoPipFace(value: tile.right, color: numberColor, dotSize: compact ? 4 : 6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DominoPipFace extends StatelessWidget {
  const _DominoPipFace({required this.value, required this.color, required this.dotSize});

  static const Map<int, Set<int>> _pipPositions = {
    0: <int>{},
    1: <int>{4},
    2: <int>{0, 8},
    3: <int>{0, 4, 8},
    4: <int>{0, 2, 6, 8},
    5: <int>{0, 2, 4, 6, 8},
    6: <int>{0, 2, 3, 5, 6, 8},
  };

  final int value;
  final Color color;
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    final positions = _pipPositions[value] ?? const <int>{};
    return SizedBox(
      width: dotSize * 4.5,
      height: dotSize * 4.5,
      child: Column(
        children: List.generate(3, (row) => Expanded(
          child: Row(
            children: List.generate(3, (column) {
              final visible = positions.contains(row * 3 + column);
              return Expanded(
                child: Center(
                  child: visible
                      ? Container(
                          width: dotSize,
                          height: dotSize,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color.lerp(color, Colors.white, 0.34)!, color, Color.lerp(color, Colors.black, 0.32)!],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 1.5, offset: const Offset(0, 1))],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              );
            }),
          ),
        )),
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
