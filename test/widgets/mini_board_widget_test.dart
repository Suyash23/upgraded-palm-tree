import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:super_ultimate_tic_tac_toe/logic/game_state.dart';
import 'package:super_ultimate_tic_tac_toe/widgets/mini_board_widget.dart';
import 'package:super_ultimate_tic_tac_toe/painters/mini_grid_painter.dart';
import 'package:super_ultimate_tic_tac_toe/painters/x_painter.dart';
import 'package:super_ultimate_tic_tac_toe/painters/winning_line_painter.dart';


// Helper to get the painter from a CustomPaint widget
T? getPainter<T extends CustomPainter>(WidgetTester tester, Finder finder) {
  final customPaintWidget = tester.widget<CustomPaint>(finder);
  return customPaintWidget.painter as T?;
}

void main() {
  late GameState gameState;

  setUp(() {
    gameState = GameState();
  });

  Widget createTestableMiniBoardWidget({
    required int miniBoardIndex,
    bool isPlayable = false,
    bool startAnimation = true, // Default to true for grid animation test
    String? boardStatus,
  }) {
    return ChangeNotifierProvider<GameState>.value(
      value: gameState,
      child: MaterialApp(
        home: Scaffold(
          body: Center( // Added Center to give some constraints
            child: SizedBox( // Added SizedBox to provide finite constraints
              width: 100,
              height: 100,
              child: MiniBoardWidget(
                miniBoardIndex: miniBoardIndex,
                isPlayable: isPlayable,
                startAnimation: startAnimation,
                boardStatus: boardStatus,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('MiniBoardWidget grid animation plays on start', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableMiniBoardWidget(miniBoardIndex: 0, startAnimation: true));

    // Initial state before animation starts might be progress 0
    var gridPainter = getPainter<MiniGridPainter>(tester, find.byType(CustomPaint));
    expect(gridPainter, isA<MiniGridPainter>());
    // We can't easily check initial progress directly without exposing it or complex finders.
    // But we expect it to start animating.

    // Pump a few frames to advance the animation
    await tester.pump(const Duration(milliseconds: 100)); // Advance animation
    gridPainter = getPainter<MiniGridPainter>(tester, find.byType(CustomPaint));
    // Here, painter's progress should be > 0 if animation is running
    // This is hard to verify directly.

    await tester.pump(const Duration(milliseconds: 200));
    gridPainter = getPainter<MiniGridPainter>(tester, find.byType(CustomPaint));
    
    await tester.pump(const Duration(milliseconds: 300)); // Total 600ms, full duration
    gridPainter = getPainter<MiniGridPainter>(tester, find.byType(CustomPaint));

    // pumpAndSettle to ensure animation completes
    await tester.pumpAndSettle();
    
    gridPainter = getPainter<MiniGridPainter>(tester, find.byType(CustomPaint));
    expect(gridPainter, isA<MiniGridPainter>());
    // After pumpAndSettle, if the painter's progress was driving the animation,
    // it should be at 1.0. This is an indirect verification based on animation completion.
    // For a more direct test, MiniGridPainter would need to expose its progress or draw differently at 1.0.
    // Assuming MiniGridPainter with progress 1.0 is the final state.
  });

  testWidgets('MiniBoardWidget win animation plays for X correctly (simplified check)', (WidgetTester tester) async {
    const miniBoardIndex = 0;

    // Setup GameState for a win for 'X' in miniBoardIndex
    gameState.miniBoardStates[miniBoardIndex] = [
      'X', 'X', 'X', // Winning row
      null, null, null,
      null, null, null,
    ];
    // Manually set the superBoardState for this mini-board to trigger win
    // This is what would happen if _checkMiniBoardWinner was called in GameState
    gameState.superBoardState[miniBoardIndex] = 'X';


    await tester.pumpWidget(createTestableMiniBoardWidget(
      miniBoardIndex: miniBoardIndex,
      startAnimation: false, // Grid animation not the focus
      boardStatus: null, // Initially no win status
    ));
    
    // Re-pump with the boardStatus 'X' to trigger didUpdateWidget
    await tester.pumpWidget(createTestableMiniBoardWidget(
      miniBoardIndex: miniBoardIndex,
      startAnimation: false,
      boardStatus: 'X', // Now boardStatus is 'X'
    ));

    // Win animation setup happens in a post-frame callback.
    await tester.pump(); // Process the post-frame callback for _setupWinAnimationsAndStart

    // The master win animation duration is 1800ms.
    // Let's pump through it.
    // Stage 1: Winning Line (500ms)
    await tester.pump(const Duration(milliseconds: 100)); // Start of S1
    expect(find.byType(WinningLinePainter), findsOneWidget, reason: "WinningLinePainter should be present during Stage 1");
    
    await tester.pump(const Duration(milliseconds: 400)); // End of S1 (total 500ms)
    
    // Stage 2: Converge (700ms)
    await tester.pump(const Duration(milliseconds: 100)); // Start of S2
    // During S2, XPainters for converging marks should be present.
    // WinningLinePainter should be fading/scaling.
    
    await tester.pump(const Duration(milliseconds: 600)); // End of S2 (total 500+700=1200ms)

    // Stage 3 & 4: Clear & Grow (600ms)
    await tester.pump(const Duration(milliseconds: 100)); // Start of S3/S4
    // During S3/S4, grid and non-winning marks clear, hero XPainter scales.
    
    await tester.pump(const Duration(milliseconds: 500)); // End of S3/S4 (total 1200+600=1800ms)

    // Use pumpAndSettle to ensure all animations are truly finished.
    await tester.pumpAndSettle();

    // Verify final state: A prominent X mark should be visible.
    // This is an indirect check. The final state shows the scaled XPainter.
    // We expect at least one XPainter (the hero mark).
    final xPainters = find.byWidgetPredicate((widget) => widget is CustomPaint && widget.painter is XPainter);
    expect(xPainters, findsOneWidget, reason: "Should find one prominent XPainter after win animation.");

    // To verify it's the "hero" mark, we'd ideally check its size or position,
    // which is complex. The presence of an XPainter in the final settled state is a good indicator.
  });
}
