import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    final gameState = Provider.of<GameState>(context);
    
    String statusText;
    if (gameState.isAITurnInProgress) { // Check this first
      statusText = "AI is thinking...";
    } else if (!gameState.gameActive && gameState.overallWinner != null) {
      switch (gameState.overallWinner) {
        case 'X': statusText = "PLAYER X WINS THE SUPER GAME! 🎉"; break;
        case 'O': statusText = "PLAYER O WINS THE SUPER GAME! 🎉"; break;
        case 'DRAW': statusText = "SUPER GAME IS A DRAW! 🤝"; break;
        default: statusText = "Game Over!"; 
      }
    } else { // Game is ongoing
      String player = gameState.currentPlayer;
      String boardGuidance;
      if (gameState.activeMiniBoardIndex != null) {
        int displayBoardIndex = gameState.activeMiniBoardIndex! + 1; 
        boardGuidance = "Play in Board #$displayBoardIndex.";
      } else {
        boardGuidance = "Play in ANY available (yellow-lined) board.";
      }
      statusText = "Player $player's turn. $boardGuidance";
      if (gameState.currentGameMode == GameMode.humanVsAI && player == 'O' && gameState.gameActive) {
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // When user clicks reset, reset with the current game mode.
                _resetGame(gameState);
              },
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
              child: const Text('Reset Super Game', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
