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
  Key _superBoardKey = UniqueKey(); // Initial key

  void _resetGame(GameState gameState) {
    gameState.resetGame();
    setState(() {
      _superBoardKey = UniqueKey(); // Generate a new key to force rebuild
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    // ... (statusText logic remains the same) ...
    String statusText;
    if (!gameState.gameActive && gameState.overallWinner != null) {
      switch (gameState.overallWinner) {
        case 'X': statusText = "PLAYER X WINS THE SUPER GAME! 🎉"; break;
        case 'O': statusText = "PLAYER O WINS THE SUPER GAME! 🎉"; break;
        case 'DRAW': statusText = "SUPER GAME IS A DRAW! 🤝"; break;
        default: statusText = "Game Over!"; 
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
      statusText = "Player $player's turn. $boardGuidance";
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
                _resetGame(gameState); // Call the new reset method
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
