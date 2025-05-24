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
  String? _previousOverallWinner; // Added to track previous winner
  Size? _currentBoardSize; // Added to store board size from LayoutBuilder

  @override
  void initState() {
    super.initState();

    // Initialize GameState related properties
    // Accessing GameState here should be done carefully if it could trigger rebuilds.
    // However, for initial setup, it's often fine.
    // If GameState is not fully initialized itself, this might need to be deferred.
    // For _previousOverallWinner, it's safer to initialize it based on initial widget.gameState if possible,
    // or after the first build using addPostFrameCallback, or rely on first didUpdateWidget call.
    // For simplicity, let's initialize to null, first didUpdateWidget will handle it.
    _previousOverallWinner = null; 


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
    _superWinAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SuperBoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final gameState = Provider.of<GameState>(context, listen: false);
    final String? currentOverallWinner = gameState.overallWinner;

    // Check for a new win
    if (currentOverallWinner != null &&
        currentOverallWinner != 'DRAW' &&
        _previousOverallWinner == null && // Means it's a new win
        !_isSuperWinAnimationPlaying && // And not already playing (safety)
        _superWinningLineAnimation == null) { // And no animation object exists yet
      if (_currentBoardSize != null) {
        _superWinningLineCoords = _calculateSuperWinningLineCoords(currentOverallWinner, gameState.superBoardState, _currentBoardSize!);
        if (_superWinningLineCoords != null) {
          if (mounted) { // Ensure widget is still mounted before delayed operations
            setState(() {
              _superWinnerForAnimation = currentOverallWinner;
              _isSuperWinAnimationPlaying = true;

              _superWinningLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(parent: _superWinAnimationController, curve: Curves.easeInOutCubic)
              )..addListener(() { 
                  if(mounted) setState(() {}); 
                })
               ..addStatusListener((status) {
                   if (status == AnimationStatus.completed) {
                       if (mounted) {
                           // _isSuperWinAnimationPlaying remains true to keep line drawn
                       }
                   }
               });
            });

            // The original delay before starting the animation.
            Future.delayed(const Duration(seconds: 1), () {
                if (mounted && _isSuperWinAnimationPlaying && _superWinnerForAnimation == currentOverallWinner) { 
                   _superWinAnimationController.reset(); // Reset before forward if it might have run
                   _superWinAnimationController.forward();
                }
            });
          }
        }
      }
    } 
    // Check for game reset (winner becomes null after there was a winner)
    else if (currentOverallWinner == null && _previousOverallWinner != null) {
      if (mounted) {
        setState(() {
          _superWinAnimationController.reset();
          _superWinningLineAnimation = null; // Clear the animation object
          _superWinningLineCoords = null;
          _superWinnerForAnimation = null;
          _isSuperWinAnimationPlaying = false;
        });
      }
    }
    // Update previous winner state for the next comparison
    _previousOverallWinner = currentOverallWinner;
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
    // GameState for actions or non-reactive parts, keep listen: false or rely on didUpdateWidget
    // final gameStateForActions = Provider.of<GameState>(context, listen: false); 
    // overallWinner check is now in didUpdateWidget

    return LayoutBuilder( 
      builder: (context, constraints) {
        if (_currentBoardSize != constraints.biggest) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
             if (mounted) {
                setState(() {
                  _currentBoardSize = constraints.biggest;
                });
             }
          });
        }
        
        return Selector<GameState, Map<String, dynamic>>(
          selector: (_, gameState) => {
            'activeMiniBoardIndex': gameState.activeMiniBoardIndex,
            'superBoardState': gameState.superBoardState,
            // No need to select overallWinner here as it's handled by didUpdateWidget for animation
          },
          // Custom shouldRebuild to compare superBoardState list more carefully if needed,
          // but default list comparison (identity) might be okay if GameState always creates new list on change.
          // For activeMiniBoardIndex, simple equality is fine.
          // Let's rely on default for now, assuming GameState.superBoardState is replaced on change.
          builder: (context, selectedData, child) {
            final int? activeMiniBoardIndex = selectedData['activeMiniBoardIndex'] as int?;
            final List<String?> superBoardState = selectedData['superBoardState'] as List<String?>;

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
                        String? boardStatus = superBoardState[index];
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
    );
  }
}
