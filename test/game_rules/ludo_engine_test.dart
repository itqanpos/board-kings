import 'package:board_kings/features/ludo/engine/ludo_engine.dart';
import 'package:board_kings/ludo_engine.dart' as board;
import 'package:flutter_test/flutter_test.dart';

LudoGameState stateWith({
  Map<LudoColor, Map<int, int>> positions = const {},
  LudoColor currentTurn = LudoColor.red,
  int? diceValue,
  int consecutiveSixes = 0,
  LudoColor? winner,
}) {
  return LudoGameState(
    pieces: {
      for (final color in LudoColor.values)
        color: List.generate(
          4,
          (index) => LudoPiece(
            id: '${color.name}_$index',
            color: color,
            index: index,
            position: positions[color]?[index] ?? -1,
          ),
        ),
    },
    currentTurn: currentTurn,
    diceValue: diceValue,
    consecutiveSixes: consecutiveSixes,
    winner: winner,
  );
}

void main() {
  group('Ludo board coordinates', () {
    test('maps relative progress to the correct color-specific track square', () {
      expect(board.LudoEngine.getAbsoluteTrackPosition('red', 0), 0);
      expect(board.LudoEngine.getAbsoluteTrackPosition('green', 0), 13);
      expect(board.LudoEngine.getAbsoluteTrackPosition('yellow', 0), 26);
      expect(board.LudoEngine.getAbsoluteTrackPosition('blue', 0), 39);
      expect(board.LudoEngine.getAbsoluteTrackPosition('green', 39), 0);
      expect(board.LudoEngine.getAbsoluteTrackPosition('red', -1), isNull);
      expect(board.LudoEngine.getAbsoluteTrackPosition('red', 52), isNull);

      expect(board.LudoEngine.getTokenCoords('red', 0, 0), [6.0, 13.0]);
      expect(board.LudoEngine.getTokenCoords('green', 0, 0), [1.0, 6.0]);
      expect(board.LudoEngine.getTokenCoords('yellow', 0, 0), [8.0, 1.0]);
      expect(board.LudoEngine.getTokenCoords('blue', 0, 0), [13.0, 8.0]);
    });

    test('gives every piece in a shared track square its own visual position', () {
      final positions = [
        for (var index = 0; index < 4; index++)
          board.LudoEngine.getTokenCoords(
            'red',
            0,
            index,
            stackIndex: index,
            stackSize: 4,
          ),
      ];

      expect(positions.toSet(), hasLength(4));
      expect(
        positions.any((point) => point[0] == 6.0 && point[1] == 13.0),
        isFalse,
      );
      expect(board.LudoEngine.getTokenCoords('red', -1, 0), [1.5, 1.5]);
      expect(board.LudoEngine.getTokenCoords('red', 0, 0), [6.0, 13.0]);
    });

    test('offsets mixed-color pieces sharing one absolute square without changing progress', () {
      final redPoint = board.LudoEngine.getTokenCoords(
        'red',
        0,
        0,
        stackIndex: 0,
        stackSize: 2,
      );
      final greenPoint = board.LudoEngine.getTokenCoords(
        'green',
        39,
        0,
        stackIndex: 1,
        stackSize: 2,
      );

      expect(board.LudoEngine.getAbsoluteTrackPosition('red', 0), 0);
      expect(board.LudoEngine.getAbsoluteTrackPosition('green', 39), 0);
      expect(redPoint, isNot(greenPoint));
      expect(redPoint[1], greenPoint[1]);
    });
  });

  group('Ludo turn and roll validation', () {
    test('creates four colors with four base pieces each', () {
      final game = LudoGameState.initial();
      expect(game.pieces.keys, containsAll(LudoColor.values));
      expect(game.pieces.values.expand((pieces) => pieces), hasLength(16));
      expect(game.pieces.values.every((pieces) => pieces.every((piece) => piece.position == -1)), isTrue);
    });

    test('records valid rolls and rejects invalid or duplicate rolls', () {
      final game = LudoGameState.initial();
      expect(LudoEngine.recordRoll(game, 0), same(game));
      expect(LudoEngine.recordRoll(game, 7), same(game));

      final rolled = LudoEngine.recordRoll(game, 4);
      expect(rolled.diceValue, 4);
      expect(rolled.consecutiveSixes, 0);
      expect(LudoEngine.recordRoll(rolled, 2), same(rolled));
    });

    test('requires a six to enter from base and keeps the six bonus turn', () {
      final rolledFive = LudoEngine.recordRoll(LudoGameState.initial(), 5);
      expect(LudoEngine.isValidMove(rolledFive, LudoColor.red, 'red_0', 5), isFalse);
      expect(LudoEngine.applyMove(rolledFive, LudoColor.red, 'red_0', 5), same(rolledFive));

      final rolledSix = LudoEngine.recordRoll(LudoGameState.initial(), 6);
      final entered = LudoEngine.applyMove(rolledSix, LudoColor.red, 'red_0', 6);
      expect(entered.pieces[LudoColor.red]![0].position, 0);
      expect(entered.currentTurn, LudoColor.red);
      expect(entered.diceValue, isNull);
      expect(entered.consecutiveSixes, 1);
    });

    test('a third consecutive six forfeits the roll without moving a piece', () {
      final beforeThirdSix = stateWith(consecutiveSixes: 2);
      final afterThirdSix = LudoEngine.recordRoll(beforeThirdSix, 6);

      expect(afterThirdSix.currentTurn, LudoColor.green);
      expect(afterThirdSix.diceValue, isNull);
      expect(afterThirdSix.consecutiveSixes, 0);
      expect(afterThirdSix.pieces[LudoColor.red]!.every((piece) => piece.position == -1), isTrue);
      expect(beforeThirdSix.currentTurn, LudoColor.red);
    });

    test('advances the turn and resets six counter after a non-six roll', () {
      final state = stateWith(consecutiveSixes: 2);
      final rolled = LudoEngine.recordRoll(state, 3);
      expect(rolled.currentTurn, LudoColor.red);
      expect(rolled.consecutiveSixes, 0);
      expect(rolled.diceValue, 3);
    });
  });

  group('Ludo movement and capture', () {
    test('moves along player progress and advances after an ordinary move', () {
      final state = stateWith(positions: {
        LudoColor.red: {0: 4},
      });
      final rolled = LudoEngine.recordRoll(state, 2);
      final moved = LudoEngine.applyMove(rolled, LudoColor.red, 'red_0', 2);

      expect(moved.pieces[LudoColor.red]![0].position, 6);
      expect(moved.currentTurn, LudoColor.green);
      expect(moved.diceValue, isNull);
      expect(moved.consecutiveSixes, 0);
      expect(state.pieces[LudoColor.red]![0].position, 4);
    });

    test('returns false for missing pieces, wrong player, wrong die, and finished pieces', () {
      final rolled = LudoEngine.recordRoll(
        stateWith(positions: {
          LudoColor.red: {0: 58},
        }),
        1,
      );

      expect(LudoEngine.isValidMove(rolled, LudoColor.red, 'missing', 1), isFalse);
      expect(LudoEngine.isValidMove(rolled, LudoColor.green, 'red_0', 1), isFalse);
      expect(LudoEngine.isValidMove(rolled, LudoColor.red, 'red_0', 2), isFalse);
      expect(LudoEngine.isValidMove(rolled, LudoColor.red, 'red_0', 1), isFalse);
      expect(LudoEngine.applyMove(rolled, LudoColor.red, 'missing', 1), same(rolled));
    });

    test('requires an exact roll to finish and declares a winner', () {
      final beforeFinish = stateWith(positions: {
        LudoColor.red: {0: 57, 1: 58, 2: 58, 3: 58},
      });
      final tooLarge = LudoEngine.recordRoll(beforeFinish, 2);
      expect(LudoEngine.isValidMove(tooLarge, LudoColor.red, 'red_0', 2), isFalse);

      final exactRoll = LudoEngine.recordRoll(beforeFinish, 1);
      final finished = LudoEngine.applyMove(exactRoll, LudoColor.red, 'red_0', 1);
      expect(finished.pieces[LudoColor.red]!.every((piece) => piece.position == 58), isTrue);
      expect(finished.winner, LudoColor.red);
      expect(finished.diceValue, isNull);
      expect(LudoEngine.recordRoll(finished, 6), same(finished));
    });

    test('captures an opponent and allows that piece to re-enter from base', () {
      final state = stateWith(positions: {
        LudoColor.red: {0: 4},
        LudoColor.green: {0: 44},
      });
      final rolled = LudoEngine.recordRoll(state, 1);
      final captured = LudoEngine.applyMove(rolled, LudoColor.red, 'red_0', 1);

      expect(captured.pieces[LudoColor.red]![0].position, 5);
      expect(captured.pieces[LudoColor.green]![0].position, -1);
      expect(captured.currentTurn, LudoColor.red);

      final greenTurn = captured.copyWith(currentTurn: LudoColor.green);
      final reentryRoll = LudoEngine.recordRoll(greenTurn, 6);
      final reentered = LudoEngine.applyMove(
        reentryRoll,
        LudoColor.green,
        'green_0',
        6,
      );
      expect(reentered.pieces[LudoColor.green]![0].position, 0);
      expect(
        board.LudoEngine.getTokenCoords('green', 0, 0),
        [1.0, 6.0],
      );
    });

    test('does not capture a piece on an absolute safe square', () {
      final state = stateWith(positions: {
        LudoColor.red: {0: 12},
        LudoColor.green: {0: 0},
      });
      final rolled = LudoEngine.recordRoll(state, 1);
      final moved = LudoEngine.applyMove(rolled, LudoColor.red, 'red_0', 1);

      expect(moved.pieces[LudoColor.red]![0].position, 13);
      expect(moved.pieces[LudoColor.green]![0].position, 0);
      expect(moved.currentTurn, LudoColor.green);
    });

    test('does not treat home-lane positions as track squares for capture', () {
      final state = stateWith(positions: {
        LudoColor.red: {0: 51},
        LudoColor.green: {0: 0},
      });
      final rolled = LudoEngine.recordRoll(state, 1);
      final moved = LudoEngine.applyMove(rolled, LudoColor.red, 'red_0', 1);

      expect(moved.pieces[LudoColor.red]![0].position, 52);
      expect(moved.pieces[LudoColor.green]![0].position, 0);
    });

    test('skips only when no legal move exists and clears the pending die', () {
      final noMove = LudoEngine.recordRoll(LudoGameState.initial(), 1);
      final skipped = LudoEngine.skipIfNoLegalMove(noMove);
      expect(skipped.currentTurn, LudoColor.green);
      expect(skipped.diceValue, isNull);

      final six = LudoEngine.recordRoll(LudoGameState.initial(), 6);
      expect(LudoEngine.skipIfNoLegalMove(six), same(six));
    });

    test('clears a die and winner explicitly in copyWith', () {
      final state = stateWith(diceValue: 4, winner: LudoColor.blue);
      final cleared = state.copyWith(clearDiceValue: true, clearWinner: true);
      expect(cleared.diceValue, isNull);
      expect(cleared.winner, isNull);
    });

    test('uses an injectable seeded random source for reproducible dice', () {
      final firstRoll = LudoEngine.rollDice(random: Random(42));
      expect(LudoEngine.rollDice(random: Random(42)), firstRoll);
      for (var seed = 0; seed < 100; seed++) {
        expect(LudoEngine.rollDice(random: Random(seed)), inInclusiveRange(1, 6));
      }
    });

    test('cannot land on or cross an opponent blockade', () {
      final state = stateWith(positions: {
        LudoColor.red: {0: 3},
        LudoColor.green: {0: 44, 1: 44},
      });
      final rolledTwo = LudoEngine.recordRoll(state, 2);
      expect(LudoEngine.isValidMove(rolledTwo, LudoColor.red, 'red_0', 2), isFalse);

      final rolledThree = LudoEngine.recordRoll(state, 3);
      expect(LudoEngine.isValidMove(rolledThree, LudoColor.red, 'red_0', 3), isFalse);
      expect(
        LudoEngine.applyMove(rolledThree, LudoColor.red, 'red_0', 3),
        same(rolledThree),
      );
      expect(state.pieces[LudoColor.green]!.where((piece) => piece.position == 44), hasLength(2));
    });
  });
}
