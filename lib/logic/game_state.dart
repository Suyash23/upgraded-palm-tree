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

  // New property: Tracks the winner or draw status of each of the 9 mini-boards
  List<String?> superBoardState; 
  String? overallWinner; // New property: null, 'X', 'O', or 'DRAW' for the whole game

  GameState()
      : miniBoardStates = List.generate(9, (_) => List.generate(9, (_) => null)),
        superBoardState = List.generate(9, (_) => null), 
        currentPlayer = 'X',
        activeMiniBoardIndex = null, 
        gameActive = true,
        overallWinner = null; // Initialize here

  // Basic reset method for now
  void resetGame() {
    miniBoardStates = List.generate(9, (_) => List.generate(9, (_) => null));
    superBoardState = List.generate(9, (_) => null); 
    currentPlayer = 'X';
    activeMiniBoardIndex = null;
    gameActive = true;
    overallWinner = null; // Reset here
    notifyListeners(); 
  }

// In class GameState within lib/logic/game_state.dart

bool makeMove(int miniBoardIdx, int cellIdx) { // Changed return type to bool
  // Validate the move
  if (!gameActive) {
    if (kDebugMode) { print("Game is not active. Overall winner: $overallWinner"); }
    return false; // Game is over
  }
  if (miniBoardStates[miniBoardIdx][cellIdx] != null) {
    if (kDebugMode) { print("Cell $miniBoardIdx-$cellIdx is already occupied by ${miniBoardStates[miniBoardIdx][cellIdx]}."); }
    return false; // Cell is not empty
  }

  // --- Start: Active Mini-Board Validation (Finalized for Step 4) ---
  bool chosenBoardIsDecided = superBoardState[miniBoardIdx] != null;

  if (chosenBoardIsDecided) {
    if (kDebugMode) { print("Invalid move: Chosen mini-board $miniBoardIdx is already decided with status: ${superBoardState[miniBoardIdx]}."); }
    return false;
  }

  if (activeMiniBoardIndex != null) { // Player is forced to play in a specific mini-board
    if (miniBoardIdx != activeMiniBoardIndex) {
      if (kDebugMode) { print("Invalid move: Must play in active board $activeMiniBoardIndex, but tried to play in $miniBoardIdx."); }
      return false;
    }
    if (superBoardState[activeMiniBoardIndex!] != null) {
         if (kDebugMode) { print("Logical error: activeMiniBoardIndex ($activeMiniBoardIndex) is set, but that board is already decided (${superBoardState[activeMiniBoardIndex!]}). This shouldn't happen."); }
        return false; 
    }
  } 
  // --- End: Active Mini-Board Validation ---

  String playerMakingMove = currentPlayer; 
  miniBoardStates[miniBoardIdx][cellIdx] = playerMakingMove;

  if (superBoardState[miniBoardIdx] == null) { 
    String? miniBoardResult = _checkMiniBoardWinner(miniBoardIdx);
    if (miniBoardResult != null) {
      superBoardState[miniBoardIdx] = miniBoardResult;
      if (kDebugMode) { print("Mini-board $miniBoardIdx result: $miniBoardResult by $playerMakingMove"); }

      String? gameResult = _checkOverallWinner();
      if (gameResult != null) {
        overallWinner = gameResult;
        gameActive = false; 
        if (kDebugMode) { print("Overall game result: $overallWinner. Game over."); }
      }
    }
  }

  if (gameActive) {
    currentPlayer = (playerMakingMove == 'X') ? 'O' : 'X';
    if (superBoardState[cellIdx] == null) { 
      activeMiniBoardIndex = cellIdx; 
    } else { 
      activeMiniBoardIndex = null; 
    }
  } else {
    activeMiniBoardIndex = null; 
  }
  
  if (kDebugMode) {
    print("Move by $playerMakingMove in board $miniBoardIdx, cell $cellIdx. Next player: $currentPlayer. Next forced: $activeMiniBoardIndex. SuperBoard: $superBoardState. Overall: $overallWinner");
  }

  notifyListeners();
  return true; // Move was successful
}

  // Helper method to get cell state
  String? getCellState(int miniBoardIdx, int cellIdx) {
    return miniBoardStates[miniBoardIdx][cellIdx];
  }

  String? _checkOverallWinner() {
    // Use superBoardState to check for an overall win or draw
    const List<List<int>> winPatterns = [
      // Rows
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      // Columns
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      // Diagonals
      [0, 4, 8], [2, 4, 6]
    ];

    for (var pattern in winPatterns) {
      String? p1 = superBoardState[pattern[0]];
      String? p2 = superBoardState[pattern[1]];
      String? p3 = superBoardState[pattern[2]];

      // Important: Drawn mini-boards ('DRAW') do not count towards a win line
      if (p1 != null && p1 != 'DRAW' && p1 == p2 && p1 == p3) {
        return p1; // Return 'X' or 'O' for overall winner
      }
    }

    // Check for overall draw: if no winner and all mini-boards are decided (not null)
    if (superBoardState.every((status) => status != null)) {
      return 'DRAW'; // Overall game is a draw
    }

    return null; // No overall winner, game continues
  }

  // Private helper method to check for a winner or draw in a specific mini-board
  String? _checkMiniBoardWinner(int miniBoardIndex) {
    List<String?> board = miniBoardStates[miniBoardIndex];

    // Define winning combinations (indices in the 1D list of 9 cells)
    const List<List<int>> winPatterns = [
      // Rows
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      // Columns
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      // Diagonals
      [0, 4, 8], [2, 4, 6]
    ];

    for (var pattern in winPatterns) {
      String? p1 = board[pattern[0]];
      String? p2 = board[pattern[1]];
      String? p3 = board[pattern[2]];

      if (p1 != null && p1 == p2 && p1 == p3) {
        return p1; // Return 'X' or 'O'
      }
    }

    // Check for draw (if no winner and board is full)
    if (board.every((cell) => cell != null)) {
      return 'DRAW';
    }

    return null; // No winner, not a draw, game on this board continues
  }
}
