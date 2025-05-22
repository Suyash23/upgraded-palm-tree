// In lib/logic/ai_player.dart
import 'dart:math';
import 'game_state.dart'; // Assuming GameState and GameMode are here
import 'ai_move.dart';    // Import the AIMove class

class AIPlayer {
  final Random _random = Random(); // Made final as it's initialized once

  AIMove? getRandomMove(GameState gameState) {
    if (!gameState.gameActive || gameState.currentPlayer == 'X') { // Assuming AI is 'O'
      return null; // Not AI's turn or game is over
    }

    List<AIMove> validMoves = [];
    List<int> playableMiniBoardIndices = [];

    if (gameState.activeMiniBoardIndex != null) {
      // AI is forced to play in a specific mini-board.
      // We must check if this board is not already decided (won/drawn).
      // If GameState.makeMove correctly sets activeMiniBoardIndex to null when sending to a decided board,
      // then this check (superBoardState[gameState.activeMiniBoardIndex!] == null) is crucial.
      if (gameState.superBoardState[gameState.activeMiniBoardIndex!] == null) {
        playableMiniBoardIndices.add(gameState.activeMiniBoardIndex!);
      } else {
        // This state implies a logical inconsistency: AI is forced to a board that's already decided.
        // GameState.makeMove should have set activeMiniBoardIndex to null.
        // For robustness, if this happens, AI should be allowed to play anywhere valid.
        // However, the prompt's GameState.makeMove for Step 4 handles this by setting activeMiniBoardIndex to null.
        // So, if activeMiniBoardIndex is NOT NULL here, it IS the target and SHOULD BE playable.
        // If it's not playable (already decided), it's a bug in how activeMiniBoardIndex was set.
        // For now, adhering to the logic that if activeMiniBoardIndex is not null, it's the target:
        playableMiniBoardIndices.add(gameState.activeMiniBoardIndex!);
      }
    } else {
      // Free choice: can play in any mini-board that is not yet won or drawn
      for (int i = 0; i < 9; i++) {
        if (gameState.superBoardState[i] == null) {
          playableMiniBoardIndices.add(i);
        }
      }
    }

    if (playableMiniBoardIndices.isEmpty) {
      // This could happen if all playable boards are full, but game isn't over.
      // Or if forced to a full board (which should ideally be marked DRAW and handled by activeMiniBoardIndex becoming null).
      return null; 
    }

    for (int miniBoardIdx in playableMiniBoardIndices) {
      // Ensure we only consider boards that are not decided.
      // This is somewhat redundant if playableMiniBoardIndices is already filtered,
      // but provides safety, especially if the logic for activeMiniBoardIndex being non-null but decided is ever hit.
      if (gameState.superBoardState[miniBoardIdx] == null) { 
        for (int cellIdx = 0; cellIdx < 9; cellIdx++) {
          if (gameState.miniBoardStates[miniBoardIdx][cellIdx] == null) {
            validMoves.add(AIMove(miniBoardIdx, cellIdx));
          }
        }
      }
    }

    if (validMoves.isEmpty) {
      return null; 
    }

    return validMoves[_random.nextInt(validMoves.length)];
  }
}
