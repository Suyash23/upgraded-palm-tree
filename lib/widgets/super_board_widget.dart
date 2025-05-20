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
    with SingleTickerProviderStateMixin {
  late AnimationController _mainGridController;
  late Animation<double> _mainGridAnimation;

  bool _startMiniBoardAnimations = false;

  @override
  void initState() {
    super.initState();
    _mainGridController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _mainGridAnimation = CurvedAnimation(
      parent: _mainGridController,
      curve: const Cubic(0.65, 0, 0.35, 1),
    )..addListener(() {
        setState(() {});
      });

    _mainGridController.forward();

    Future.delayed(const Duration(milliseconds: 50), () {
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
            // Get the status of the current mini-board
            String? boardStatus = gameState.superBoardState[index];

            return Padding(
              padding: const EdgeInsets.all(6.0), // Changed to 6.0
              child: MiniBoardWidget(
                miniBoardIndex: index,
                // Determine isPlayable based on activeMiniBoardIndex AND if the board itself is NOT decided
                isPlayable: (activeMiniBoardIndex == null || activeMiniBoardIndex == index) && boardStatus == null,
                startAnimation: _startMiniBoardAnimations,
                boardStatus: boardStatus, // Pass the board status
              ),
            );
          },
        ),
      ),
    );
  }
}
