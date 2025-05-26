// In lib/logic/ai_player.dart
import 'dart:math';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'game_state.dart';
import 'ai_move.dart';
import 'ai_difficulty.dart'; // Import the enum

class AIPlayer {
  final Random _random = Random();
  static const int _hardMoveMaxDepth = 3; // Max depth for Hard Minimax
  static const int _unfairMoveMaxDepth = 4; // Max depth for Unfair Minimax

  AIMove? getAIMove(GameState gameState) {
    // Debug print for selected difficulty
    if (kDebugMode) {
      print("[AIPlayer.getAIMove] Entered. Difficulty: ${gameState.selectedAIDifficulty}, Current Player: ${gameState.currentPlayer}");
    }

    // Ensure AI is 'O' for hardcoded logic, or make it dynamic
    if (gameState.currentPlayer != 'O') {
      if (kDebugMode) {
        print("[AIPlayer.getAIMove] AI is not the current player ('O'). Returning null.");
      }
      // This case should ideally not be reached if GameState.triggerAIMove is called correctly.
      return null; 
    }

    switch (gameState.selectedAIDifficulty) {
      case AIDifficulty.easy:
        return _getEasyMove(gameState);
      case AIDifficulty.medium:
        return _getMediumMove(gameState);
      case AIDifficulty.hard:
        return _getHardMove(gameState);
      case AIDifficulty.unfair:
        return _getUnfairMove(gameState);
      default: // Should not happen
        if (kDebugMode) {
          print("AIPlayer:getAIMove - Warning: Unknown difficulty, defaulting to Easy.");
        }
        return _getEasyMove(gameState); // Fallback to easy
    }
  }

  // --- STUB Private Methods ---

  AIMove? _getEasyMove(GameState gameState) {
    if (kDebugMode) {
      print("[AIPlayer._getEasyMove] Entered.");
    }
    List<AIMove> validMoves = _getAllValidMoves(gameState);
    if (validMoves.isEmpty) {
      if (kDebugMode) {
        print("[AIPlayer._getEasyMove] No valid moves to pick from.");
      }
      return null;
    }
    if (kDebugMode) {
      print("[AIPlayer._getEasyMove] About to pick a random move from ${validMoves.length} options.");
    }
    return validMoves[_random.nextInt(validMoves.length)];
  }

  AIMove? _getMediumMove(GameState gameState) {
    if (kDebugMode) {
      print("[AIPlayer._getMediumMove] Entered.");
    }
    List<AIMove> validMoves = _getAllValidMoves(gameState);
    if (validMoves.isEmpty) return null;

    String aiPlayer = gameState.currentPlayer; // Should be 'O' if it's AI's turn
    String opponentPlayer = (aiPlayer == 'X') ? 'O' : 'X';

    // 1. Check for AI's winning move
    for (AIMove move in validMoves) {
      if (_checkPotentialWin(gameState.miniBoardStates[move.miniBoardIndex], move.cellIndex, aiPlayer)) {
        if (kDebugMode) {
          print("[AIPlayer._getMediumMove] Found winning move for AI at ${move.miniBoardIndex}-${move.cellIndex}");
        }
        return move;
      }
    }

    // 2. Block opponent's winning move
    for (AIMove move in validMoves) { // 'move' is a cell AI can play in
      if (_checkPotentialWin(gameState.miniBoardStates[move.miniBoardIndex], move.cellIndex, opponentPlayer)) {
        if (kDebugMode) {
          print("[AIPlayer._getMediumMove] Found blocking move for opponent at ${move.miniBoardIndex}-${move.cellIndex}");
        }
        return move; // AI plays in the cell where opponent would have won
      }
    }

    // 3. Fallback to Random Move
    if (kDebugMode) {
      print("[AIPlayer._getMediumMove] No win or block, resorting to random move from ${validMoves.length} options.");
    }
    return validMoves[_random.nextInt(validMoves.length)];
  }

