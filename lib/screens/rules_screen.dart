import 'package:flutter/material.dart';
import 'dart:math' as math; // For math.pi and math.atan2
import 'package:provider/provider.dart';
import '../logic/game_state.dart';
import '../themes/color_schemes.dart';
import '../painters/mini_grid_painter.dart';
import '../painters/x_painter.dart';

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
    final AppColorScheme scheme = Provider.of<GameState>(context).currentColorScheme;
    const double boardSize = 75.0;
    const double cellSize = boardSize / 3.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text("Example:", style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Visual 1: Current Mini-Board Play
            Expanded(
              child: Column(
                children: <Widget>[
                  const Text("Your move in a mini-board:", textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: boardSize,
                    height: boardSize,
                    child: Stack(
                      children: [
                        CustomPaint(
                          painter: MiniGridPainter(
                            isPlayable: true, // Example shows a playable board
                            progress: 1.0,
                            gridColor: scheme.miniGridColor,
                            activeGridColor: scheme.activeMiniGridColor, // Though not strictly active for this exact explanation part
                          ),
                          size: const Size(boardSize, boardSize),
                        ),
                        Positioned(
                          left: cellSize * 2, // Top-right cell (column 2)
                          top: 0,             // Top-right cell (row 0)
                          width: cellSize,
                          height: cellSize,
                          child: Padding(
                            padding: const EdgeInsets.all(2.0), // Small padding for X
                            child: CustomPaint(
                              painter: XPainter(progress: 1.0, color: scheme.xColor),
                              size: Size.infinite,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Visual 2: Arrow Icon
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(Icons.arrow_forward, size: 30, color: Colors.black),
            ),
            // Visual 3: Target Super-Grid Cell Highlighted
            Expanded(
              child: Column(
                children: <Widget>[
                  const Text("Sends opponent to:", textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: boardSize,
                    height: boardSize,
                    child: Stack(
                      children: [
                        Container(
                          color: scheme.activeMiniGridColor.withOpacity(0.3), // Highlight background
                        ),
                        CustomPaint(
                          painter: MiniGridPainter(
                            isPlayable: false, // Target board is just shown, not necessarily playable by current player
                            progress: 1.0,
                            gridColor: scheme.miniGridColor,
                            activeGridColor: scheme.activeMiniGridColor,
                          ),
                          size: const Size(boardSize, boardSize),
                        ),
                        // Optional: Could add a small text label like "Top-Right Board"
                        // Center(child: Text("Top-Right\nBoard", style: TextStyle(fontSize: 10, color: Colors.black54), textAlign: TextAlign.center,))
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Offset startOffset;
  final Offset endOffset;
  final Color color;
  final double strokeWidth;
  final double arrowheadAngle;
  final double arrowheadLength;

  _ArrowPainter({
    required this.startOffset,
    required this.endOffset,
    this.color = Colors.black,
    this.strokeWidth = 2.0,
    this.arrowheadAngle = math.pi / 6, // 30 degrees
    this.arrowheadLength = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw the line
    canvas.drawLine(startOffset, endOffset, paint);

    // Draw the arrowhead
    final path = Path();
    final double angle = math.atan2(endOffset.dy - startOffset.dy, endOffset.dx - startOffset.dx);

    // Point 1 of arrowhead
    path.moveTo(
        endOffset.dx - arrowheadLength * math.cos(angle - arrowheadAngle),
        endOffset.dy - arrowheadLength * math.sin(angle - arrowheadAngle),
    );
    // Tip of arrowhead
    path.lineTo(endOffset.dx, endOffset.dy);
    // Point 2 of arrowhead
    path.lineTo(
        endOffset.dx - arrowheadLength * math.cos(angle + arrowheadAngle),
        endOffset.dy - arrowheadLength * math.sin(angle + arrowheadAngle),
    );

    // Close the path for a filled arrowhead, or draw lines for an open one.
    // For a filled arrowhead, change paint style and close path.
    // For now, let's make it an open arrowhead with lines.
    // To make it filled:
    // path.close();
    // canvas.drawPath(path, paint..style = PaintingStyle.fill);
    // For an open arrowhead (lines):
    canvas.drawPath(path, paint); // This will draw the two lines of the arrowhead
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) {
    return oldDelegate.startOffset != startOffset ||
           oldDelegate.endOffset != endOffset ||
           oldDelegate.color != color ||
           oldDelegate.strokeWidth != strokeWidth ||
           oldDelegate.arrowheadAngle != arrowheadAngle ||
           oldDelegate.arrowheadLength != arrowheadLength;
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
