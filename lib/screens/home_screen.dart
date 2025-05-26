import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import '../logic/game_state.dart';
import '../widgets/super_board_widget.dart';

class HomeScreen extends StatefulWidget { // Changed to StatefulWidget
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> { // New State class
  Key _superBoardKey = UniqueKey(); 
  bool _gameModeInitialized = false; // Flag to ensure one-time initialization per route visit

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_gameModeInitialized) {
      final GameMode? mode = ModalRoute.of(context)?.settings.arguments as GameMode?;
      final gameState = Provider.of<GameState>(context, listen: false);

      if (mode != null) {
        gameState.setGameMode(mode); // Set the mode from arguments
      } else {
        // Fallback if no mode is passed (e.g., direct navigation or error)
        // Ensure GameState's default (humanVsHuman) is explicitly set if not already
        if (gameState.currentGameMode != GameMode.humanVsHuman) {
            gameState.setGameMode(GameMode.humanVsHuman);
        }
      }
      // Reset the game state to apply the (potentially new) mode and clear board etc.
      // _resetGame internally calls gameState.resetGame() which now respects currentGameMode
      _resetGame(gameState); 
      _gameModeInitialized = true;
    }
  }

  void _resetGame(GameState gameState) {
    // GameState.resetGame() now correctly does not reset currentGameMode.
    // It just clears board, player, winner status.
    gameState.resetGame(); 
    
    // If we want to ensure the current mode (possibly set from args) is active 
    // before animations re-trigger, this is implicitly handled as setGameMode was called.
    // No need to call gameState.setGameMode(gameState.currentGameMode) again here.

    setState(() {
      _superBoardKey = UniqueKey(); 
    });
  }

  @override
  Widget build(BuildContext context) {
    // final gameState = Provider.of<GameState>(context); // Original line
    // For logging, access GameState without listening if only for this log.
    // If other parts of build depend on it, listen: true is fine (or use Consumer).
    final GameState gameState = Provider.of<GameState>(context, listen: false); // Changed to listen: false for logging
    if (kDebugMode) {
      print("[HomeScreen.build] Current game mode from GameState: ${gameState.currentGameMode}");
    }
    // If you need to listen for changes for UI updates, you'd typically use:
    // final GameState gameStateForUI = Provider.of<GameState>(context);
    // Or, if you modified the line above back to listen: true, that's also fine.
    // For this task, the listen: false version is sufficient for the log.
    // The original Provider.of<GameState>(context) (which implies listen: true)
    // will be used for the actual UI building parts that follow.
    final gameStateForUI = Provider.of<GameState>(context); // Re-get with listen: true for UI
    
    String statusText;
    // Use gameStateForUI for parts of the UI that need to react to changes
    if (gameStateForUI.isAITurnInProgress) { // Check this first
      statusText = "AI is thinking...";
    } else if (!gameStateForUI.gameActive && gameStateForUI.overallWinner != null) {
      switch (gameStateForUI.overallWinner) {
        case 'X': statusText = "PLAYER X WINS THE SUPER GAME! 🎉"; break;
        case 'O': statusText = "PLAYER O WINS THE SUPER GAME! 🎉"; break;
        case 'DRAW': statusText = "SUPER GAME IS A DRAW! 🤝"; break;
        default: statusText = "Game Over!"; 
      }
    } else { // Game is ongoing
      String player = gameStateForUI.currentPlayer;
      String boardGuidance;
      if (gameStateForUI.activeMiniBoardIndex != null) {
        int displayBoardIndex = gameStateForUI.activeMiniBoardIndex! + 1; 
        boardGuidance = "Play in Board #$displayBoardIndex.";
      } else {
        boardGuidance = "Play in ANY available (yellow-lined) board.";
      }
      statusText = "Player $player's turn. $boardGuidance";
      if (gameStateForUI.currentGameMode == GameMode.humanVsAI && player == 'O' && gameStateForUI.gameActive) {
        // This case should ideally be caught by isAITurnInProgress,
        // but as a fallback or if AI moves instantly (e.g. error or no delay).
        // Ensure game is active to prevent showing "AI is thinking" after game over.
        statusText = "AI is thinking..."; 
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Super Tic Tac Toe')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Note: The original subtask mentioned calling GameState's resetGame.
                      // However, the existing _resetGame method in this file
                      // also handles resetting the _superBoardKey, which is crucial for
                      // re-rendering the SuperBoardWidget correctly after a reset.
                      // So, we should call this local _resetGame.
                      // It internally calls gameState.resetGame().
                      _resetGame(gameStateForUI); // Use gameStateForUI or a new Provider.of with listen:false
                    },
                    child: const Text("Reset Game"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
                    },
                    child: const Text("Go to Home"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15), // Spacing before the SuperBoard
            Container(
              width: 400,
              height: 400,
              padding: const EdgeInsets.all(8.0),
              color: Colors.grey[200],
              child: SuperBoardWidget(key: _superBoardKey), // Use the key here
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(statusText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            ),
            // const SizedBox(height: 20), // Removed SizedBox above button
            // ElevatedButton(...) // Removed Reset Button
            // const SizedBox(height: 20), // Removed SizedBox below button
          ],
        ),
      ),
    );
  }
}