  AIMove? _getHardMove(GameState gameState) {
    if (kDebugMode) {
      print("[AIPlayer._getHardMove] Entered. Current player for gameState: ${gameState.currentPlayer}");
    }

    String aiPlayer = 'O'; // Assuming AI is always 'O' as per current game logic
    String opponentPlayer = 'X';
    List<AIMove> validMoves = _getAllValidMoves(gameState);

    if (validMoves.isEmpty) {
      if (kDebugMode) {
        print("[AIPlayer._getHardMove] No valid moves available.");
      }
      return null;
    }

    AIMove? bestMove;
    double bestScore = -double.infinity;

    if (kDebugMode) {
      print("[AIPlayer._getHardMove] Evaluating ${validMoves.length} moves.");
    }

    for (AIMove move in validMoves) {
      GameState nextState = gameState.copyWith();
      // The AI makes a move. The player in nextState will be switched by applyMoveForSimulation.
      nextState.applyMoveForSimulation(move.miniBoardIndex, move.cellIndex, aiPlayer); 
      
      if (kDebugMode) {
        // print("[AIPlayer._getHardMove] Simulating move: ${move.miniBoardIndex}-${move.cellIndex}. Player for next minimax call: ${nextState.currentPlayer}");
      }

      // Now it's opponent's turn in nextState, so isMaximizingPlayer is false.
      double score = _minimax(nextState, 0, false, aiPlayer, opponentPlayer, _hardMoveMaxDepth);
      
      if (kDebugMode) {
        // print("[AIPlayer._getHardMove] Move ${move.miniBoardIndex}-${move.cellIndex} scored: $score");
      }

      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    if (kDebugMode) {
      if (bestMove != null) {
        print("[AIPlayer._getHardMove] Best move: ${bestMove.miniBoardIndex}-${bestMove.cellIndex} with score: $bestScore");
      } else {
        print("[AIPlayer._getHardMove] No best move found, returning null (or first valid move as fallback).");
        // Fallback, though ideally Minimax should always guide to a choice if moves exist.
        return validMoves.isNotEmpty ? validMoves[_random.nextInt(validMoves.length)] : null;
      }
    }
    return bestMove;
  }

  double _minimax(GameState gameState, int depth, bool isMaximizingPlayer, String aiPlayer, String opponentPlayer, int maxDepth) {
    String? winner = gameState.getOverallWinner();
    if (winner != null) {
      if (winner == aiPlayer) return 1000 - depth.toDouble(); // Prioritize faster wins
      if (winner == opponentPlayer) return -1000 + depth.toDouble(); // Prioritize delaying losses
      if (winner == 'DRAW') return 0;
    }

    if (!gameState.isGameActive()) { // Should be covered by winner check, but as a safeguard
        if (kDebugMode) print("[AIPlayer._minimax] Game not active but no winner, might be a full board draw not caught by overallWinner logic for superboard.");
        return 0; // Or evaluate board if it's a draw due to no moves
    }
    
    if (depth >= maxDepth) { // Use the passed maxDepth parameter
      return _evaluateBoard(gameState, aiPlayer, opponentPlayer);
    }

    List<AIMove> validMoves = _getAllValidMoves(gameState);
    if (validMoves.isEmpty) {
      // If no moves and game not over, it's a draw for this path.
      // This can happen if a player is forced into a full mini-board, and that move doesn't end the game,
      // and the next board to play on is also full/decided, leading to no valid moves.
      // Or if the whole super-board is full without an overall winner.
      // The _checkOverallWinner should ideally return 'DRAW' if the board is full and no one won.
      // If _getAllValidMoves is empty and game is active, it implies a drawn state for this path.
      if (kDebugMode) print("[AIPlayer._minimax] No valid moves at depth $depth for player ${gameState.currentPlayer}. Evaluating as draw for this path.");
      return 0; 
    }

    if (isMaximizingPlayer) { // AI's turn
      double bestScore = -double.infinity;
      for (AIMove move in validMoves) {
        GameState nextState = gameState.copyWith();
        nextState.applyMoveForSimulation(move.miniBoardIndex, move.cellIndex, aiPlayer);
        double score = _minimax(nextState, depth + 1, false, aiPlayer, opponentPlayer, maxDepth);
        bestScore = max(bestScore, score);
      }
      return bestScore;
    } else { // Opponent's turn
      double bestScore = double.infinity;
      for (AIMove move in validMoves) {
        GameState nextState = gameState.copyWith();
        nextState.applyMoveForSimulation(move.miniBoardIndex, move.cellIndex, opponentPlayer);
        double score = _minimax(nextState, depth + 1, true, aiPlayer, opponentPlayer, maxDepth);
        bestScore = min(bestScore, score);
      }
      return bestScore;
    }
  }

  double _evaluateBoard(GameState gameState, String aiPlayer, String opponentPlayer) {
    double score = 0;

    // 1. Super-board evaluation (mini-board wins)
    for (int i = 0; i < 9; i++) {
      if (gameState.superBoardState[i] == aiPlayer) {
        score += 25; // Significant bonus for winning a mini-board
      } else if (gameState.superBoardState[i] == opponentPlayer) {
        score -= 25; // Significant penalty
      } else if (gameState.superBoardState[i] == 'DRAW') {
        // score -= 1; // Small penalty for a drawn mini-board that AI didn't win
      }
    }

    // 2. Evaluate individual mini-boards for potential lines (more complex)
    // This is a simplified version: count cells in non-decided mini-boards
    for (int mbIdx = 0; mbIdx < 9; mbIdx++) {
        if (gameState.superBoardState[mbIdx] == null) { // Only evaluate undecided mini-boards
            List<String?> miniBoard = gameState.miniBoardStates[mbIdx];
            // Simple heuristic: count number of AI pieces vs Opponent pieces
            // More advanced: count 2-in-a-rows, center control etc.
            int aiCells = 0;
            int opponentCells = 0;
            for(int cellIdx = 0; cellIdx < 9; cellIdx++){
                if(miniBoard[cellIdx] == aiPlayer) aiCells++;
                else if(miniBoard[cellIdx] == opponentPlayer) opponentCells++;
            }
            score += (aiCells * 0.5);   // Small bonus for player's cells
            score -= (opponentCells * 0.5); // Small penalty for opponent's cells

            // Check for potential wins in this mini-board (lines of 2)
            // This uses _checkPotentialWin, which checks if placing a piece *would* win.
            // We want to count open lines of 2.
            score += _countPotentialWins(miniBoard, aiPlayer) * 3;
            score -= _countPotentialWins(miniBoard, opponentPlayer) * 3;
        }
    }
    
    // 3. Consider activeMiniBoardIndex: is it favorable?
    // If activeMiniBoardIndex is set and that board is good for AI, that's a plus.
    // If it's bad, that's a minus. This is harder to quantify simply.

    if (kDebugMode && (score > 500 || score < -500) ) { // Print if score seems too high for heuristic
       print("[AIPlayer._evaluateBoard] Warning: Unusual heuristic score: $score for player $aiPlayer. Depth limit reached. SuperBoard: ${gameState.superBoardState}");
    }
    return score;
  }

  // Helper for _evaluateBoard to count potential winning lines (2 in a row with an empty spot)
  int _countPotentialWins(List<String?> boardData, String player) {
    int count = 0;
    const List<List<int>> winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
      [0, 4, 8], [2, 4, 6]             // Diagonals
    ];

    for (var pattern in winPatterns) {
      int playerCount = 0;
      int emptyCount = 0;
      for (var cellIndex in pattern) {
        if (boardData[cellIndex] == player) {
          playerCount++;
        } else if (boardData[cellIndex] == null) {
          emptyCount++;
        }
      }
      if (playerCount == 2 && emptyCount == 1) {
        count++;
      }
    }
    return count;
  }


