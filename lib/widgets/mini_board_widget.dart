import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../painters/mini_grid_painter.dart';
import 'cell_widget.dart';
import '../logic/game_state.dart';

class MiniBoardWidget extends StatefulWidget {
  final int miniBoardIndex;
  final bool isPlayable;
  final bool startAnimation; // Trigger from SuperBoardWidget

  const MiniBoardWidget({
    super.key,
    required this.miniBoardIndex,
    required this.isPlayable,
    required this.startAnimation,
  });

  @override
  State<MiniBoardWidget> createState() => _MiniBoardWidgetState();
}

class _MiniBoardWidgetState extends State<MiniBoardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _miniGridController;
  late Animation<double> _miniGridAnimation;

  @override
  void initState() {
    super.initState();
    _miniGridController = AnimationController(
      duration: const Duration(milliseconds: 600), // As per spec
      vsync: this,
    );

    _miniGridAnimation = CurvedAnimation(
      parent: _miniGridController,
      curve: const Cubic(0.65, 0, 0.35, 1), // As per spec
    )..addListener(() {
        setState(() {});
      });

    // Only start animation if the trigger is true
    if (widget.startAnimation) {
      _miniGridController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant MiniBoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If startAnimation becomes true and wasn't before, start animation
    if (widget.startAnimation && !oldWidget.startAnimation && !_miniGridController.isAnimating) {
      _miniGridController.reset(); // Reset if it was somehow played before
      _miniGridController.forward();
    }
  }

  @override
  void dispose() {
    _miniGridController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);

    return AspectRatio(
      aspectRatio: 1.0,
      child: CustomPaint(
        painter: MiniGridPainter(
          isPlayable: widget.isPlayable,
          progress: _miniGridAnimation.value,
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
          ),
          itemCount: 9,
          itemBuilder: (context, cellIndex) {
            String? cellMark = gameState.getCellState(widget.miniBoardIndex, cellIndex);
            bool isCellActuallyPlayable = widget.isPlayable && cellMark == null;

            return CellWidget(
              miniBoardIndex: widget.miniBoardIndex,
              cellIndexInMiniBoard: cellIndex,
              mark: cellMark,
              isPlayableCell: isCellActuallyPlayable,
              onTap: () {
                if (isCellActuallyPlayable) {
                  gameState.makeMove(widget.miniBoardIndex, cellIndex);
                }
              },
            );
          },
        ),
      ),
    );
  }
}
