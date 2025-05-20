import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../painters/super_grid_painter.dart';
import '../painters/super_winning_line_painter.dart'; // Added import
import 'mini_board_widget.dart';
import '../logic/game_state.dart';

class SuperBoardWidget extends StatefulWidget {
  const SuperBoardWidget({super.key});

  @override
  State<SuperBoardWidget> createState() => _SuperBoardWidgetState();
}

class _SuperBoardWidgetState extends State<SuperBoardWidget>
    with TickerProviderStateMixin { // Changed to TickerProviderStateMixin
  late AnimationController _mainGridController;
  late Animation<double> _mainGridAnimation;

  bool _startMiniBoardAnimations = false;

  // New state variables for super win animation
  late AnimationController _superWinAnimationController;
  Animation<double>? _superWinningLineAnimation;
  List<Offset>? _superWinningLineCoords;
  String? _superWinnerForAnimation;
  bool _isSuperWinAnimationPlaying = false; 

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

    // Initialize _superWinAnimationController
    _superWinAnimationController = AnimationController(
      duration: const Duration(milliseconds: 700), // As per spec
      vsync: this,
    );
  }

  @override
  void dispose() {
    _mainGridController.dispose();
    _superWinAnimationController.dispose(); // Added dispose
    super.dispose();
  }

  // Helper to calculate super winning line coordinates
  List<Offset>? _calculateSuperWinningLineCoords(String winner, List<String?> superBoardStatus, Size boardSize) {
    const List<List<int>> winPatterns = [
      [0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]
    ];
    List<int>? winningPatternIndices;

    for (var pattern in winPatterns) {
      String? p1 = superBoardStatus[pattern[0]];
      String? p2 = superBoardStatus[pattern[1]];
      String? p3 = superBoardStatus[pattern[2]];
      if (p1 == winner && p1 == p2 && p1 == p3) { // Check for the specific winner
        winningPatternIndices = pattern;
        break;
      }
    }

    if (winningPatternIndices == null) return null;

    double miniBoardWidth = boardSize.width / 3;
    double miniBoardHeight = boardSize.height / 3;
    
    Offset getGeometricMiniBoardCenter(int index) {
      int row = index ~/ 3;
      int col = index % 3;
      return Offset(col * miniBoardWidth + miniBoardWidth / 2, row * miniBoardHeight + miniBoardHeight / 2);
    }

    Offset startCenter = getGeometricMiniBoardCenter(winningPatternIndices[0]);
    Offset endCenter = getGeometricMiniBoardCenter(winningPatternIndices[2]);
    
    return [startCenter, endCenter];
  }


  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final int? activeMiniBoardIndex = gameState.activeMiniBoardIndex;
    final String? overallWinner = gameState.overallWinner;

    // Check for overall winner and trigger animation if not already played
    if (overallWinner != null && overallWinner != 'DRAW' && !_isSuperWinAnimationPlaying && _superWinningLineAnimation == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            // Use LayoutBuilder's constraints for size if context.size is not reliable here.
            // However, for now, let's assume context.size is available from the parent AspectRatio.
            final boardSize = context.size; 
            if (boardSize != null) {
                _superWinningLineCoords = _calculateSuperWinningLineCoords(overallWinner, gameState.superBoardState, boardSize);
                if (_superWinningLineCoords != null) {
                    _superWinnerForAnimation = overallWinner;
                    _isSuperWinAnimationPlaying = true;

                    _superWinningLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(parent: _superWinAnimationController, curve: Curves.easeInOutCubic)
                    )..addListener(() { setState(() {}); })
                     ..addStatusListener((status) {
                         if (status == AnimationStatus.completed) {
                             if (mounted) {
                                 // Keep the line drawn, _isSuperWinAnimationPlaying remains true
                             }
                         }
                     });
                    
                    Future.delayed(const Duration(seconds: 1), () { // Simplified delay
                        if (mounted && _isSuperWinAnimationPlaying) { 
                           _superWinAnimationController.reset();
                           _superWinAnimationController.forward();
                        }
                    });
                }
            }
        });
    }
    
    if(overallWinner == null && _superWinningLineAnimation != null) {
        _superWinAnimationController.reset();
        _superWinningLineAnimation = null;
        _superWinningLineCoords = null;
        _superWinnerForAnimation = null;
        _isSuperWinAnimationPlaying = false;
    }

    return LayoutBuilder( 
      builder: (context, constraints) {
        return Stack(
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: CustomPaint(
                painter: SuperGridPainter(progress: _mainGridAnimation.value),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    String? boardStatus = gameState.superBoardState[index];
                    return Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: MiniBoardWidget(
                        miniBoardIndex: index,
                        isPlayable: (activeMiniBoardIndex == null || activeMiniBoardIndex == index) && boardStatus == null,
                        startAnimation: _startMiniBoardAnimations,
                        boardStatus: boardStatus,
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_isSuperWinAnimationPlaying && _superWinningLineAnimation != null && _superWinningLineCoords != null)
              Positioned.fill( 
                child: CustomPaint(
                  painter: SuperWinningLinePainter(
                    lineCoords: _superWinningLineCoords,
                    winner: _superWinnerForAnimation,
                    progress: _superWinningLineAnimation!.value,
                  ),
                  size: constraints.biggest, 
                ),
              ),
          ],
        );
      }
    );
  }
}
