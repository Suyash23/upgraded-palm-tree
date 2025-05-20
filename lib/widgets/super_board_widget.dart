import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../painters/super_grid_painter.dart';
import 'mini_board_widget.dart';
import '../logic/game_state.dart';

class SuperBoardWidget extends StatefulWidget {
  const SuperBoardWidget({super.key});

  @override
  State<SuperBoardWidget> createState() => _SuperBoardWidgetState();
}

class _SuperBoardWidgetState extends State<SuperBoardWidget>
    with SingleTickerProviderStateMixin { // Use TickerProviderStateMixin for single controller
  late AnimationController _mainGridController;
  late Animation<double> _mainGridAnimation;

  // To trigger mini-board animations with a delay
  bool _startMiniBoardAnimations = false;

  @override
  void initState() {
    super.initState();
    _mainGridController = AnimationController(
      duration: const Duration(milliseconds: 800), // As per spec
      vsync: this,
    );

    _mainGridAnimation = CurvedAnimation(
      parent: _mainGridController,
      curve: const Cubic(0.65, 0, 0.35, 1), // As per spec
    )..addListener(() {
        setState(() {}); // Redraw on animation change
      });

    _mainGridController.forward();

    // After main grid animation starts, trigger mini-boards with a delay
    Future.delayed(const Duration(milliseconds: 50), () { // 50ms delay as per spec (relative to main grid start)
      if (mounted) {
        setState(() {
          _startMiniBoardAnimations = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _mainGridController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final int? activeMiniBoardIndex = gameState.activeMiniBoardIndex;

    return AspectRatio(
      aspectRatio: 1.0,
      child: CustomPaint(
        painter: SuperGridPainter(progress: _mainGridAnimation.value),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
          ),
          itemCount: 9,
          itemBuilder: (context, index) {
            return MiniBoardWidget(
              miniBoardIndex: index,
              isPlayable: activeMiniBoardIndex == null || activeMiniBoardIndex == index,
              startAnimation: _startMiniBoardAnimations, // Pass trigger
            );
          },
        ),
      ),
    );
  }
}
