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
    with TickerProviderStateMixin {
  late AnimationController _mainGridController;
  late Animation<double> _mainGridAnimation;

  bool _startMiniBoardAnimations = false;

  // GlobalKeys for MiniBoardWidgets
  final List<GlobalKey<_MiniBoardWidgetState>> _miniBoardKeys = List.generate(9, (_) => GlobalKey<_MiniBoardWidgetState>());

  // New state variables for super win animation
  late AnimationController _superWinAnimationController;
  Animation<double>? _superWinningLineAnimation;
  List<Offset>? _superWinningLineCoords;
  String? _superWinnerForAnimation;
  bool _isSuperWinAnimationPlaying = false;

  // Track previous states
  List<String?> _previousSuperBoardState = List.generate(9, (_) => null);
  String? _previousOverallWinner;

  @override
  void initState() {
    super.initState();
    final gameState = Provider.of<GameState>(context, listen: false); // Get GameState for initialization
    _previousSuperBoardState = List.from(gameState.superBoardState);
    _previousOverallWinner = gameState.overallWinner;

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
  // Returns a list of [startOffset, endOffset, winningPatternIndices]
  // winningPatternIndices is a List<int> of the 3 mini-board indices in the line.
  List<dynamic>? _calculateSuperWinningLineCoordsAndPattern(String winner, List<String?> superBoardStatus, Size boardSize) {
    const List<List<int>> winPatterns = [
      [0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]
    ];
    List<int>? winningPatternIndices;

    for (var pattern in winPatterns) {
      String? p1 = superBoardStatus[pattern[0]];
      String? p2 = superBoardStatus[pattern[1]];
      String? p3 = superBoardStatus[pattern[2]];
      if (p1 == winner && p1 == p2 && p1 == p3) {
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
    
    return [startCenter, endCenter, winningPatternIndices];
  }

  Future<void> _triggerSuperWinAnimationSequence(String winner, List<String?> initialSuperBoardStateForWin, Size boardSize) async {
    if (!mounted) return;

    final calculationResult = _calculateSuperWinningLineCoordsAndPattern(winner, initialSuperBoardStateForWin, boardSize);
    if (calculationResult == null) return;

    final List<Offset> lineCoords = [calculationResult[0] as Offset, calculationResult[1] as Offset];
    final List<int> winningPatternIndices = calculationResult[2] as List<int>;
    
    List<Future<void>> miniBoardFutures = [];
    for (int miniBoardIndex in winningPatternIndices) {
      // Check if this mini-board actually contributed to THIS win (was not already won by the winner)
      // This is a simplified check; for more complex scenarios, one might need to compare with _previousSuperBoardState
      // at the exact moment of the win. However, for now, we assume any board in the winning line
      // that shows the winner's mark should have its animation awaited.
      if (initialSuperBoardStateForWin[miniBoardIndex] == winner) {
        final key = _miniBoardKeys[miniBoardIndex];
        final state = key.currentState;
        if (state != null && state.winAnimationCompleteFuture != null) {
          miniBoardFutures.add(state.winAnimationCompleteFuture!);
        }
      }
    }

    if (miniBoardFutures.isNotEmpty) {
      try {
        await Future.wait(miniBoardFutures);
      } catch (e) {
        // Handle or log errors from mini-board animations if necessary
        print("Error waiting for mini-board win animations: $e");
      }
    }

    if (!mounted) return;

    // It's possible gameState.superBoardState might have changed if another move was made quickly.
    // For visual consistency of the line, re-calculate with the current superBoardState if needed,
    // or use the initially passed state. For this implementation, we'll use the initially captured win state.
    // However, if the board has been reset in the meantime, we should not proceed.
    final currentGameState = Provider.of<GameState>(context, listen: false);
    if (currentGameState.overallWinner != winner) { // Check if the win is still valid
        _isSuperWinAnimationPlaying = false; // Ensure it's reset if win invalidated
        _superWinningLineAnimation = null;
        return;
    }

    setState(() {
      _superWinningLineCoords = lineCoords;
      _superWinnerForAnimation = winner;
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
      
      _superWinAnimationController.reset();
      _superWinAnimationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final int? activeMiniBoardIndex = gameState.activeMiniBoardIndex;
    final String? overallWinner = gameState.overallWinner;

    bool newOverallWin = overallWinner != null && overallWinner != 'DRAW' && _previousOverallWinner == null;

    if (newOverallWin && !_isSuperWinAnimationPlaying && _superWinningLineAnimation == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
                final boardSize = context.size;
                if (boardSize != null) {
                    // Pass a copy of the current superBoardState at the moment of win detection.
                    _triggerSuperWinAnimationSequence(overallWinner!, List.from(gameState.superBoardState), boardSize);
                }
            }
        });
    }
    
    // Reset animation if overallWinner becomes null (e.g., game reset)
    if(overallWinner == null && (_isSuperWinAnimationPlaying || _superWinningLineAnimation != null)) {
        _superWinAnimationController.reset();
        _superWinningLineAnimation = null;
        _superWinningLineCoords = null;
        _superWinnerForAnimation = null;
        _isSuperWinAnimationPlaying = false;
        // No need to call setState here if the changes above will trigger a rebuild via other means,
        // but if they don't, a setState might be needed. The existing Positioned.fill check should handle it.
    }
    
    // Update previous states at the end of the build, after all logic.
    _previousOverallWinner = overallWinner;
    _previousSuperBoardState = List.from(gameState.superBoardState);

    return LayoutBuilder( 
      builder: (context, constraints) {
        final Size currentBoardSize = constraints.biggest; // Use for consistent sizing within LayoutBuilder
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
                    String? boardStatus = gameState.superBoardState[index]; // Use current gameState for UI
                    return Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: MiniBoardWidget(
                        key: _miniBoardKeys[index], // Assign the key
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
            if (_isSuperWinAnimationPlaying && _superWinningLineAnimation != null && _superWinningLineCoords != null && _superWinnerForAnimation != null)
              Positioned.fill( 
                child: CustomPaint(
                  painter: SuperWinningLinePainter(
                    lineCoords: _superWinningLineCoords!, // Null checked by condition
                    winner: _superWinnerForAnimation!, // Null checked by condition
                    progress: _superWinningLineAnimation!.value,
                  ),
                  size: currentBoardSize, // Use size from LayoutBuilder
                ),
              ),
          ],
        );
      }
    );
  }
}
