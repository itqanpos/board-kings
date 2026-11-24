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
      identical(this, other) || other is DominoTile && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DominoGameState {
  final List<DominoTile> board;
  final Map<int, List<DominoTile>> playerHands;
  final int currentTurnPlayer;
  final int? leftEnd;
  final int? rightEnd;
  final int consecutivePasses;
  final int? winner;

  DominoGameState({
    required this.board,
    required this.playerHands,
    required this.currentTurnPlayer,
    this.leftEnd,
    this.rightEnd,
    this.consecutivePasses = 0,
    this.winner,
  });

  factory DominoGameState.initial(int playerCount) {
    List<DominoTile> allTiles = [];
    int id = 0;
    for (int i = 0; i <= 6; i++) {
      for (int j = i; j <= 6; j++) {
        allTiles.add(DominoTile(id: id++, left: i, right: j));
      }
    }
    allTiles.shuffle(Random());

    Map<int, List<DominoTile>> hands = {};
    int tilesPerPlayer = (playerCount == 2) ? 7 : 5;
    int tileIndex = 0;

    for (int p = 0; p < playerCount; p++) {
      hands[p] = allTiles.sublist(tileIndex, tileIndex + tilesPerPlayer);
      tileIndex += tilesPerPlayer;
    }

    // Determine starting player by highest double
    int startingPlayer = 0;
    int highestDouble = -1;
    for (int p = 0; p < playerCount; p++) {
      for (var tile in hands[p]!) {
        if (tile.isDouble && tile.left > highestDouble) {
          highestDouble = tile.left;
          startingPlayer = p;
        }
      }
    }

    return DominoGameState(
      board: [],
      playerHands: hands,
      currentTurnPlayer: startingPlayer,
    );
  }

  DominoGameState copyWith({
    List<DominoTile>? board,
    Map<int, List<DominoTile>>? playerHands,
    int? currentTurnPlayer,
    int? leftEnd,
    int? rightEnd,
    int? consecutivePasses,
    int? winner,
  }) {
    return DominoGameState(
      board: board ?? this.board,
      playerHands: playerHands ?? this.playerHands,
      currentTurnPlayer: currentTurnPlayer ?? this.currentTurnPlayer,
      leftEnd: leftEnd ?? this.leftEnd,
      rightEnd: rightEnd ?? this.rightEnd,
      consecutivePasses: consecutivePasses ?? this.consecutivePasses,
      winner: winner ?? this.winner,
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
    if (state.board.isEmpty) return true;
    final hand = state.playerHands[player] ?? [];
    return hand.any((tile) => canPlayTile(state, tile));
  }

  static DominoGameState playTile(DominoGameState state, int player, DominoTile tile, bool playOnLeft) {
    if (state.currentTurnPlayer != player || state.winner != null) return state;

    final hand = state.playerHands[player] ?? [];
    if (!hand.contains(tile)) return state;

    List<DominoTile> newBoard = List.from(state.board);
    int? newLeft = state.leftEnd;
    int? newRight = state.rightEnd;

    if (newBoard.isEmpty) {
      newBoard.add(tile);
      newLeft = tile.left;
      newRight = tile.right;
    } else {
      if (playOnLeft) {
        if (tile.right == newLeft) {
          newBoard.insert(0, tile);
          newLeft = tile.left;
        } else if (tile.left == newLeft) {
          // Flip tile
          newBoard.insert(0, DominoTile(id: tile.id, left: tile.right, right: tile.left));
          newLeft = tile.right;
        } else {
          return state;
        }
      } else {
        if (tile.left == newRight) {
          newBoard.add(tile);
          newRight = tile.right;
        } else if (tile.right == newRight) {
          newBoard.add(DominoTile(id: tile.id, left: tile.right, right: tile.left));
          newRight = tile.left;
        } else {
          return state;
        }
      }
    }

    final updatedHands = Map<int, List<DominoTile>>.from(state.playerHands);
    updatedHands[player] = hand.where((t) => t.id != tile.id).toList();

    // Check win condition
    int? winner = updatedHands[player]!.isEmpty ? player : null;

    int nextPlayer = (state.currentTurnPlayer + 1) % state.playerHands.length;

    return state.copyWith(
      board: newBoard,
      playerHands: updatedHands,
      currentTurnPlayer: nextPlayer,
      leftEnd: newLeft,
      rightEnd: newRight,
      consecutivePasses: 0,
      winner: winner,
    );
  }

  static DominoGameState passTurn(DominoGameState state, int player, int totalPlayers) {
    if (state.currentTurnPlayer != player || hasAnyValidMove(state, player)) {
      return state;
    }

    int newPasses = state.consecutivePasses + 1;
    int nextPlayer = (state.currentTurnPlayer + 1) % totalPlayers;

    // Check block / deadlock condition
    int? winner = state.winner;
    if (newPasses >= totalPlayers) {
      // Game blocked: determine winner by lowest total pip count
      int minPips = 999;
      int lowestPlayer = 0;
      state.playerHands.forEach((p, hand) {
        int pips = hand.fold(0, (sum, t) => sum + t.totalValue);
        if (pips < minPips) {
          minPips = pips;
          lowestPlayer = p;
        }
      });
      winner = lowestPlayer;
    }

    return state.copyWith(
      currentTurnPlayer: nextPlayer,
      consecutivePasses: newPasses,
      winner: winner,
    );
  }
}
