import 'dart:math';

import '../../game_ai_difficulty.dart';
import 'ludo_engine.dart';

class LudoAi {
  const LudoAi._();

  /// Returns a rules-legal piece id for the current roll, or null when no move exists.
  static String? choosePiece(
    LudoGameState state, {
    GameAiDifficulty difficulty = GameAiDifficulty.medium,
    Random? random,
  }) {
    final die = state.diceValue;
    if (die == null || state.winner != null) return null;
    final candidates = (state.pieces[state.currentTurn] ?? const <LudoPiece>[])
        .where((piece) =>
            LudoEngine.isValidMove(state, state.currentTurn, piece.id, die))
        .toList();
    if (candidates.isEmpty) return null;
    if (difficulty == GameAiDifficulty.easy) return candidates.first.id;

    final scored = candidates.map((piece) {
      final next = LudoEngine.applyMove(state, state.currentTurn, piece.id, die);
      final moved = next.pieces[state.currentTurn]!
          .firstWhere((candidate) => candidate.id == piece.id);
      var score = moved.position * 1.0;
      if (piece.position == -1) score += 12;
      if (next.winner == state.currentTurn) score += 10000;
      if (next.currentTurn == state.currentTurn &&
          state.currentTurn != next.winner) {
        score += 5;
      }
      if (moved.position < LudoEngine.trackLength &&
          LudoEngine.safeZones
              .contains((LudoEngine.startOffsets[state.currentTurn]! + moved.position) % LudoEngine.trackLength)) {
        score += 6;
      }
      final captured = state.pieces.entries
          .where((entry) => entry.key != state.currentTurn)
          .expand((entry) => entry.value)
          .where((enemy) =>
              enemy.position >= 0 &&
              !next.pieces.entries
                  .where((entry) => entry.key != state.currentTurn)
                  .expand((entry) => entry.value)
                  .any((after) => after.id == enemy.id && after.position == enemy.position));
      score += captured.length * 18;
      if (difficulty == GameAiDifficulty.hard) {
        score -= _riskPenalty(next, moved);
      }
      return (piece: piece, score: score);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final bestScore = scored.first.score;
    final best = scored.where((entry) => entry.score == bestScore).toList();
    return best[(random ?? Random(0)).nextInt(best.length)].piece.id;
  }

  static double _riskPenalty(LudoGameState state, LudoPiece piece) {
    if (piece.position < 0 || piece.position >= LudoEngine.trackLength) return 0;
    final square = (LudoEngine.startOffsets[piece.color]! + piece.position) %
        LudoEngine.trackLength;
    if (LudoEngine.safeZones.contains(square)) return 0;
    var threats = 0;
    for (final entry in state.pieces.entries) {
      if (entry.key == piece.color) continue;
      for (final enemy in entry.value) {
        if (enemy.position < 0 || enemy.position >= LudoEngine.trackLength) continue;
        final enemySquare =
            (LudoEngine.startOffsets[entry.key]! + enemy.position) %
                LudoEngine.trackLength;
        final distance = (square - enemySquare + LudoEngine.trackLength) %
            LudoEngine.trackLength;
        if (distance >= 1 && distance <= 6) threats++;
      }
    }
    return threats * 4;
  }
}
