import 'package:board_kings/features/domino/engine/domino_ai.dart';
import 'package:board_kings/features/domino/engine/domino_engine.dart';
import 'package:board_kings/features/game_ai_difficulty.dart';
import 'package:board_kings/features/ludo/engine/ludo_ai.dart';
import 'package:board_kings/features/ludo/engine/ludo_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Ludo AI', () {
    test('returns a legal move and null when no move exists', () {
      final game = LudoEngine.recordRoll(LudoGameState.initial(), 6);
      final selected = LudoAi.choosePiece(
        game,
        difficulty: GameAiDifficulty.hard,
      );
      expect(selected, isNotNull);
      expect(
        LudoEngine.isValidMove(game, game.currentTurn, selected!, 6),
        isTrue,
      );

      final noMove = LudoEngine.recordRoll(LudoGameState.initial(), 2);
      expect(LudoAi.choosePiece(noMove), isNull);
    });

    test('prioritizes a winning finish over an ordinary piece move', () {
      final game = LudoGameState(
        pieces: {
          for (final color in LudoColor.values)
            color: List.generate(
              4,
              (index) => LudoPiece(
                id: '${color.name}_$index',
                color: color,
                index: index,
                position: color == LudoColor.red
                    ? (index == 0 ? 57 : 58)
                    : -1,
              ),
            ),
        },
        currentTurn: LudoColor.red,
        diceValue: 1,
      );
      expect(
        LudoAi.choosePiece(game, difficulty: GameAiDifficulty.hard),
        'red_0',
      );
    });
  });

  group('Domino AI', () {
    test('obeys opening tile restrictions and returns legal placements', () {
      const opening = DominoTile(id: 1, left: 6, right: 6);
      const other = DominoTile(id: 2, left: 1, right: 4);
      final game = DominoGameState(
        board: const [],
        playerHands: {
          0: [opening, other],
          1: const [DominoTile(id: 3, left: 0, right: 0)],
        },
        currentTurnPlayer: 0,
        openingTileId: opening.id,
      );

      final move = DominoAi.chooseMove(
        game,
        difficulty: GameAiDifficulty.hard,
      );
      expect(move?.tileId, opening.id);
      final selectedMove = move!;
      final next = DominoEngine.playTile(
        game,
        game.currentTurnPlayer,
        game.playerHands[0]!.firstWhere((tile) => tile.id == selectedMove.tileId),
        selectedMove.playOnLeft,
      );
      expect(identical(next, game), isFalse);
    });

    test('returns null when the active player cannot play', () {
      final game = DominoGameState(
        board: const [DominoTile(id: 10, left: 2, right: 5)],
        playerHands: {
          0: const [DominoTile(id: 1, left: 0, right: 0)],
          1: const [DominoTile(id: 2, left: 3, right: 3)],
        },
        currentTurnPlayer: 0,
        leftEnd: 2,
        rightEnd: 5,
      );
      expect(DominoAi.chooseMove(game), isNull);
    });
  });
}
