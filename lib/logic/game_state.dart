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

GameState copyWith() {
  GameState newGameState = GameState();
  newGameState.miniBoardStates = List.generate(9, (i) => List.from(miniBoardStates[i]));
  newGameState.superBoardState = List.from(superBoardState);
  newGameState.currentPlayer = currentPlayer;
  newGameState.activeMiniBoardIndex = activeMiniBoardIndex;
  newGameState.gameActive = gameActive;
  newGameState.overallWinner = overallWinner;
  newGameState.currentGameMode = currentGameMode;
  newGameState.selectedAIDifficulty = selectedAIDifficulty;
  // isAITurnInProgress is a transient state, typically not part of a pure model copy for simulation
  // but if minimax needs to be aware of it, it could be copied. For now, let's assume it's not needed for the simulation part.
  newGameState.isAITurnInProgress = false; // Default for copies used in simulation
  return newGameState;
}

  // Private helper method to apply a validated move
  // The duplicated version (taking 2 arguments) has been removed.
  // This is the correct version (taking 3 arguments).
// Made public for AI simulation purposes. Consider a more restricted internal API if needed.
void applyMoveForSimulation(int miniBoardIdx, int cellIdx, String player) {
  // This method directly applies a move and updates board state WITHOUT notifyListeners
  // or AI turn triggers. It's intended for use by the AI's simulation.

  if (miniBoardStates[miniBoardIdx][cellIdx] != null) {
    // This should ideally not happen if _getAllValidMoves is correct
    if (kDebugMode) print("applyMoveForSimulation: Cell $miniBoardIdx-$cellIdx is already occupied.");
    return; // Or throw an error
  }
  if (superBoardState[miniBoardIdx] != null) {
    if (kDebugMode) print("applyMoveForSimulation: Mini-board $miniBoardIdx is already decided.");
    return; // Or throw an error
  }
   if (activeMiniBoardIndex != null && miniBoardIdx != activeMiniBoardIndex) {
    if (superBoardState[activeMiniBoardIndex!] == null) { // only enforce if the required board is playable
        if (kDebugMode) print("applyMoveForSimulation: Must play in active board $activeMiniBoardIndex, tried $miniBoardIdx.");
        return; // Or throw an error
    }
    // If the required board (activeMiniBoardIndex) is already won/drawn, then the player can choose any other open board.
    // This logic is implicitly handled by _getAllValidMoves providing the correct set of moves.
    // So, if a move to miniBoardIdx is "valid" according to _getAllValidMoves, we should allow it here.
  }


    miniBoardStates[miniBoardIdx][cellIdx] = player;

  if (superBoardState[miniBoardIdx] == null) { // Check if this mini-board was not already decided
    String? miniBoardResult = _checkMiniBoardWinner(miniBoardIdx); // This uses the current (modified) miniBoardStates
      if (miniBoardResult != null) {
        superBoardState[miniBoardIdx] = miniBoardResult;
      // if (kDebugMode) { print("applyMoveForSimulation: Mini-board $miniBoardIdx result: $miniBoardResult by $player"); }

      String? gameResult = _checkOverallWinner(); // This uses the current (modified) superBoardState
        if (gameResult != null) {
          overallWinner = gameResult;
        gameActive = false; // Game ends
        // if (kDebugMode) { print("applyMoveForSimulation: Overall game result: $overallWinner. Game over."); }
        }
      }
    }

  if (gameActive) { // If game didn't end with this move
    currentPlayer = (player == 'X') ? 'O' : 'X'; // Switch player

    // Determine next active mini-board
    if (superBoardState[cellIdx] == null) { // If the target mini-board (based on current cellIdx) is not decided
        activeMiniBoardIndex = cellIdx;
      } else {
      activeMiniBoardIndex = null; // Next player can play anywhere undecided
      }
    } else {
    activeMiniBoardIndex = null; // Game ended, no next active board
    }

  // No print statements or notifyListeners() for simulation
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
    // If activeMiniBoardIndex points to a board that IS decided, player can play anywhere.
    // This check should only fail if player tries to play in a board DIFFERENT from activeMiniBoardIndex
    // AND activeMiniBoardIndex itself is NOT decided.
    if (miniBoardIdx != activeMiniBoardIndex && superBoardState[activeMiniBoardIndex!] == null) {
      if (kDebugMode) { print("Invalid move: Must play in active board $activeMiniBoardIndex (which is not decided), but tried to play in $miniBoardIdx."); }
        return false;
      }
    // It's okay if miniBoardIdx != activeMiniBoardIndex if superBoardState[activeMiniBoardIndex!] IS decided.
    // In that case, the player can choose any other non-decided board.
    // This specific validation within _applyMoveInternal might need to be relaxed or aligned with _getAllValidMoves logic.
    // For now, the logic in _getAllValidMoves is what determines playable boards.
    // If _getAllValidMoves says a move is valid, _applyMoveInternal should generally allow it.
    }
    // --- End: Initial Validation ---

  // Apply the player's move (using the original _applyValidatedMove for actual game moves)
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

  // Public getter for overallWinner for Minimax
  String? getOverallWinner() => overallWinner;

  // Public getter for gameActive for Minimax
  bool isGameActive() => gameActive;

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
    List<String?> board = miniBoardStates[miniBoardIndex]; // Operates on the current instance's state
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
