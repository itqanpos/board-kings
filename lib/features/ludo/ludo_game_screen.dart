import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/local_game_journal.dart';
import 'engine/ludo_ai.dart';
import 'engine/ludo_engine.dart';
import '../game_ai_difficulty.dart';
import '../store/data/cosmetic_repository.dart';
import 'widgets/ludo_board.dart';
import 'widgets/ludo_match_controls.dart';
import 'widgets/ludo_player_card.dart';
import 'widgets/ludo_style.dart';

class LudoGameScreen extends StatefulWidget {
  const LudoGameScreen({super.key});

  @override
  State<LudoGameScreen> createState() => _LudoGameScreenState();
}

class _LudoGameScreenState extends State<LudoGameScreen> {
  LudoGameState _game = LudoGameState.initial();
  String _message = 'ارمِ النرد لبدء دور اللاعب أحمد';
  bool _aiEnabled = false;
  bool _aiBusy = false;
  bool _paused = false;
  bool _soundEnabled = true;
  GameAiDifficulty _aiDifficulty = GameAiDifficulty.medium;
  Timer? _aiTimer;
  Timer? _clockTimer;
  final Stopwatch _roundClock = Stopwatch();
  Duration _elapsed = Duration.zero;
  String _tableSkin = 'ludo_table_classic';
  String _diceSkin = 'ludo_dice_classic';
  String _piecesSkin = 'ludo_pieces_classic';

