import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:super_ultimate_tic_tac_toe/logic/game_state.dart';
import 'package:super_ultimate_tic_tac_toe/widgets/super_board_widget.dart';
import 'package:super_ultimate_tic_tac_toe/painters/super_grid_painter.dart';
import 'package:super_ultimate_tic_tac_toe/painters/super_winning_line_painter.dart';

// Helper to get the painter from a CustomPaint widget
T? getPainter<T extends CustomPainter>(WidgetTester tester, Finder finder) {
  final customPaintWidgets = tester.widgetList<CustomPaint>(finder);
  for (final customPaintWidget in customPaintWidgets) {
    if (customPaintWidget.painter is T) {
      return customPaintWidget.painter as T?;
    }
    if (customPaintWidget.foregroundPainter is T) {
      return customPaintWidget.foregroundPainter as T?;
    }
  }
  return null;
}


void main() {
  late GameState gameState;

  setUp(() {
    gameState = GameState();
  });

  Widget createTestableSuperBoardWidget() {
    return ChangeNotifierProvider<GameState>.value(
      value: gameState,
      child: MaterialApp(
        home: Scaffold(
          body: Center( // Ensure constraints
            child: SizedBox( // Ensure finite constraints for LayoutBuilder
              width: 300,
              height: 300,
              child: SuperBoardWidget(key: UniqueKey()), // Add key for consistent rebuilds if needed
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('SuperBoardWidget main grid animation plays on start', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableSuperBoardWidget());

    // Grid animation duration is 800ms.
    // _mainGridController.forward() is called in initState.
    // _startMiniBoardAnimations is set to true after 50ms.

    // Initial state (progress 0)
    var gridPainter = getPainter<SuperGridPainter>(tester, find.byType(CustomPaint));
    expect(gridPainter, isA<SuperGridPainter>());
    // At progress 0, painter exists but might not draw anything.

    await tester.pump(const Duration(milliseconds: 50)); // For _startMiniBoardAnimations
    await tester.pump(const Duration(milliseconds: 100)); // Advance main grid animation
    
    gridPainter = getPainter<SuperGridPainter>(tester, find.byType(CustomPaint));
    expect(gridPainter, isA<SuperGridPainter>());
    // Here, painter's progress should be > 0.

    await tester.pump(const Duration(milliseconds: 700)); // Complete 800ms
    
    // Use pumpAndSettle to ensure animation completes fully
    await tester.pumpAndSettle();
    
    gridPainter = getPainter<SuperGridPainter>(tester, find.byType(CustomPaint));
    expect(gridPainter, isA<SuperGridPainter>());
    // After pumpAndSettle, progress should be 1.0.
    // Direct check is hard, but animation completion is verified.
  });

  testWidgets('SuperBoardWidget super win animation plays for X correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableSuperBoardWidget());
    
    // Pump past the initial grid animation and _startMiniBoardAnimations delay
    await tester.pumpAndSettle(); 

    // Simulate a win for 'X'
    gameState.superBoardState = [
      'X', 'X', 'X', // Winning row
      null, null, null,
      null, null, null,
    ];
    gameState.overallWinner = 'X'; // Set overall winner
    gameState.gameActive = false;
    gameState.notifyListeners(); // Notify listeners of the change

    // Pump to reflect GameState changes in SuperBoardWidget's didUpdateWidget
    await tester.pump(); 
    
    // In didUpdateWidget, there's a Future.delayed(1 second) before animation controller starts
    expect(find.byType(SuperWinningLinePainter), findsNothing, reason: "SuperWinningLinePainter should not be present before 1s delay");
    
    await tester.pump(const Duration(seconds: 1)); // Wait for the delay
    
    // After delay, animation controller should have started.
    // Let's pump a bit to start drawing the line.
    await tester.pump(const Duration(milliseconds: 50)); 
    
    final linePainterFinder = find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is SuperWinningLinePainter);
    expect(linePainterFinder, findsOneWidget, reason: "SuperWinningLinePainter should be present after animation starts");

    var linePainter = getPainter<SuperWinningLinePainter>(tester, linePainterFinder);
    expect(linePainter?.winner, 'X');
    // We can't easily check progress values directly without modifying painter.

    // Let the animation complete (duration 700ms)
    await tester.pumpAndSettle(const Duration(milliseconds: 700));

    linePainter = getPainter<SuperWinningLinePainter>(tester, linePainterFinder);
    expect(linePainter, isA<SuperWinningLinePainter>(), reason: "SuperWinningLinePainter should still be present after animation completes");
    expect(linePainter?.winner, 'X');
    // After pumpAndSettle, progress should be 1.0.
  });

   testWidgets('SuperBoardWidget super win animation resets correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableSuperBoardWidget());
    await tester.pumpAndSettle(); // Initial animations

    // 1. Simulate a win for 'X'
    gameState.superBoardState = ['X', 'X', 'X', null, null, null, null, null, null];
    gameState.overallWinner = 'X';
    gameState.gameActive = false;
    gameState.notifyListeners();
    await tester.pump(); // Process GameState update
    await tester.pump(const Duration(seconds: 1)); // Delay in SuperBoardWidget
    await tester.pumpAndSettle(); // Win animation plays and settles

    final linePainterFinder = find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is SuperWinningLinePainter);
    expect(linePainterFinder, findsOneWidget, reason: "Winning line should be visible after win.");

    // 2. Reset the game
    gameState.resetGame(); // This sets overallWinner to null
    gameState.notifyListeners();
    await tester.pump(); // Process GameState update for reset

    // didUpdateWidget in SuperBoardWidget should now reset the animation state
    // _isSuperWinAnimationPlaying should be false, _superWinningLineAnimation null.
    expect(linePainterFinder, findsNothing, reason: "Winning line should be gone after reset.");
  });

}
