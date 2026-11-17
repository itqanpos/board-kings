import 'dart:math';

enum LudoColor { red, green, yellow, blue }

class LudoPiece {
  final String id;
  final LudoColor color;
  final int index; // -1: base, 0-51: main track, 52-57: home stretch, 58: finished
  int position; // absolute board position or track step

  LudoPiece({
    required this.id,
    required this.color,
    required this.index,
    this.position = -1,
  });

  LudoPiece copyWith({int? position, int? index}) {
    return LudoPiece(
      id: id,
      color: color,
      index: index ?? this.index,
      position: position ?? this.position,
    );
  }
}

class LudoGameState {
  final Map<LudoColor, List<LudoPiece>> pieces;
  final LudoColor currentTurn;
  final int? diceValue;
  final int consecutiveSixes;
  final LudoColor? winner;

  LudoGameState({
    required this.pieces,
    required this.currentTurn,
    this.diceValue,
    this.consecutiveSixes = 0,
    this.winner,
  });

  factory LudoGameState.initial() {
    Map<LudoColor, List<LudoPiece>> initialPieces = {};
    for (var color in LudoColor.values) {
      initialPieces[color] = List.generate(
        4,
        (i) => LudoPiece(id: '${color.name}_$i', color: color, index: i, position: -1),
      );
    }
    return LudoGameState(pieces: initialPieces, currentTurn: LudoColor.red);
  }

  LudoGameState copyWith({
    Map<LudoColor, List<LudoPiece>>? pieces,
    LudoColor? currentTurn,
    int? diceValue,
    int? consecutiveSixes,
    LudoColor? winner,
  }) {
    return LudoGameState(
      pieces: pieces ?? this.pieces,
      currentTurn: currentTurn ?? this.currentTurn,
      diceValue: diceValue ?? this.diceValue,
      consecutiveSixes: consecutiveSixes ?? this.consecutiveSixes,
      winner: winner ?? this.winner,
    );
  }
}

class LudoEngine {
  static const List<int> safeZones = [0, 8, 13, 21, 26, 34, 39, 47];

  // Safe random generator for local play
  static final Random _random = Random();

  static int rollDice() {
    return _random.nextInt(6) + 1;
  }

  static bool isValidMove(LudoGameState state, LudoColor color, String pieceId, int dice) {
    if (state.currentTurn != color || state.diceValue != dice || state.winner != null) {
      return false;
    }

    final piece = state.pieces[color]?.firstWhere((p) => p.id == pieceId);
    if (piece == null) return false;

    // Finished pieces cannot move
    if (piece.position == 58) return false;

    // In base, requires a 6 to exit
    if (piece.position == -1) {
      return dice == 6;
    }

    // Moving on track or home stretch
    if (piece.position + dice > 58) {
      return false; // Exact roll needed for final home position (58)
    }

    return true;
  }

  static LudoGameState applyMove(LudoGameState state, LudoColor color, String pieceId, int dice) {
    if (!isValidMove(state, color, pieceId, dice)) {
      return state;
    }

    final updatedPieces = Map<LudoColor, List<LudoPiece>>.from(
      state.pieces.map((k, v) => MapEntry(k, v.map((p) => p.copyWith()).toList())),
    );

    final piece = updatedPieces[color]!.firstWhere((p) => p.id == pieceId);

    int newPosition;
    if (piece.position == -1) {
      newPosition = 0; // Spawn point
    } else {
      newPosition = piece.position + dice;
    }

    piece.position = newPosition;

    // Check for captures on main track (excluding safe zones)
    bool captured = false;
    if (newPosition <= 51 && !safeZones.contains(newPosition)) {
      for (var entry in updatedPieces.entries) {
        if (entry.key != color) {
          for (var otherPiece in entry.value) {
            if (otherPiece.position == newPosition) {
              otherPiece.position = -1; // Send back to base
              captured = true;
            }
          }
        }
      }
    }

    // Check for win condition
    bool hasWon = updatedPieces[color]!.every((p) => p.position == 58);
    LudoColor? winner = hasWon ? color : state.winner;

    // Turn management: Rolling a 6 or capturing grants an extra turn
    LudoColor nextTurn = state.currentTurn;
    int newConsecutiveSixes = state.consecutiveSixes;

    if (dice == 6) {
      newConsecutiveSixes++;
      if (newConsecutiveSixes >= 3) {
        // Penalty for 3 sixes: reset piece if moved and skip turn
        piece.position = -1;
        newConsecutiveSixes = 0;
        nextTurn = _getNextTurn(state.currentTurn);
      }
    } else {
      newConsecutiveSixes = 0;
      if (!captured) {
        nextTurn = _getNextTurn(state.currentTurn);
      }
    }

    return state.copyWith(
      pieces: updatedPieces,
      currentTurn: nextTurn,
      diceValue: null,
      consecutiveSixes: newConsecutiveSixes,
      winner: winner,
    );
  }

  static LudoColor _getNextTurn(LudoColor current) {
    switch (current) {
      case LudoColor.red:
        return LudoColor.green;
      case LudoColor.green:
        return LudoColor.yellow;
      case LudoColor.yellow:
        return LudoColor.blue;
      case LudoColor.blue:
        return LudoColor.red;
    }
  }
}
