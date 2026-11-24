import 'dart:math';

enum LudoColor { red, green, yellow, blue }

class LudoPiece {
  final String id;
  final LudoColor color;
  final int index;
  final int position;

  const LudoPiece({
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
    required Map<LudoColor, List<LudoPiece>> pieces,
    required this.currentTurn,
    this.diceValue,
    this.consecutiveSixes = 0,
    this.winner,
  }) : pieces = Map.unmodifiable({
          for (final entry in pieces.entries)
            entry.key: List<LudoPiece>.unmodifiable(entry.value),
        });

  factory LudoGameState.initial() {
    return LudoGameState(
      pieces: {
        for (final color in LudoColor.values)
          color: List.generate(
            4,
            (index) => LudoPiece(
              id: '${color.name}_$index',
              color: color,
              index: index,
            ),
          ),
      },
      currentTurn: LudoColor.red,
    );
  }

  LudoGameState copyWith({
    Map<LudoColor, List<LudoPiece>>? pieces,
    LudoColor? currentTurn,
    int? diceValue,
    bool clearDiceValue = false,
    int? consecutiveSixes,
    LudoColor? winner,
    bool clearWinner = false,
  }) {
    return LudoGameState(
      pieces: pieces ?? this.pieces,
      currentTurn: currentTurn ?? this.currentTurn,
      diceValue: clearDiceValue ? null : diceValue ?? this.diceValue,
      consecutiveSixes: consecutiveSixes ?? this.consecutiveSixes,
      winner: clearWinner ? null : winner ?? this.winner,
    );
  }
}

class LudoEngine {
  static const int trackLength = 52;
  static const int finishPosition = 58;
  static const List<int> safeZones = [0, 8, 13, 21, 26, 34, 39, 47];
  static const Map<LudoColor, int> startOffsets = {
    LudoColor.red: 0,
    LudoColor.green: 13,
    LudoColor.yellow: 26,
    LudoColor.blue: 39,
  };

  static final Random _random = Random.secure();

  static int rollDice() => _random.nextInt(6) + 1;

  /// Records a resolved die value. A third consecutive six forfeits that roll.
  static LudoGameState recordRoll(LudoGameState state, int value) {
    if (state.winner != null || state.diceValue != null || value < 1 || value > 6) {
      return state;
    }

    final sixes = value == 6 ? state.consecutiveSixes + 1 : 0;
    if (sixes >= 3) {
      return state.copyWith(
        currentTurn: _getNextTurn(state.currentTurn),
        consecutiveSixes: 0,
        clearDiceValue: true,
      );
    }

    return state.copyWith(diceValue: value, consecutiveSixes: sixes);
  }

  static bool isValidMove(
    LudoGameState state,
    LudoColor color,
    String pieceId,
    int dice,
  ) {
    if (state.currentTurn != color ||
        state.diceValue != dice ||
        dice < 1 ||
        dice > 6 ||
        state.winner != null) {
      return false;
    }

    final pieces = state.pieces[color];
    if (pieces == null) return false;
    final pieceIndex = pieces.indexWhere((piece) => piece.id == pieceId);
    if (pieceIndex == -1) return false;

    final piece = pieces[pieceIndex];
    if (piece.color != color) return false;
    final position = piece.position;
    if (position == -1) return dice == 6;
    if (position < 0 || position >= finishPosition) return false;
    return position + dice <= finishPosition;
  }

  static LudoGameState applyMove(
    LudoGameState state,
    LudoColor color,
    String pieceId,
    int dice,
  ) {
    if (!isValidMove(state, color, pieceId, dice)) return state;

    final updatedPieces = <LudoColor, List<LudoPiece>>{
      for (final entry in state.pieces.entries)
        entry.key: entry.value.map((piece) => piece.copyWith()).toList(),
    };
    final movingPieces = updatedPieces[color];
    if (movingPieces == null) return state;
    final pieceIndex = movingPieces.indexWhere((piece) => piece.id == pieceId);
    if (pieceIndex == -1) return state;

    final piece = movingPieces[pieceIndex];
    final newPosition = piece.position == -1 ? 0 : piece.position + dice;
    movingPieces[pieceIndex] = piece.copyWith(position: newPosition);

    var captured = false;
    if (newPosition < trackLength) {
      final absoluteSquare = _absoluteSquare(color, newPosition);
      if (!safeZones.contains(absoluteSquare)) {
        for (final entry in updatedPieces.entries) {
          if (entry.key == color) continue;
          final opponentPieces = entry.value;
          for (var index = 0; index < opponentPieces.length; index++) {
            final opponent = opponentPieces[index];
            if (opponent.position >= 0 &&
                opponent.position < trackLength &&
                _absoluteSquare(entry.key, opponent.position) == absoluteSquare) {
              opponentPieces[index] = opponent.copyWith(position: -1);
              captured = true;
            }
          }
        }
      }
    }

    final hasWon = movingPieces.every((candidate) => candidate.position == finishPosition);
    final nextTurn = dice == 6 || captured || hasWon
        ? state.currentTurn
        : _getNextTurn(state.currentTurn);
    final nextSixes = dice == 6 ? state.consecutiveSixes : 0;

    return state.copyWith(
      pieces: updatedPieces,
      currentTurn: nextTurn,
      clearDiceValue: true,
      consecutiveSixes: nextSixes,
      winner: hasWon ? color : null,
      clearWinner: !hasWon,
    );
  }

  /// Clears a roll only when the current player has no legal piece movement.
  static LudoGameState skipIfNoLegalMove(LudoGameState state) {
    final dice = state.diceValue;
    if (dice == null || state.winner != null) return state;
    final hasMove = (state.pieces[state.currentTurn] ?? const <LudoPiece>[])
        .any((piece) => isValidMove(state, state.currentTurn, piece.id, dice));
    if (hasMove) return state;

    return state.copyWith(
      currentTurn: dice == 6 ? state.currentTurn : _getNextTurn(state.currentTurn),
      clearDiceValue: true,
      consecutiveSixes: dice == 6 ? state.consecutiveSixes : 0,
    );
  }

  static int _absoluteSquare(LudoColor color, int progress) =>
      (startOffsets[color]! + progress) % trackLength;

  static LudoColor _getNextTurn(LudoColor current) {
    final index = (LudoColor.values.indexOf(current) + 1) % LudoColor.values.length;
    return LudoColor.values[index];
  }
}