  AIMove? _getUnfairMove(GameState gameState) {
    if (kDebugMode) {
      print("[AIPlayer._getUnfairMove] Entered, will delegate.");
    }
    return _getHardMove(gameState);
  }

  // Helper method to get all valid moves
  List<AIMove> _getAllValidMoves(GameState gameState) {
    // This method needs to respect the gameState's currentPlayer for its logic.
    // The Minimax algorithm will call this for both AI and simulated opponent turns.
    if (kDebugMode) {
      // print("[AIPlayer._getAllValidMoves] Entered. Game Active: ${gameState.isGameActive()}, Current Player: ${gameState.currentPlayer}, Active MiniBoard: ${gameState.activeMiniBoardIndex}, SuperBoard: ${gameState.superBoardState}");
    }

    if (!gameState.isGameActive()) {
        if (kDebugMode) print("[AIPlayer._getAllValidMoves] Game is not active. Returning empty list.");
        return [];
    }

    List<AIMove> validMoves = [];
    List<int> playableMiniBoardIndices = [];

    int? forcedBoard = gameState.activeMiniBoardIndex;

    if (forcedBoard != null && gameState.superBoardState[forcedBoard] == null) {
        // Forced to play in a specific, undecided mini-board.
        playableMiniBoardIndices.add(forcedBoard);
        if (kDebugMode) {
            // print("[AIPlayer._getAllValidMoves] Forced to play in mini-board: $forcedBoard");
        }
    } else {
        // Free choice: can play in any mini-board that is not yet won or drawn.
        // This also covers the case where forcedBoard is non-null but IS decided.
        if (kDebugMode) {
            // print("[AIPlayer._getAllValidMoves] Free choice or forced board $forcedBoard is already decided (${gameState.superBoardState[forcedBoard]})");
        }
        for (int i = 0; i < 9; i++) {
            if (gameState.superBoardState[i] == null) {
                playableMiniBoardIndices.add(i);
            }
        }
    }
    
    if (kDebugMode) {
    //   print("[AIPlayer._getAllValidMoves] Playable MiniBoard Indices for player ${gameState.currentPlayer}: $playableMiniBoardIndices");
    }

    if (playableMiniBoardIndices.isEmpty) {
        if (kDebugMode) print("[AIPlayer._getAllValidMoves] No playable mini-boards found. Returning empty list.");
        return []; 
    }

    for (int miniBoardIdx in playableMiniBoardIndices) {
        // Safety check (should be redundant if playableMiniBoardIndices is correctly filtered)
        if (gameState.superBoardState[miniBoardIdx] == null) { 
            for (int cellIdx = 0; cellIdx < 9; cellIdx++) {
                if (gameState.miniBoardStates[miniBoardIdx][cellIdx] == null) {
                    validMoves.add(AIMove(miniBoardIdx, cellIdx));
                }
            }
        }
    }

    if (kDebugMode) {
    //   print("[AIPlayer._getAllValidMoves] Found ${validMoves.length} valid moves for player ${gameState.currentPlayer}.");
    }
    return validMoves;
  }

  // Helper method for _getMediumMove and potentially others
  // This original _checkPotentialWin is fine for its original purpose in medium AI.
  // For the heuristic, _countPotentialWins is more suitable.
  bool _checkPotentialWin(List<String?> currentBoardData, int cellIdx, String player) {
    if (currentBoardData[cellIdx] != null) return false; // Cell already occupied

    List<String?> tempBoard = List.from(currentBoardData);
    tempBoard[cellIdx] = player;

    const List<List<int>> winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
      [0, 4, 8], [2, 4, 6]             // Diagonals
    ];

    for (var pattern in winPatterns) {
      String? p1 = tempBoard[pattern[0]];
      String? p2 = tempBoard[pattern[1]];
      String? p3 = tempBoard[pattern[2]];
      if (p1 == player && p1 == p2 && p1 == p3) {
        return true; // Player wins with this move
      }
    }
    return false; // No win with this move
  }
}
