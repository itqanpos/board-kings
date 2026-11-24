import 'dart:math';

class DominoTile {
  final int id;
  final int left;
  final int right;

  const DominoTile({required this.id, required this.left, required this.right});

  bool get isDouble => left == right;
  int get totalValue => left + right;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DominoTile && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DominoGameState {
  final List<DominoTile> board;
  final Map<int, List<DominoTile>> playerHands;
  final List<DominoTile> drawPile;
  final int? openingTileId;
  final int currentTurnPlayer;
  final int? leftEnd;
  final int? rightEnd;
  final int consecutivePasses;
  final int? winner;

  DominoGameState({
    required List<DominoTile> board,
    required Map<int, List<DominoTile>> playerHands,
    required this.currentTurnPlayer,
    List<DominoTile> drawPile = const [],
    this.openingTileId,
    this.leftEnd,
    this.rightEnd,
    this.consecutivePasses = 0,
    this.winner,
  })  : board = List.unmodifiable(board),
        playerHands = Map.unmodifiable({
          for (final entry in playerHands.entries)
            entry.key: List<DominoTile>.unmodifiable(entry.value),
        }),
        drawPile = List.unmodifiable(drawPile);

  factory DominoGameState.initial(int playerCount, {Random? random}) {
    if (playerCount < 2 || playerCount > 4) {
      throw ArgumentError.value(playerCount, 'playerCount', 'Must be between 2 and 4');
    }

    final tiles = <DominoTile>[];
    var id = 0;
    for (var left = 0; left <= 6; left++) {
      for (var right = left; right <= 6; right++) {
        tiles.add(DominoTile(id: id++, left: left, right: right));
      }
    }
    (random ?? Random()).shuffle(tiles);

    final tilesPerPlayer = playerCount == 2 ? 7 : 5;
    var tileIndex = 0;
    final hands = <int, List<DominoTile>>{};
    for (var player = 0; player < playerCount; player++) {
      hands[player] = tiles.sublist(tileIndex, tileIndex + tilesPerPlayer);
      tileIndex += tilesPerPlayer;
    }

    var startingPlayer = 0;
    int? openingTileId;
    var highestDouble = -1;
    var highestTileValue = -1;
    for (final entry in hands.entries) {
      for (final tile in entry.value) {
        if (tile.isDouble && tile.left > highestDouble) {
          highestDouble = tile.left;
          startingPlayer = entry.key;
          openingTileId = tile.id;
        }
      }
    }
    if (highestDouble == -1) {
      for (final entry in hands.entries) {
        for (final tile in entry.value) {
          if (tile.totalValue > highestTileValue) {
            highestTileValue = tile.totalValue;
            startingPlayer = entry.key;
            openingTileId = tile.id;
          }
        }
      }
    }

    return DominoGameState(
      board: const [],
      playerHands: hands,
      currentTurnPlayer: startingPlayer,
      drawPile: tiles.sublist(tileIndex),
      openingTileId: openingTileId,
    );
  }

  DominoGameState copyWith({
    List<DominoTile>? board,
    Map<int, List<DominoTile>>? playerHands,
    List<DominoTile>? drawPile,
    int? currentTurnPlayer,
    int? openingTileId,
    bool clearOpeningTileId = false,
    int? leftEnd,
    bool clearLeftEnd = false,
    int? rightEnd,
    bool clearRightEnd = false,
    int? consecutivePasses,
    int? winner,
    bool clearWinner = false,
  }) {
    return DominoGameState(
      board: board ?? this.board,
      playerHands: playerHands ?? this.playerHands,
      drawPile: drawPile ?? this.drawPile,
      currentTurnPlayer: currentTurnPlayer ?? this.currentTurnPlayer,
      openingTileId: clearOpeningTileId ? null : openingTileId ?? this.openingTileId,
      leftEnd: clearLeftEnd ? null : leftEnd ?? this.leftEnd,
      rightEnd: clearRightEnd ? null : rightEnd ?? this.rightEnd,
      consecutivePasses: consecutivePasses ?? this.consecutivePasses,
      winner: clearWinner ? null : winner ?? this.winner,
    );
  }
}

class DominoEngine {
  static bool canPlayTile(DominoGameState state, DominoTile tile) {
    if (state.board.isEmpty) return true;
    return tile.left == state.leftEnd ||
        tile.right == state.leftEnd ||
        tile.left == state.rightEnd ||
        tile.right == state.rightEnd;
  }

  static bool hasAnyValidMove(DominoGameState state, int player) {
    final hand = state.playerHands[player];
    if (hand == null || hand.isEmpty || state.winner != null) return false;
    if (state.board.isEmpty) {
      return player == state.currentTurnPlayer &&
          (state.openingTileId == null || hand.any((tile) => tile.id == state.openingTileId));
    }
    return hand.any((tile) => canPlayTile(state, tile));
  }