  @override
  void initState() {
    super.initState();
    _loadEquippedCosmetics();
    _roundClock.start();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _paused) return;
      setState(() => _elapsed = _roundClock.elapsed);
    });
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
    if (!_aiEnabled || _paused || _aiBusy || _game.currentTurn == LudoColor.red || _game.winner != null) return;
    _aiBusy = true;
    _aiTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      if (!_aiEnabled || _paused || _game.currentTurn == LudoColor.red || _game.winner != null) {
        _aiBusy = false;
        return;
      }

      var next = _game;
      if (next.diceValue == null) next = LudoEngine.recordRoll(next, LudoEngine.rollDice());
      if (next.diceValue == null) {
        setState(() {
          _game = next;
          _message = 'ثلاثة أرقام ٦ متتالية؛ انتقل الدور إلى ${ludoPlayerNames[next.currentTurn]}';
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
          _message = 'لا توجد حركة قانونية بالرقم $die؛ الدور التالي ${ludoPlayerNames[next.currentTurn]}';
        });
      } else {
        final aiColor = next.currentTurn;
        next = LudoEngine.applyMove(next, aiColor, pieceId, die);
        setState(() {
          _game = next;
          _message = next.winner == null
              ? 'حرّك الذكاء الاصطناعي قطعة اللاعب ${ludoPlayerNames[aiColor]}'
              : 'فاز اللاعب ${ludoPlayerNames[next.winner!]}!';
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
    _clockTimer?.cancel();
    super.dispose();
  }

  void _playClick() {
    if (_soundEnabled) SystemSound.play(SystemSoundType.click);
  }

  void _rollDice() {
    if (_game.diceValue != null || _game.winner != null || (_aiEnabled && _game.currentTurn != LudoColor.red)) return;
    _playClick();
    var next = LudoEngine.recordRoll(_game, LudoEngine.rollDice());
    if (next.diceValue == null) {
      setState(() {
        _game = next;
        _message = 'ثلاثة أرقام ٦ متتالية؛ انتقل الدور إلى ${ludoPlayerNames[next.currentTurn]}';
      });
      _scheduleAiTurn();
      return;
    }

    final rolledValue = next.diceValue!;
    next = LudoEngine.skipIfNoLegalMove(next);
    setState(() {
      _game = next;
      _message = next.diceValue == null
          ? 'لا توجد حركة قانونية بالرقم $rolledValue؛ الدور التالي ${ludoPlayerNames[next.currentTurn]}'
          : 'ظهر الرقم $rolledValue؛ اختر قطعة مضيئة للتحرك';
    });
    _scheduleAiTurn();
  }

  void _movePiece(LudoPiece piece) {
    if (_aiEnabled && _game.currentTurn != LudoColor.red) return;
    final die = _game.diceValue;
    if (die == null || !LudoEngine.isValidMove(_game, _game.currentTurn, piece.id, die)) return;
    _playClick();
    final next = LudoEngine.applyMove(_game, _game.currentTurn, piece.id, die);
    setState(() {
      _game = next;
      _message = next.winner == null
          ? (next.currentTurn == piece.color
              ? 'حركة موفقة؛ لديك دور إضافي. ارمِ النرد مجدداً.'
              : 'انتهى الدور؛ اللاعب ${ludoPlayerNames[next.currentTurn]} يلعب الآن.')
          : 'فاز اللاعب ${ludoPlayerNames[next.winner!]}!';
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
      _roundClock..reset()..start();
      _elapsed = Duration.zero;
    });
  }

  Future<void> _pauseGame() async {
    if (_game.winner != null) return;
    _aiTimer?.cancel();
    _aiBusy = false;
    _roundClock.stop();
    setState(() => _paused = true);
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ludoPanel,
        title: const Text('اللعبة متوقفة مؤقتاً', textAlign: TextAlign.center, style: TextStyle(color: ludoCream, fontWeight: FontWeight.w900)),
        content: const Text('استرح قليلاً، وستبقى جولتك محفوظة هنا.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, 'resume'), child: const Text('متابعة اللعب')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, 'restart'), child: const Text('جولة جديدة')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, 'exit'), child: const Text('إنهاء المباراة')),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _paused = false);
    if (action == 'restart') {
      _restart();
    } else if (action == 'exit') {
      context.pop();
    } else {
      _roundClock.start();
      _scheduleAiTurn();
    }
  }

  Future<void> _showQuickChat() async {
    const messages = ['حظاً موفقاً!', 'أحسنت الحركة', 'اقتربت من الفوز', 'جولة ممتعة'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: ludoPanel,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('رسالة سريعة', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ludoCream)),
            const SizedBox(height: 14),
            for (final message in messages)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: OutlinedButton(onPressed: () => Navigator.pop(sheetContext, message), child: Text(message)),
              ),
          ]),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('${ludoPlayerNames[_game.currentTurn]}: $selected'), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
  }

  Future<void> _showSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: ludoPanel,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, refreshSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('إعدادات الجولة', textAlign: TextAlign.center, style: TextStyle(color: ludoCream, fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              SwitchListTile.adaptive(
                value: _aiEnabled,
                activeColor: ludoGold,
                title: const Text('اللعب ضد الذكاء الاصطناعي'),
                subtitle: const Text('أنت اللاعب الأحمر؛ بقية الألوان يتحكم بها الحاسوب.'),
                onChanged: (enabled) {
                  setState(() {
                    _aiEnabled = enabled;
                    if (!enabled) {
                      _aiTimer?.cancel();
                      _aiBusy = false;
                    }
                  });
                  refreshSheet(() {});
                  if (enabled) _scheduleAiTurn();
                },
              ),
              if (_aiEnabled) ...[
                const SizedBox(height: 4),
                const Text('مستوى الصعوبة', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                SegmentedButton<GameAiDifficulty>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: GameAiDifficulty.easy, label: Text('سهل')),
                    ButtonSegment(value: GameAiDifficulty.medium, label: Text('متوسط')),
                    ButtonSegment(value: GameAiDifficulty.hard, label: Text('صعب')),
                  ],
                  selected: {_aiDifficulty},
                  onSelectionChanged: (selection) {
                    setState(() => _aiDifficulty = selection.first);
                    refreshSheet(() {});
                  },
                ),
              ],
              const SizedBox(height: 10),
              OutlinedButton.icon(onPressed: () { Navigator.pop(sheetContext); _openCosmetics(); }, icon: const Icon(Icons.storefront_rounded), label: const Text('المظاهر والأحجار')),
              TextButton.icon(onPressed: () { Navigator.pop(sheetContext); _restart(); }, icon: const Icon(Icons.refresh_rounded), label: const Text('بدء جولة جديدة')),
            ]),
          ),
        ),
      ),
    );
  }

  void _showPlayerInfo(LudoColor color) {
    final pieces = _game.pieces[color] ?? const <LudoPiece>[];
    final finished = pieces.where((piece) => piece.position == LudoEngine.finishPosition).length;
    final onTrack = pieces.where((piece) => piece.position >= 0 && piece.position < LudoEngine.finishPosition).length;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ludoPanel,
        title: Text(ludoPlayerNames[color]!, textAlign: TextAlign.center, style: TextStyle(color: ludoPlayerColors[color], fontWeight: FontWeight.w900)),
        content: Text('قطع في المسار: $onTrack\nقطع وصلت للنهاية: $finished من 4', textAlign: TextAlign.center, style: const TextStyle(height: 1.7)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إغلاق'))],
      ),
    );
  }

  void _showWinner(LudoColor winner) {
    unawaited(
      LocalGameJournal.recordResult(game: 'ludo', playerCount: LudoColor.values.length, winner: ludoPlayerNames[winner]!).catchError((Object _) {}),
    );
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ludoPanel,
        title: const Text('انتهت الجولة'),
        content: Text('الفائز هو ${ludoPlayerNames[winner]}.', textAlign: TextAlign.center),
        actions: [
          TextButton(onPressed: () { Navigator.pop(dialogContext); _restart(); }, child: const Text('جولة جديدة')),
          TextButton(onPressed: () { Navigator.pop(dialogContext); context.pop(); }, child: const Text('إنهاء')),
        ],
      ),
    );
  }

  String get _timerText {
    final minutes = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  int _finishedCount(LudoColor color) => _game.pieces[color]!.where((piece) => piece.position == LudoEngine.finishPosition).length;

  int _progressPoints(LudoColor color) => _game.pieces[color]!.fold<int>(
        0,
        (points, piece) => points + (piece.position < 0 ? 0 : piece.position + 1),
      );

  Widget _buildBoard(double maxWidth, double maxHeight) {
    final side = maxWidth < 1 || maxHeight < 1 ? 0.0 : maxWidth.clamp(0.0, maxHeight).clamp(0.0, 620.0).toDouble();
    return Center(
      child: SizedBox.square(
        dimension: side,
        child: LudoBoardView(
          game: _game,
          legalPieceIds: _legalPieces.map((piece) => piece.id).toSet(),
          onPieceTap: _movePiece,
          tableSkin: _tableSkin,
          piecesSkin: _piecesSkin,
        ),
      ),
    );
  }

  Widget _playerCard(LudoColor color, {bool compact = false}) => LudoPlayerCard(
        color: color,
        active: color == _game.currentTurn,
        finishedPieces: _finishedCount(color),
        points: _progressPoints(color),
        isAi: _aiEnabled && color != LudoColor.red,
        compact: compact,
        onTap: () => _showPlayerInfo(color),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: ludoInk,
        body: Stack(
          children: [
            const Positioned.fill(child: _LudoRoomBackdrop()),
            SafeArea(
              child: Column(
                children: [
                  LudoTopBar(
                    currentTurn: _game.currentTurn,
                    timer: _timerText,
                    soundEnabled: _soundEnabled,
                    onPause: _pauseGame,
                    onToggleSound: () {
                      setState(() => _soundEnabled = !_soundEnabled);
                      _playClick();
                    },
                    onChat: _showQuickChat,
                    onSettings: _showSettings,
                  ),
                  Container(
                    height: 29,
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: ludoPanel.withOpacity(0.82), borderRadius: BorderRadius.circular(14), border: Border.all(color: ludoGold.withOpacity(0.16))),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Text(_message, key: ValueKey(_message), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: ludoCream, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth > 760 && constraints.maxWidth > constraints.maxHeight * 1.18;
                        if (wide) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(14, 11, 14, 9),
                            child: Row(
                              children: [
                                SizedBox(width: 154, child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_playerCard(LudoColor.red), _playerCard(LudoColor.yellow)])),
                                const SizedBox(width: 12),
                                Expanded(child: LayoutBuilder(builder: (context, boardConstraints) => _buildBoard(boardConstraints.maxWidth, boardConstraints.maxHeight))),
                                const SizedBox(width: 12),
                                SizedBox(width: 154, child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_playerCard(LudoColor.green), _playerCard(LudoColor.blue)])),
                              ],
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(11, 9, 11, 5),
                          child: Column(
                            children: [
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 7,
                                crossAxisSpacing: 7,
                                childAspectRatio: constraints.maxWidth < 360 ? 2.25 : 2.55,
                                children: LudoColor.values.map((color) => _playerCard(color, compact: true)).toList(),
                              ),
                              const SizedBox(height: 6),
                              Expanded(child: LayoutBuilder(builder: (context, boardConstraints) => _buildBoard(boardConstraints.maxWidth, boardConstraints.maxHeight))),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                    child: Row(
                      children: [
                        LudoQuickActionButton(icon: Icons.storefront_rounded, label: 'مظاهر اللعبة', onPressed: _openCosmetics),
                        const SizedBox(width: 10),
                        Expanded(child: LudoRollButton(value: _game.diceValue, enabled: _game.diceValue == null && _game.winner == null && (!_aiEnabled || _game.currentTurn == LudoColor.red), onPressed: _rollDice, skin: _diceSkin)),
                        const SizedBox(width: 10),
                        LudoQuickActionButton(icon: Icons.info_outline_rounded, label: 'حالة الجولة', onPressed: () => _showPlayerInfo(_game.currentTurn)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _LudoRoomBackdrop extends StatelessWidget {
  const _LudoRoomBackdrop();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(0, -0.3), radius: 1.2, colors: [Color(0xFF3A281E), Color(0xFF19131A), ludoInk]),
        ),
        child: CustomPaint(painter: _BackdropGlowPainter(), child: const SizedBox.expand()),
      );
}

class _BackdropGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()..shader = RadialGradient(colors: [ludoGold.withOpacity(0.1), Colors.transparent]).createShader(Rect.fromCircle(center: Offset(size.width / 2, size.height * 0.42), radius: size.shortestSide * 0.75));
    canvas.drawRect(Offset.zero & size, glow);
    final edgePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = ludoGold.withOpacity(0.075);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(8, 8, size.width - 16, size.height - 16), const Radius.circular(20)), edgePaint);
  }

  @override
  bool shouldRepaint(covariant _BackdropGlowPainter oldDelegate) => false;
}
