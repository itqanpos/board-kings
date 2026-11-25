import '../../game_ai_difficulty.dart';
import 'domino_engine.dart';

class DominoAiMove {
  const DominoAiMove({required this.tileId, required this.playOnLeft});

  final int tileId;
  final bool playOnLeft;
}

class DominoAi {
  const DominoAi._();

  /// Chooses a rules-legal placement from the active player's visible hand.
  static DominoAiMove? chooseMove(
    DominoGameState state, {
    GameAiDifficulty difficulty = GameAiDifficulty.medium,
  }) {
    final player = state.currentTurnPlayer;
    final hand = state.playerHands[player];
    if (hand == null || state.winner != null) return null;

    final candidates = <({DominoAiMove move, DominoGameState next})>[];
    for (final tile in hand) {
      if (state.board.isEmpty) {
        final isRequiredOpening =
            state.openingTileId == null || tile.id == state.openingTileId;
        if (isRequiredOpening) {
          final next = DominoEngine.playTile(state, player, tile, false);
          if (!identical(next, state)) {
            candidates.add((
              move: DominoAiMove(tileId: tile.id, playOnLeft: false),
              next: next,
            ));
          }
        }
        continue;
      }
      for (final playOnLeft in [true, false]) {
        final next = DominoEngine.playTile(state, player, tile, playOnLeft);
        if (!identical(next, state)) {
          candidates.add((
            move: DominoAiMove(tileId: tile.id, playOnLeft: playOnLeft),
            next: next,
          ));
        }
      }
    }
    if (candidates.isEmpty) return null;
    if (difficulty == GameAiDifficulty.easy) return candidates.first.move;

    double score(({DominoAiMove move, DominoGameState next}) candidate) {
      final played = hand.firstWhere((tile) => tile.id == candidate.move.tileId);
      if (candidate.next.winner == player) return 10000;
      var value = played.totalValue *
          (difficulty == GameAiDifficulty.hard ? 2.0 : 1.0);
      if (difficulty == GameAiDifficulty.hard) {
        final remaining = candidate.next.playerHands[player] ?? const [];
        final left = candidate.next.leftEnd;
        final right = candidate.next.rightEnd;
        final support = remaining.where((tile) =>
            tile.left == left ||
            tile.right == left ||
            tile.left == right ||
            tile.right == right).length;
        value += support * 3;
        if (played.isDouble) value += 1;
      }
      return value;
    }

    candidates.sort((a, b) => score(b).compareTo(score(a)));
    return candidates.first.move;
  }
}
