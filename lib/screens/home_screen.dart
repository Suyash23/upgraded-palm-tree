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
    // gameStateForActions can be used for non-reactive parts or passed to event handlers.
    final gameStateForActions = Provider.of<GameState>(context, listen: false);
    
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
              child: SuperBoardWidget(key: _superBoardKey),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Selector<GameState, String>(
                selector: (_, gameState) {
                  // This logic constructs the statusText based on various GameState properties.
                  // The Selector will only rebuild if the output of this function (the statusText string) changes.
                  if (gameState.isAITurnInProgress) {
                    return "AI is thinking...";
                  } else if (!gameState.gameActive && gameState.overallWinner != null) {
                    switch (gameState.overallWinner) {
                      case 'X': return "PLAYER X WINS THE SUPER GAME! 🎉";
                      case 'O': return "PLAYER O WINS THE SUPER GAME! 🎉";
                      case 'DRAW': return "SUPER GAME IS A DRAW! 🤝";
                      default: return "Game Over!";
                    }
                  } else {
                    String player = gameState.currentPlayer;
                    String boardGuidance;
                    if (gameState.activeMiniBoardIndex != null) {
                      int displayBoardIndex = gameState.activeMiniBoardIndex! + 1;
                      boardGuidance = "Play in Board #$displayBoardIndex.";
                    } else {
                      boardGuidance = "Play in ANY available (yellow-lined) board.";
                    }
                    // Check for AI turn again for humanVsAI mode, even if not caught by isAITurnInProgress
                    if (gameState.currentGameMode == GameMode.humanVsAI && player == 'O' && gameState.gameActive) {
                       return "AI is thinking...";
                    }
                    return "Player $player's turn. $boardGuidance";
                  }
                },
                builder: (context, statusText, child) {
                  return Text(statusText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500), textAlign: TextAlign.center);
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _resetGame(gameStateForActions); // Pass the non-listening gameState
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
