import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import '../logic/game_state.dart';
import '../widgets/super_board_widget.dart';
import '../themes/color_schemes.dart'; // Added import
import '../themes/button_styles.dart'; // Added import

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
      _gameModeInitialized = true; // Set flag immediately

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return; // Check if widget is still in the tree

        // All logic that might call notifyListeners or depends on initial build being complete
        final arguments = ModalRoute.of(context)?.settings.arguments;
        // It's important to get gameState here, inside the callback,
        // to ensure it's accessed with the correct context if context matters for Provider.
        final gameState = Provider.of<GameState>(context, listen: false);

        if (arguments is GameMode) {
          if (kDebugMode) {
            print("[HomeScreen.didChangeDependencies.postFrame] Received game mode from arguments: $arguments. Setting game mode.");
          }
          // Ensure setGameMode is called before _resetGame if _resetGame depends on the mode.
          // Based on current GameState, setGameMode does not directly call notifyListeners,
          // but it's good practice to group state-affecting calls here.
          gameState.setGameMode(arguments);
        }
        // else {
        //   // This block was commented out in the prompt's example, implying that if arguments
        //   // aren't GameMode, we proceed with the existing gameState.currentGameMode.
        //   // No explicit action needed here if that's the desired behavior.
        //   if (kDebugMode) {
        //     print("[HomeScreen.didChangeDependencies.postFrame] Game mode not found in arguments or not of type GameMode. Using current from GameState: ${gameState.currentGameMode}");
        //   }
        // }

        // This part handles the game reset, which was the primary concern for post-frame callback.
        if (kDebugMode) {
          print("[HomeScreen.didChangeDependencies.postFrame] Initializing. Current mode from GameState: ${gameState.currentGameMode}. Resetting game board.");
        }
        // _resetGame calls gameState.resetGame(), which clears the board, player, winner, etc.,
        // and also calls setState() locally in _HomeScreenState.
        // This is why it needs to be in a post-frame callback.
        _resetGame(gameState, inPostFrameCallback: true);
      });
    }
  }

  void _resetGame(GameState gameState, {bool inPostFrameCallback = false}) {
    // GameState.resetGame() now correctly does not reset currentGameMode.
    // It just clears board, player, winner status.
    gameState.resetGame(); // This calls notifyListeners() in GameState
    
    // If we want to ensure the current mode (possibly set from args) is active 
    // before animations re-trigger, this is implicitly handled as setGameMode was called.
    // No need to call gameState.setGameMode(gameState.currentGameMode) again here.

    if (inPostFrameCallback) {
      // Already in a post-frame callback, safe to call setState directly
      // after the gameState.resetGame() has potentially scheduled other builds.
      if (mounted) {
        setState(() {
          _superBoardKey = UniqueKey();
        });
      }
    } else {
      // Called from a direct action (e.g., button press), schedule setState
      // to run after the current frame, ensuring it doesn't clash with
      // builds potentially triggered by gameState.resetGame().
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _superBoardKey = UniqueKey();
          });
        }
      });
    }
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
    final AppColorScheme scheme = gameStateForUI.currentColorScheme; // Get the scheme
    
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
      // appBar: AppBar(title: const Text('')), // AppBar removed
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
                    style: roundedSquareButtonStyle,
                    child: const Icon(Icons.refresh),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
                    },
                    style: roundedSquareButtonStyle,
                    child: const Icon(Icons.home),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15), // Spacing before the SuperBoard
            Container(
              width: 400,
              height: 400,
              padding: const EdgeInsets.all(8.0),
              color: scheme.scaffoldBackground, // New logic
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
