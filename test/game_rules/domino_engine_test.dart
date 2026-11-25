import 'dart:math';

import 'package:board_kings/features/domino/engine/domino_engine.dart';
import 'package:flutter_test/flutter_test.dart';

DominoTile tile(int id, int left, int right) =>
    DominoTile(id: id, left: left, right: right);

DominoGameState stateWith({
  required List<DominoTile> board,
  required Map<int, List<DominoTile>> hands,
  required int currentPlayer,
  List<DominoTile> drawPile = const [],
  int? leftEnd,
  int? rightEnd,
  int consecutivePasses = 0,
  int? winner,
}) {
  return DominoGameState(
    board: board,
    playerHands: hands,
    currentTurnPlayer: currentPlayer,
    drawPile: drawPile,
    leftEnd: leftEnd,
    rightEnd: rightEnd,
    consecutivePasses: consecutivePasses,
    winner: winner,
  );
}

void main() {
  group('Domino initial deal', () {
    test('distributes every double-six tile exactly once for 2 to 4 players', () {
      for (final playerCount in [2, 3, 4]) {
        final game = DominoGameState.initial(playerCount, random: Random(42));
        final dealtTiles = [
          ...game.playerHands.values.expand((hand) => hand),
          ...game.drawPile,
        ];
        final expectedHandSize = playerCount == 2 ? 7 : 5;

        expect(game.playerHands, hasLength(playerCount));
        expect(game.playerHands.values.every((hand) => hand.length == expectedHandSize), isTrue);
        expect(dealtTiles, hasLength(28));
        expect(dealtTiles.map((piece) => piece.id).toSet(), hasLength(28));
        expect(game.drawPile, hasLength(28 - playerCount * expectedHandSize));
        expect(game.currentTurnPlayer, inInclusiveRange(0, playerCount - 1));
        expect(game.openingTileId, isNotNull);
        expect(
          game.playerHands[game.currentTurnPlayer]!.any((piece) => piece.id == game.openingTileId),
          isTrue,
        );
      }
    });

    test('allows only the selected opening tile to start an initialized game', () {
      final game = DominoGameState.initial(2, random: Random(7));
      final starterHand = game.playerHands[game.currentTurnPlayer]!;
      final openingTile = starterHand.firstWhere((piece) => piece.id == game.openingTileId);
      final otherTile = starterHand.firstWhere((piece) => piece.id != game.openingTileId);

      expect(DominoEngine.hasAnyValidMove(game, game.currentTurnPlayer), isTrue);
      expect(DominoEngine.hasAnyValidMove(game, (game.currentTurnPlayer + 1) % 2), isFalse);
      expect(DominoEngine.playTile(game, game.currentTurnPlayer, otherTile, false), same(game));
      expect(
        DominoEngine.playTile(game, game.currentTurnPlayer, openingTile, false).board.single.id,
        openingTile.id,
      );
    });

    test('rejects unsupported player counts', () {
      expect(() => DominoGameState.initial(1), throwsArgumentError);
      expect(() => DominoGameState.initial(5), throwsArgumentError);
    });
  });

  group('Domino legal play', () {
    test('plays the first tile, removes it from hand, and advances turn', () {
      final opening = tile(1, 2, 3);
      final game = stateWith(
        board: const [],
        hands: {
          0: [opening, tile(2, 1, 1)],
          1: [tile(3, 4, 4)],
        },
        currentPlayer: 0,
      );

      final next = DominoEngine.playTile(game, 0, opening, false);

      expect(next.board, [opening]);
      expect(next.leftEnd, 2);
      expect(next.rightEnd, 3);
      expect(next.playerHands[0], hasLength(1));
      expect(next.currentTurnPlayer, 1);
      expect(next.winner, isNull);
      expect(game.board, isEmpty);
      expect(game.playerHands[0], hasLength(2));
    });

    test('uses the canonical hand tile instead of forged pip values', () {
      final actualTile = tile(10, 2, 4);
      final game = stateWith(
        board: const [],
        hands: {
          0: [actualTile],
          1: [tile(11, 0, 0)],
        },
        currentPlayer: 0,
      );

      final next = DominoEngine.playTile(game, 0, tile(10, 6, 6), false);

      expect(next.board.single.left, 2);
      expect(next.board.single.right, 4);
      expect(next.winner, 0);
    });

    test('flips a tile correctly when attaching to the left end', () {
      final game = stateWith(
        board: [tile(100, 2, 5)],
        hands: {
          0: [tile(1, 2, 4)],
          1: [tile(2, 0, 0)],
        },
        currentPlayer: 0,
        leftEnd: 2,
        rightEnd: 5,
      );

      final next = DominoEngine.playTile(game, 0, game.playerHands[0]!.single, true);

      expect(next.board.first.left, 4);
      expect(next.board.first.right, 2);
      expect(next.leftEnd, 4);
      expect(next.rightEnd, 5);
      expect(next.currentTurnPlayer, 1);
    });

    test('flips a tile correctly when attaching to the right end', () {
      final game = stateWith(
        board: [tile(100, 2, 5)],
        hands: {
          0: [tile(1, 3, 5)],
          1: [tile(2, 0, 0)],
        },
        currentPlayer: 0,
        leftEnd: 2,
        rightEnd: 5,
      );

      final next = DominoEngine.playTile(game, 0, game.playerHands[0]!.single, false);

      expect(next.board.last.left, 5);
      expect(next.board.last.right, 3);
      expect(next.leftEnd, 2);
      expect(next.rightEnd, 3);
    });

    test('rejects an unmatched tile, wrong player, and a repeated play without mutation', () {
      final game = stateWith(
        board: [tile(100, 2, 5)],
        hands: {
          0: [tile(1, 1, 3)],
          1: [tile(2, 0, 0)],
        },
        currentPlayer: 0,
        leftEnd: 2,
        rightEnd: 5,
      );
      final unmatched = game.playerHands[0]!.single;

      expect(DominoEngine.playTile(game, 0, unmatched, true), same(game));
      expect(DominoEngine.playTile(game, 1, unmatched, true), same(game));

      final won = DominoEngine.playTile(
        stateWith(
          board: const [],
          hands: {0: [tile(7, 2, 2)], 1: [tile(8, 3, 3)]},
          currentPlayer: 0,
        ),
        0,
        tile(7, 2, 2),
        false,
      );
      expect(won.winner, 0);
      expect(DominoEngine.playTile(won, 1, tile(8, 3, 3), false), same(won));
    });

    test('rejects actions from non-active players on an open board', () {
      final game = stateWith(
        board: [tile(100, 2, 5)],
        hands: {
          0: [tile(1, 2, 3)],
          1: [tile(2, 5, 6)],
        },
        currentPlayer: 0,
        leftEnd: 2,
        rightEnd: 5,
      );
      expect(DominoEngine.hasAnyValidMove(game, 1), isFalse);
      expect(DominoEngine.playTile(game, 1, game.playerHands[1]!.single, true), same(game));
    });

    test('rejects inconsistent endpoints and duplicate tile ids', () {
      final inconsistent = stateWith(
        board: [tile(100, 2, 5)],
        hands: {0: [tile(1, 2, 3)], 1: [tile(2, 5, 6)]},
        currentPlayer: 0,
        leftEnd: 1,
        rightEnd: 5,
      );
      expect(DominoEngine.playTile(inconsistent, 0, tile(1, 2, 3), true), same(inconsistent));

      final duplicateIds = stateWith(
        board: [tile(100, 2, 5)],
        hands: {0: [tile(100, 1, 3)], 1: [tile(2, 5, 6)]},
        currentPlayer: 0,
        leftEnd: 2,
        rightEnd: 5,
      );
      expect(DominoEngine.playTile(duplicateIds, 0, tile(100, 1, 3), true), same(duplicateIds));
    });

    test('reports legal moves only when the player has a playable tile', () {
      final game = stateWith(
        board: [tile(100, 2, 5)],
        hands: {
          0: [tile(1, 5, 6)],
          1: [tile(2, 0, 0)],
        },
        currentPlayer: 0,
        leftEnd: 2,
        rightEnd: 5,
      );

      expect(DominoEngine.hasAnyValidMove(game, 0), isTrue);
      expect(DominoEngine.hasAnyValidMove(game, 1), isFalse);
      expect(DominoEngine.canPlayTile(game, tile(3, 1, 2)), isTrue);
    });
  });

  group('Domino draw, pass, and scoring', () {
    test('draws one tile only when no current hand tile can be played', () {
      final game = stateWith(
        board: [tile(100, 2, 5)],
        hands: {
          0: [tile(1, 6, 6)],
          1: [tile(2, 0, 0)],
        },
        currentPlayer: 0,
        drawPile: [tile(3, 2, 6), tile(4, 1, 1)],
        leftEnd: 2,
        rightEnd: 5,
      );

      final next = DominoEngine.drawTile(game, 0);

      expect(next.playerHands[0], hasLength(2));
      expect(next.playerHands[0]!.last.id, 3);
      expect(next.drawPile, hasLength(1));
      expect(next.currentTurnPlayer, 0);
      expect(DominoEngine.hasAnyValidMove(next, 0), isTrue);
      expect(DominoEngine.drawTile(next, 1), same(next));
      expect(DominoEngine.drawTile(next, 0), same(next));
    });

    test('passes only after the draw pile is empty and ends a blocked game', () {
      final game = stateWith(
        board: [tile(100, 2, 5)],
        hands: {
          0: [tile(1, 6, 6)],
          1: [tile(2, 0, 0)],
        },
        currentPlayer: 0,
        leftEnd: 2,
        rightEnd: 5,
      );

      final firstPass = DominoEngine.passTurn(game, 0, 2);
      expect(firstPass.currentTurnPlayer, 1);
      expect(firstPass.consecutivePasses, 1);
      expect(firstPass.winner, isNull);

      final blocked = DominoEngine.passTurn(firstPass, 1, 2);
      expect(blocked.consecutivePasses, 2);
      expect(blocked.winner, 1);
      expect(DominoEngine.passTurn(blocked, 0, 2), same(blocked));
    });

    test('does not pass while a tile can be drawn or played', () {
      final game = stateWith(
        board: [tile(100, 2, 5)],
        hands: {
          0: [tile(1, 6, 6)],
          1: [tile(2, 0, 0)],
        },
        currentPlayer: 0,
        drawPile: [tile(3, 1, 1)],
        leftEnd: 2,
        rightEnd: 5,
      );

      expect(DominoEngine.passTurn(game, 0, 2), same(game));
      expect(DominoEngine.passTurn(game, 0, 3), same(game));
    });

    test('clears nullable endpoints and winner explicitly in copyWith', () {
      final game = stateWith(
        board: [tile(100, 2, 5)],
        hands: {0: [], 1: []},
        currentPlayer: 0,
        leftEnd: 2,
        rightEnd: 5,
        winner: 1,
      );
      final cleared = game.copyWith(
        clearLeftEnd: true,
        clearRightEnd: true,
        clearWinner: true,
      );

      expect(cleared.leftEnd, isNull);
      expect(cleared.rightEnd, isNull);
      expect(cleared.winner, isNull);
    });
  });
}
