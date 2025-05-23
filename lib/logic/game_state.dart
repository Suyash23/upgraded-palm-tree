import 'package:flutter/foundation.dart'; // Required for ChangeNotifier
import 'ai_player.dart'; 
import 'ai_move.dart';   

enum GameMode {
  humanVsHuman,
  humanVsAI
}

class GameState extends ChangeNotifier {
  final AIPlayer _aiPlayer = AIPlayer(); 
  List<List<String?>> miniBoardStates;
  String currentPlayer;
  int? activeMiniBoardIndex;
  bool gameActive;
  List<String?> superBoardState; 
  String? overallWinner; 
  GameMode currentGameMode; 
  bool isAITurnInProgress = false; // New property

  GameState()
      : miniBoardStates = List.generate(9, (_) => List.generate(9, (_) => null)),
        superBoardState = List.generate(9, (_) => null), 
        currentPlayer = 'X',
        activeMiniBoardIndex = null, 
        gameActive = true,
        overallWinner = null,
        currentGameMode = GameMode.humanVsHuman,
        isAITurnInProgress = false; // Initialize

  void resetGame() {
    miniBoardStates = List.generate(9, (_) => List.generate(9, (_) => null));
    superBoardState = List.generate(9, (_) => null); 
    currentPlayer = 'X';
    activeMiniBoardIndex = null;
    gameActive = true;
    overallWinner = null; 
    isAITurnInProgress = false; // Reset this flag
    // currentGameMode is NOT reset here
    notifyListeners(); 
  }

  void setGameMode(GameMode mode) {
    currentGameMode = mode;
  }

  // Private helper method to apply a validated move
  void _applyValidatedMove(int miniBoardIdx, int cellIdx) {
    String playerMakingThisMove = currentPlayer;
    miniBoardStates[miniBoardIdx][cellIdx] = playerMakingThisMove;

    if (superBoardState[miniBoardIdx] == null) {
      String? miniBoardResult = _checkMiniBoardWinner(miniBoardIdx);
      if (miniBoardResult != null) {
        superBoardState[miniBoardIdx] = miniBoardResult;
        if (kDebugMode) { print("Mini-board $miniBoardIdx result: $miniBoardResult by $playerMakingThisMove"); }

        String? gameResult = _checkOverallWinner();
        if (gameResult != null) {
          overallWinner = gameResult;
          gameActive = false;
          if (kDebugMode) { print("Overall game result: $overallWinner. Game over."); }
        }
      }
    }

    if (gameActive) {
      currentPlayer = (playerMakingThisMove == 'X') ? 'O' : 'X'; // Switch to next player
      if (superBoardState[cellIdx] == null) {
        activeMiniBoardIndex = cellIdx;
      } else {
        activeMiniBoardIndex = null;
      }
    } else {
      activeMiniBoardIndex = null; // Game ended
    }

    if (kDebugMode) {
      print("Move applied by $playerMakingThisMove in board $miniBoardIdx, cell $cellIdx. Next player: $currentPlayer. Next forced: $activeMiniBoardIndex. SuperBoard: $superBoardState. Overall: $overallWinner");
    }
    // notifyListeners() will be called by the public makeMove method
  }

  // Modified public makeMove method
  Future<bool> makeMove(int miniBoardIdx, int cellIdx) async { 
    // --- Start: Initial Validation (remains same) ---
    if (!gameActive) { 
      if (kDebugMode) { print("Game is not active. Overall winner: $overallWinner"); }
      return false; 
    }
    if (miniBoardStates[miniBoardIdx][cellIdx] != null) { 
      if (kDebugMode) { print("Cell $miniBoardIdx-$cellIdx is already occupied by ${miniBoardStates[miniBoardIdx][cellIdx]}."); }
      return false; 
    }
    bool chosenBoardIsDecided = superBoardState[miniBoardIdx] != null;
    if (chosenBoardIsDecided) { 
      if (kDebugMode) { print("Invalid move: Chosen mini-board $miniBoardIdx is already decided with status: ${superBoardState[miniBoardIdx]}."); }
      return false; 
    }
    if (activeMiniBoardIndex != null) { 
      if (miniBoardIdx != activeMiniBoardIndex) {
        if (kDebugMode) { print("Invalid move: Must play in active board $activeMiniBoardIndex, but tried to play in $miniBoardIdx."); }
        return false;
      }
      if (superBoardState[activeMiniBoardIndex!] != null) {
           if (kDebugMode) { print("Logical error: activeMiniBoardIndex ($activeMiniBoardIndex) is set, but that board is already decided (${superBoardState[activeMiniBoardIndex!]}). This shouldn't happen."); }
          return false; 
      }
    }
    // --- End: Initial Validation ---

    // Apply the human player's move
    _applyValidatedMove(miniBoardIdx, cellIdx);

    // Check for AI turn if game is HumanVsAI, game is still active, and it's now AI's turn
    if (currentGameMode == GameMode.humanVsAI && gameActive && currentPlayer == 'O') { // Assuming AI is 'O'
      // Optional: Add a flag for "AI is thinking" and notify listeners
      // isAITurnInProgress = true; notifyListeners();
      
      await Future.delayed(const Duration(milliseconds: 750)); // e.g., 0.75 second delay

      AIMove? aiMove = _aiPlayer.getRandomMove(this); 
      
      if (aiMove != null) {
        _applyValidatedMove(aiMove.miniBoardIndex, aiMove.cellIndex);
      } else {
        if (kDebugMode) { print("AI could not find a valid move."); }
      }
      // isAITurnInProgress = false; // Reset flag
    }

    notifyListeners(); 
    return true; 
  }

  String? getCellState(int miniBoardIdx, int cellIdx) {
    return miniBoardStates[miniBoardIdx][cellIdx];
  }

  String? _checkOverallWinner() {
    const List<List<int>> winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6]
    ];
    for (var pattern in winPatterns) {
      String? p1 = superBoardState[pattern[0]];
      String? p2 = superBoardState[pattern[1]];
      String? p3 = superBoardState[pattern[2]];
      if (p1 != null && p1 != 'DRAW' && p1 == p2 && p1 == p3) {
        return p1; 
      }
    }
    if (superBoardState.every((status) => status != null)) {
      return 'DRAW'; 
    }
    return null; 
  }

  String? _checkMiniBoardWinner(int miniBoardIndex) {
    List<String?> board = miniBoardStates[miniBoardIndex];
    const List<List<int>> winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6]
    ];
    for (var pattern in winPatterns) {
      String? p1 = board[pattern[0]];
      String? p2 = board[pattern[1]];
      String? p3 = board[pattern[2]];
      if (p1 != null && p1 == p2 && p1 == p3) {
        return p1; 
      }
    }
    if (board.every((cell) => cell != null)) {
      return 'DRAW';
    }
    return null; 
  }
}
