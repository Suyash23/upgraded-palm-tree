import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_ultimate_tic_tac_toe/widgets/cell_widget.dart';
import 'package:super_ultimate_tic_tac_toe/painters/x_painter.dart';
import 'package:super_ultimate_tic_tac_toe/painters/o_painter.dart';

void main() {
  testWidgets('CellWidget should animate X mark when mark changes to X', (WidgetTester tester) async {
    // Build CellWidget initially with no mark
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CellWidget(
            miniBoardIndex: 0,
            cellIndexInMiniBoard: 0,
            mark: null,
            isPlayableCell: true,
            onTap: () {},
          ),
        ),
      ),
    );

    // Check no painter is initially present
    expect(find.byType(CustomPaint), findsNothing);

    // Update the widget to have an 'X' mark
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CellWidget(
            miniBoardIndex: 0,
            cellIndexInMiniBoard: 0,
            mark: 'X', // Mark is now X
            isPlayableCell: false, // Typically non-playable after mark
            onTap: () {},
          ),
        ),
      ),
    );

    // After mark is set, controller duration is set and animation starts.
    // Pump for a short duration to start the animation.
    await tester.pump(const Duration(milliseconds: 10)); 
    expect(find.byType(CustomPaint), findsOneWidget);
    CustomPaint customPaint = tester.widget(find.byType(CustomPaint));
    expect(customPaint.painter, isA<XPainter>());

    // Pump for the duration of the X animation (450ms)
    // Step through the animation
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 150));
    
    // After animation duration, it should be settled.
    // Or use pumpAndSettle if there are no more scheduled frames by the controller.
    // Since _markController.forward() is called, it will settle at the end.
    await tester.pumpAndSettle(); 

    // Verify XPainter is still there and fully drawn (progress 1.0)
    // We can't directly check painter's progress easily,
    // but pumpAndSettle ensures animation is complete.
    customPaint = tester.widget(find.byType(CustomPaint));
    expect(customPaint.painter, isA<XPainter>());
    // To verify progress, one would typically need to inspect the painter's properties,
    // which is not straightforward. The fact that it settled means animation completed.
  });

  testWidgets('CellWidget should animate O mark when mark changes to O', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CellWidget(
            miniBoardIndex: 0,
            cellIndexInMiniBoard: 0,
            mark: null,
            isPlayableCell: true,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CellWidget(
            miniBoardIndex: 0,
            cellIndexInMiniBoard: 0,
            mark: 'O', // Mark is now O
            isPlayableCell: false,
            onTap: () {},
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 10));
    expect(find.byType(CustomPaint), findsOneWidget);
    CustomPaint customPaint = tester.widget(find.byType(CustomPaint));
    expect(customPaint.painter, isA<OPainter>());
    
    // Pump for the duration of the O animation (400ms)
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 200));
    
    await tester.pumpAndSettle();

    customPaint = tester.widget(find.byType(CustomPaint));
    expect(customPaint.painter, isA<OPainter>());
  });

  testWidgets('CellWidget should show static mark if initialized with one', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CellWidget(
            miniBoardIndex: 0,
            cellIndexInMiniBoard: 0,
            mark: 'X', // Initialized with X
            isPlayableCell: false,
            onTap: () {},
          ),
        ),
      ),
    );

    // No need to pump for animation, should be immediately visible and fully drawn
    expect(find.byType(CustomPaint), findsOneWidget);
    final customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint));
    expect(customPaint.painter, isA<XPainter>());
    // This implies progress is 1.0 due to CellWidget's initState logic.
  });
}