  static DominoGameState playTile(
    DominoGameState state,
    int player,
    DominoTile tile,
    bool playOnLeft,
  ) {
    if (state.currentTurnPlayer != player || state.winner != null) return state;
    final hand = state.playerHands[player];
    if (hand == null) return state;

    final tileIndex = hand.indexWhere((candidate) => candidate.id == tile.id);
    if (tileIndex == -1) return state;
    final actualTile = hand[tileIndex];
    if (state.board.isEmpty &&
        state.openingTileId != null &&
        actualTile.id != state.openingTileId) {
      return state;
    }

    final newBoard = List<DominoTile>.of(state.board);
    var newLeft = state.leftEnd;
    var newRight = state.rightEnd;

    if (newBoard.isEmpty) {
      newBoard.add(actualTile);
      newLeft = actualTile.left;
      newRight = actualTile.right;
    } else if (playOnLeft) {
      if (actualTile.right == newLeft) {
        newBoard.insert(0, actualTile);
        newLeft = actualTile.left;
      } else if (actualTile.left == newLeft) {
        newBoard.insert(
          0,
          DominoTile(id: actualTile.id, left: actualTile.right, right: actualTile.left),
        );
        newLeft = actualTile.right;
      } else {
        return state;
      }
    } else {
      if (actualTile.left == newRight) {
        newBoard.add(actualTile);
        newRight = actualTile.right;
      } else if (actualTile.right == newRight) {
        newBoard.add(
          DominoTile(id: actualTile.id, left: actualTile.right, right: actualTile.left),
        );
        newRight = actualTile.left;
      } else {
        return state;
      }
    }

    final updatedHands = <int, List<DominoTile>>{
      for (final entry in state.playerHands.entries)
        entry.key: List<DominoTile>.of(entry.value),
    };
    updatedHands[player]!.removeAt(tileIndex);
    final nextPlayer = _nextPlayer(state, player);
    if (nextPlayer == null) return state;

    final winningPlayer = updatedHands[player]!.isEmpty ? player : null;
    return state.copyWith(
      board: newBoard,
      playerHands: updatedHands,
      currentTurnPlayer: nextPlayer,
      leftEnd: newLeft,
      rightEnd: newRight,
      consecutivePasses: 0,
      winner: winningPlayer,
      clearWinner: winningPlayer == null,
    );
  }

  static DominoGameState drawTile(DominoGameState state, int player) {
    if (state.currentTurnPlayer != player || state.winner != null) return state;
    final hand = state.playerHands[player];
    if (hand == null || state.drawPile.isEmpty || hasAnyValidMove(state, player)) {
      return state;
    }

    final updatedHands = <int, List<DominoTile>>{
      for (final entry in state.playerHands.entries)
        entry.key: List<DominoTile>.of(entry.value),
    };
    updatedHands[player]!.add(state.drawPile.first);
    return state.copyWith(
      playerHands: updatedHands,
      drawPile: state.drawPile.sublist(1),
      consecutivePasses: 0,
    );
  }

  static DominoGameState passTurn(
    DominoGameState state,
    int player,
    int totalPlayers,
  ) {
    if (state.winner != null ||
        state.currentTurnPlayer != player ||
        totalPlayers != state.playerHands.length ||
        totalPlayers < 2 ||
        state.drawPile.isNotEmpty ||
        hasAnyValidMove(state, player)) {
      return state;
    }

    final nextPlayer = _nextPlayer(state, player);
    if (nextPlayer == null) return state;
    final newPasses = state.consecutivePasses + 1;
    final winner = newPasses >= totalPlayers ? _lowestPipPlayer(state) : null;

    return state.copyWith(
      currentTurnPlayer: nextPlayer,
      consecutivePasses: newPasses,
      winner: winner,
      clearWinner: winner == null,
    );
  }

  static int? _nextPlayer(DominoGameState state, int player) {
    final playerCount = state.playerHands.length;
    if (playerCount < 2 ||
        !state.playerHands.keys.toSet().containsAll(List.generate(playerCount, (i) => i))) {
      return null;
    }
    return (player + 1) % playerCount;
  }

  static int? _lowestPipPlayer(DominoGameState state) {
    if (state.playerHands.isEmpty) return null;
    var lowestPlayer = 0;
    var lowestPips = state.playerHands[0]!.fold<int>(
      0,
      (total, tile) => total + tile.totalValue,
    );
    for (var player = 1; player < state.playerHands.length; player++) {
      final pips = state.playerHands[player]!.fold<int>(
        0,
        (total, tile) => total + tile.totalValue,
      );
      if (pips < lowestPips) {
        lowestPips = pips;
        lowestPlayer = player;
      }
    }
    return lowestPlayer;
  }
}
