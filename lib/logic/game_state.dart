import 'package:flutter/foundation.dart'; // Required for ChangeNotifier

class GameState extends ChangeNotifier {
  // Represents the 9 mini-boards, each with 9 cells.
  // Each cell can be null (empty), 'X', or 'O'.
  List<List<String?>> miniBoardStates;

  // Current player: 'X' or 'O'
  String currentPlayer;

  // Index of the mini-board (0-8) where the current player must play.
  // null means the player can choose any valid mini-board (e.g., first move, or sent to a completed board).
  int? activeMiniBoardIndex;

  // Flag indicating if the game is still ongoing.
  bool gameActive;

  // TODO: Later, add superBoardState to track winners of mini-boards:
  // List<String?> superBoardState; // null, 'X', 'O', or 'DRAW' for each mini-board

  GameState()
      : miniBoardStates = List.generate(9, (_) => List.generate(9, (_) => null)),
        currentPlayer = 'X',
        activeMiniBoardIndex = null, // First player can play anywhere
        gameActive = true {
    // Potential future initialization for superBoardState:
    // superBoardState = List.generate(9, (_) => null);
  }

  // Basic reset method for now
  void resetGame() {
    miniBoardStates = List.generate(9, (_) => List.generate(9, (_) => null));
    currentPlayer = 'X';
    activeMiniBoardIndex = null;
    gameActive = true;
    // superBoardState = List.generate(9, (_) => null); // Reset later
    notifyListeners(); // Notify listeners if using ChangeNotifier
  }

  // Placeholder for makeMove logic, to be expanded in a later step
  void makeMove(int miniBoardIdx, int cellIdx) {
    // Validate the move
    if (!gameActive) {
      if (kDebugMode) {
        print("Game is not active.");
      }
      return; // Game is over
    }

    if (miniBoardStates[miniBoardIdx][cellIdx] != null) {
      if (kDebugMode) {
        print("Cell is already occupied.");
      }
      return; // Cell is not empty
    }

    if (activeMiniBoardIndex != null && activeMiniBoardIndex != miniBoardIdx) {
      // This check needs to be more nuanced: if activeMiniBoardIndex points to a COMPLETED board,
      // then the player should be able to play in any OTHER non-completed board.
      // For now, this simpler check is fine until mini-board win status is tracked.
      // TODO: Refine this when superBoardState is available.
      // Example refinement:
      // if (superBoardState[activeMiniBoardIndex] == null && activeMiniBoardIndex != miniBoardIdx) {
      //   // If the forced board is NOT completed and player plays elsewhere
      //   if (kDebugMode) {
      //     print("Move is not in the active mini-board. Expected: $activeMiniBoardIndex, Got: $miniBoardIdx");
      //   }
      //   return;
      // } else if (superBoardState[activeMiniBoardIndex] != null && superBoardState[miniBoardIdx] != null) {
      //   // If forced board IS completed, but the chosen board IS ALSO completed
      //    if (kDebugMode) {
      //     print("Forced board $activeMiniBoardIndex is complete, but chosen board $miniBoardIdx is also complete.");
      //   }
      //   return;
      // }
       if (kDebugMode) {
        print("Move is not in the active mini-board. Expected: $activeMiniBoardIndex, Got: $miniBoardIdx");
      }
      return; // Not the correct mini-board (simplistic check for now)
    }

    // --- If validations pass, make the move ---

    // Mark the cell
    miniBoardStates[miniBoardIdx][cellIdx] = currentPlayer;
    String previousPlayer = currentPlayer; // Store for logging

    // Switch player BEFORE determining next board, as next board depends on current player's move.
    currentPlayer = (currentPlayer == 'X') ? 'O' : 'X';
    
    // Determine the next active mini-board based on the cell just played
    // This is the core rule: the cell index (0-8) in the current mini-board
    // dictates which mini-board (0-8) the next player must play in.
    activeMiniBoardIndex = cellIdx; 
    
    // TODO (Future Steps):
    // 1. Check if miniBoardIdx was won or drawn by `previousPlayer`'s move.
    //    - Update `superBoardState[miniBoardIdx]`.
    // 2. If miniBoardIdx was won/drawn, check if this results in an overall game win/draw.
    //    - Update `gameActive` if the game ends.
    // 3. If the new `activeMiniBoardIndex` (which is `cellIdx`) points to a mini-board 
    //    that is already won/drawn (i.e., `superBoardState[activeMiniBoardIndex]` is not null),
    //    then set `activeMiniBoardIndex` to `null` (next player can play anywhere valid).

    if (kDebugMode) {
      print("Move made by $previousPlayer in board $miniBoardIdx, cell $cellIdx. Next player: $currentPlayer. Next board: $activeMiniBoardIndex");
    }

    notifyListeners(); // Notify UI to update
  }

  // Helper method to get cell state
  String? getCellState(int miniBoardIdx, int cellIdx) {
    return miniBoardStates[miniBoardIdx][cellIdx];
  }
}
