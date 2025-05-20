import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/game_state.dart';
import '../widgets/super_board_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context); // Get gameState for status and reset

    String statusText;
    if (!gameState.gameActive) { // Assuming gameActive will be set to false on win/draw later
      statusText = "Game Over!"; // Placeholder, will be refined with actual winner
    } else {
      String player = gameState.currentPlayer;
      String boardGuidance;
      if (gameState.activeMiniBoardIndex != null) {
        // Adjust for 0-indexed to 1-indexed for display if desired, or keep 0-indexed
        int displayBoardIndex = gameState.activeMiniBoardIndex! + 1; 
        boardGuidance = "Play in Board #$displayBoardIndex.";
      } else {
        boardGuidance = "Play in ANY available (yellow-lined) board.";
      }
      statusText = "Player $player's turn. $boardGuidance";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Tic Tac Toe'),
      ),
      body: Center(
        child: Column( // Use Column to arrange board, status, and button
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Title could be here if not in AppBar, or additional titles
            // const Text('Super Tic Tac Toe', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            // const SizedBox(height: 10),

            Container(
              width: 400,
              height: 400,
              padding: const EdgeInsets.all(8.0),
              color: Colors.grey[200],
              child: const SuperBoardWidget(),
            ),
            const SizedBox(height: 20), // Spacing
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                statusText,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20), // Spacing
            ElevatedButton(
              onPressed: () {
                gameState.resetGame();
                // Optionally, re-trigger animations if they don't reset automatically
                // This might require more complex state management or passing down a key to SuperBoardWidget
                // For now, resetGame in GameState should clear marks and reset player/active board.
                // Grid animations are typically only on initial build.
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text('Reset Super Game', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 20), // Bottom spacing
          ],
        ),
      ),
    );
  }
}
