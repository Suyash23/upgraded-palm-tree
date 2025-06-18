import 'package:flutter/material.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rules'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const <Widget>[
            Text(
              'How to Play Super Tic-Tac-Toe',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Objective:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Be the first player to win three mini-boards in a row, column, or diagonal on the main 3x3 super-grid.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Gameplay:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '1. The game is played on a 3x3 super-grid. Each cell of this super-grid contains a smaller 3x3 mini-board.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '2. Players take turns placing their mark (X or O) in an empty cell of a mini-board.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '3. Winning a Mini-Board: To win a mini-board, a player must get three of their marks in a row, column, or diagonal within that mini-board. Once a mini-board is won or drawn, no more moves can be played in it. Its cell in the super-grid is then marked for the winner (or as a draw).',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '4. Dictated Moves: The crucial rule! The cell you choose to play in on a mini-board dictates which mini-board your opponent must play in next. For example, as illustrated in the diagram below, if you play in the top-right cell of a mini-board, your opponent MUST play their next move in the top-right mini-board of the super-grid.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16), // Space before visual
            _Rule4VisualExplanation(), // Visual explanation added
            SizedBox(height: 16), // Space after visual
            Text(
              '5. Free Choice of Mini-Board: If the mini-board your opponent is sent to is already won or drawn, or completely full, your opponent may choose to play in ANY other mini-board that is not yet won or drawn.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '6. Winning the Game: The first player to win three mini-boards in a row (horizontally, vertically, or diagonally) on the super-grid wins the game!',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '7. Draws: If all mini-boards are won or drawn and no player has won the super-grid, the game is a draw.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widget for Rule #4 visual explanation
class _Rule4VisualExplanation extends StatelessWidget {
  const _Rule4VisualExplanation();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text("Example:", style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
        const SizedBox(height: 8),
        const Text("1. You play 'X' in a cell of a mini-board:"),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(9, (i) {
            return Container(
              width: 25, height: 25,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: Center(child: i == 2 ? const Text('X', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)) : null),
            );
          }),
        ),
        const SizedBox(height: 12),
        const Text("2. This sends your opponent to the corresponding mini-board on the main grid:"),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(9, (i) {
            return Container(
              width: 30, height: 30,
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: (i == 2 ? 2.5 : 0.5)),
                color: i == 2 ? Colors.yellow.withOpacity(0.5) : Colors.grey.withOpacity(0.2),
              ),
              child: Center(child: Text('Board ${i+1}', style: const TextStyle(fontSize: 8))),
            );
          }),
        ),
      ],
    );
  }
}
