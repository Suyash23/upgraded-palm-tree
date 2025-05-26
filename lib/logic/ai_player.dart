// In lib/logic/ai_player.dart
import 'dart:math';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'game_state.dart';
import 'ai_move.dart';
import 'ai_difficulty.dart'; // Import the enum

class AIPlayer {
  final Random _random = Random();

  AIMove? getAIMove(GameState gameState) {
    // Debug print for selected difficulty
    if (kDebugMode) {
      // print("AIPlayer:getAIMove called. Selected difficulty: ${gameState.selectedAIDifficulty}"); // Original simpler print
      print("[AIPlayer.getAIMove] Entered. Difficulty: ${gameState.selectedAIDifficulty}, Current Player: ${gameState.currentPlayer}");
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
      print("[AIPlayer._getHardMove] Entered, will delegate.");
    }
    return _getMediumMove(gameState);
  }

  AIMove? _getUnfairMove(GameState gameState) {
    if (kDebugMode) {
      print("[AIPlayer._getUnfairMove] Entered, will delegate.");
    }
    return _getHardMove(gameState);
  }

  // Helper method to get all valid moves
  List<AIMove> _getAllValidMoves(GameState gameState) {
    if (kDebugMode) {
      print("[AIPlayer._getAllValidMoves] Entered. Game Active: ${gameState.gameActive}, Current Player: ${gameState.currentPlayer}, Active MiniBoard: ${gameState.activeMiniBoardIndex}");
    }
    if (!gameState.gameActive || gameState.currentPlayer == 'X') { // Assuming AI is 'O'
        return []; // Not AI's turn or game is over
    }
    List<AIMove> validMoves = [];
    List<int> playableMiniBoardIndices = [];

    if (gameState.activeMiniBoardIndex != null) {
        // AI is forced to play in a specific mini-board.
        if (gameState.superBoardState[gameState.activeMiniBoardIndex!] == null) {
            playableMiniBoardIndices.add(gameState.activeMiniBoardIndex!);
        } else {
            // This state implies a logical inconsistency or a scenario where AI is forced to a decided board.
            // For robustness, if forced to a decided board, the AI should be able to play in any *other* undecided board.
            // This behavior might need refinement based on game rules for such edge cases.
            // For now, if the forced board is decided, let it look for other options.
            // If no other options, validMoves will remain empty, and AI won't move.
            for (int i = 0; i < 9; i++) {
                if (gameState.superBoardState[i] == null) {
                    playableMiniBoardIndices.add(i);
                }
            }
        }
    } else {
        // Free choice: can play in any mini-board that is not yet won or drawn
        for (int i = 0; i < 9; i++) {
            if (gameState.superBoardState[i] == null) {
                playableMiniBoardIndices.add(i);
            }
        }
    }
    if (kDebugMode) {
      print("[AIPlayer._getAllValidMoves] Playable MiniBoard Indices: $playableMiniBoardIndices");
    }

    if (playableMiniBoardIndices.isEmpty) {
        return []; 
    }

    for (int miniBoardIdx in playableMiniBoardIndices) {
        // This check is slightly redundant if playableMiniBoardIndices are correctly filtered,
        // but good for safety.
        if (gameState.superBoardState[miniBoardIdx] == null) { 
            for (int cellIdx = 0; cellIdx < 9; cellIdx++) {
                if (gameState.miniBoardStates[miniBoardIdx][cellIdx] == null) {
                    validMoves.add(AIMove(miniBoardIdx, cellIdx));
                }
            }
        }
    }
    if (kDebugMode) {
      print("[AIPlayer._getAllValidMoves] Found ${validMoves.length} valid moves.");
    }
    return validMoves;
  }

  // Helper method for _getMediumMove and potentially others
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
