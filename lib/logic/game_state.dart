import 'package:flutter/foundation.dart'; // Required for ChangeNotifier
import 'ai_player.dart'; 
import 'ai_move.dart';   
import 'ai_difficulty.dart'; // Import the new enum

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
  AIDifficulty selectedAIDifficulty = AIDifficulty.medium; // New field for AI difficulty
  bool isAITurnInProgress = false; // New property

  GameState()
      : miniBoardStates = List.generate(9, (_) => List.generate(9, (_) => null)),
        selectedAIDifficulty = AIDifficulty.medium, // Initialize in constructor
        superBoardState = List.generate(9, (_) => null), 
        currentPlayer = 'X',
        activeMiniBoardIndex = null, 
        gameActive = true,
        overallWinner = null,
        currentGameMode = GameMode.humanVsHuman,
        isAITurnInProgress = false; // Initialize

  void resetGame() {
    if (kDebugMode) {
      print("[GameState.resetGame] Mode before reset logic: $currentGameMode");
    }
    miniBoardStates = List.generate(9, (_) => List.generate(9, (_) => null));
    superBoardState = List.generate(9, (_) => null); 
    currentPlayer = 'X';
    activeMiniBoardIndex = null;
    gameActive = true;
    overallWinner = null; 
    isAITurnInProgress = false; // Reset this flag
    // currentGameMode is NOT reset here
    // selectedAIDifficulty is NOT reset here
    notifyListeners(); 
    if (kDebugMode) {
      print("[GameState.resetGame] Mode after reset logic: $currentGameMode");
    }
  }

  void setGameMode(GameMode mode) {
    if (kDebugMode) {
      print("[GameState.setGameMode] Setting mode to $mode. Current mode was: $currentGameMode");
    }
    currentGameMode = mode;
    // Consider if resetting the game or SuperBoardKey is needed when game mode changes
    // during an active game. For now, just setting the mode.
  }

  void setAIDifficulty(AIDifficulty difficulty) {
    selectedAIDifficulty = difficulty;
    // Optional: notify if UI needs to react directly to this change.
    // Included for now as per subtask instructions.
    notifyListeners();
  }

  // Private helper method to apply a validated move
  // The duplicated version (taking 2 arguments) has been removed.
  // This is the correct version (taking 3 arguments).
  void _applyValidatedMove(int miniBoardIdx, int cellIdx, String player) {
    // String playerMakingThisMove = currentPlayer; // Changed: Use passed player
    miniBoardStates[miniBoardIdx][cellIdx] = player;

    if (superBoardState[miniBoardIdx] == null) {
      String? miniBoardResult = _checkMiniBoardWinner(miniBoardIdx);
      if (miniBoardResult != null) {
        superBoardState[miniBoardIdx] = miniBoardResult;
        if (kDebugMode) { print("Mini-board $miniBoardIdx result: $miniBoardResult by $player"); }

        String? gameResult = _checkOverallWinner();
        if (gameResult != null) {
          overallWinner = gameResult;
          gameActive = false;
          if (kDebugMode) { print("Overall game result: $overallWinner. Game over."); }
        }
      }
    }

    if (gameActive) {
      currentPlayer = (player == 'X') ? 'O' : 'X'; // Switch to next player
      if (superBoardState[cellIdx] == null) {
        activeMiniBoardIndex = cellIdx;
      } else {
        activeMiniBoardIndex = null;
      }
    } else {
      activeMiniBoardIndex = null; // Game ended
    }

    if (kDebugMode) {
      print("Move applied by $player in board $miniBoardIdx, cell $cellIdx. Next player: $currentPlayer. Next forced: $activeMiniBoardIndex. SuperBoard: $superBoardState. Overall: $overallWinner");
    }
    // notifyListeners() will be called by the public method that calls this
  }

  // Renamed and refactored makeMove
  Future<bool> _applyMoveInternal(int miniBoardIdx, int cellIdx, String player) async {
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

    // Apply the player's move
    _applyValidatedMove(miniBoardIdx, cellIdx, player);

    // AI turn handling logic has been removed from here.

    notifyListeners();
    return true;
  }

  // New public method for processing a player's move
  Future<void> processPlayerMove(int miniBoardIdx, int cellIdx) async {
    if (kDebugMode) {
      // It's useful to log who is the current player *before* the move is made.
      print("processPlayerMove called for board $miniBoardIdx, cell $cellIdx by player $currentPlayer.");
    }

    // 1. Determine Current (Human) Player
    String humanPlayer = currentPlayer; // Player making this move

    // 2. Apply Human Move
    // Note: _applyMoveInternal will call notifyListeners() itself.
    bool moveMade = await _applyMoveInternal(miniBoardIdx, cellIdx, humanPlayer);

    if (!moveMade) {
      // If the move was invalid (e.g., cell taken, wrong board) or if the game ended with this move,
      // _applyMoveInternal would have handled it (or returned false).
      // No further action needed here for an invalid move. If game ended, gameActive would be false.
      if (kDebugMode) {
        print("Human move was not successful or game ended. Exiting processPlayerMove.");
      }
      return; 
    }

    // 3. AI Turn Logic (Initial Implementation)
    // After a successful human move, currentPlayer is switched by _applyMoveInternal.
    // So, if humanPlayer was 'X', currentPlayer is now 'O'.
    if (currentGameMode == GameMode.humanVsAI && gameActive && currentPlayer == 'O') { // AI is 'O'
      isAITurnInProgress = true;
      notifyListeners(); // Notify UI that AI is "thinking"

      await Future.delayed(const Duration(milliseconds: 750)); // Simulate AI thinking time

      // Call the new method to handle AI's move.
      await _triggerAIMove();
      // _triggerAIMove will set isAITurnInProgress = false and notifyListeners.
    } else {
      if (kDebugMode && currentGameMode == GameMode.humanVsAI) {
        print("AI turn skipped. Conditions: gameActive=$gameActive, currentPlayer=$currentPlayer (expected 'O')");
      }
    }
  }

  Future<void> _triggerAIMove() async {
    if (kDebugMode) {
      print("[GameState._triggerAIMove] Entered. Current player: $currentPlayer, Game active: $gameActive, Mode: $currentGameMode");
    }

    // Safeguard: Ensure it's actually AI's turn.
    if (currentPlayer != 'O' || !gameActive || currentGameMode != GameMode.humanVsAI) {
      if (kDebugMode) {
        print("Skipping _triggerAIMove: Not AI's turn or game conditions not met. CurrentPlayer: $currentPlayer, GameActive: $gameActive, Mode: $currentGameMode");
      }
      // Ensure isAITurnInProgress is reset if this somehow gets called inappropriately.
      if(isAITurnInProgress) {
        isAITurnInProgress = false;
        notifyListeners();
      }
      return;
    }

    AIMove? aiMove = _aiPlayer.getAIMove(this); // Corrected method call
    if (kDebugMode) {
      if (aiMove != null) {
        print("[GameState._triggerAIMove] Received move from AIPlayer: ${aiMove.miniBoardIndex}-${aiMove.cellIndex}");
      } else {
        print("[GameState._triggerAIMove] AIPlayer returned no move (null).");
      }
    }

    if (aiMove != null) {
      // _applyMoveInternal will call notifyListeners upon successful move.
      await _applyMoveInternal(aiMove.miniBoardIndex, aiMove.cellIndex, 'O'); // AI is 'O'
    } else {
      if (kDebugMode) {
        print("AI (_triggerAIMove) could not find a valid move.");
      }
      // If AI has no move, it's still its turn, but nothing happens.
      // The game might be in a state where no valid moves exist for AI.
    }

    isAITurnInProgress = false;
    notifyListeners(); // Notify UI that AI's turn processing is complete.
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
