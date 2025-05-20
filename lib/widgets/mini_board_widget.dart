import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../painters/mini_grid_painter.dart';
import '../painters/x_painter.dart'; 
import '../painters/o_painter.dart'; 
import '../painters/winning_line_painter.dart'; 
import 'cell_widget.dart';
import '../logic/game_state.dart';

class MiniBoardWidget extends StatefulWidget {
  final int miniBoardIndex;
  final bool isPlayable;
  final bool startAnimation; // Trigger from SuperBoardWidget
  final String? boardStatus; 

  const MiniBoardWidget({
    super.key,
    required this.miniBoardIndex,
    required this.isPlayable,
    required this.startAnimation,
    this.boardStatus, 
  });

  @override
  State<MiniBoardWidget> createState() => _MiniBoardWidgetState();
}

class _MiniBoardWidgetState extends State<MiniBoardWidget>
    with TickerProviderStateMixin { 
  late AnimationController _miniGridController;
  late Animation<double> _miniGridAnimation;

  late AnimationController _winAnimationController; 
  Animation<double>? _winningLineAnimation; 
  List<Offset>? _winningLineCoords; 
  String? _winAnimationPlayer; 
  bool _isWinAnimationPlaying = false;

  // New state variables for draw animation
  late AnimationController _drawAnimationController;
  late Animation<double> _drawFadeOutAnimation; 
  late Animation<double> _drawSymbolFadeInAnimation; 
  late Animation<double> _drawSymbolScaleUpAnimation; 
  bool _isDrawAnimationPlaying = false;

  @override
  void initState() {
    super.initState();
    _miniGridController = AnimationController(
      duration: const Duration(milliseconds: 600), 
      vsync: this,
    );

    _miniGridAnimation = CurvedAnimation(
      parent: _miniGridController,
      curve: const Cubic(0.65, 0, 0.35, 1), 
    )..addListener(() {
        setState(() {});
      });

    if (widget.startAnimation) {
      _miniGridController.forward();
    }

    _winAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500), 
      vsync: this,
    );

    // Initialize _drawAnimationController
    _drawAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400), 
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(covariant MiniBoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startAnimation && !oldWidget.startAnimation && !_miniGridController.isAnimating) {
      _miniGridController.reset();
      _miniGridController.forward();
    }

    if (widget.boardStatus != null && oldWidget.boardStatus == null) { // Board just became decided
      if (widget.boardStatus == 'DRAW') {
        // A draw just happened!
        if (mounted) {
          _isDrawAnimationPlaying = true;
          
          _drawFadeOutAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _drawAnimationController,
              curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
            )
          )..addListener(() { setState(() {}); });

          _drawSymbolFadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _drawAnimationController,
              curve: const Interval(0.25, 1.0, curve: Curves.easeIn),
            )
          )..addListener(() { setState(() {}); });
          
          _drawSymbolScaleUpAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
            CurvedAnimation(
              parent: _drawAnimationController,
              curve: const Interval(0.25, 1.0, curve: Curves.elasticOut),
            )
          )..addListener(() { setState(() {}); });

          _drawAnimationController.reset();
          _drawAnimationController.forward().whenCompleteOrCancel(() {
              if (mounted && _drawAnimationController.status == AnimationStatus.completed) {
                  setState(() { _isDrawAnimationPlaying = false; });
              }
          });
        }
      } else { // A win ('X' or 'O') just happened
        final gameState = Provider.of<GameState>(context, listen: false);
        List<String?> currentMiniBoardCells = gameState.miniBoardStates[widget.miniBoardIndex];
        
        if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return; 
                final boardSize = context.size; 
                if (boardSize != null) {
                    _winningLineCoords = _calculateWinningLineCoords(currentMiniBoardCells, boardSize);
                    if (_winningLineCoords != null) {
                        _isWinAnimationPlaying = true;
                        _winningLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(parent: _winAnimationController, curve: Curves.easeInOut)
                        )..addListener(() { setState(() {}); })
                         ..addStatusListener((status) {
                            if (status == AnimationStatus.completed) {
                                if (mounted) {
                                    // setState(() { _isWinAnimationPlaying = false; }); // Stage 1 complete
                                }
                            }
                         });
                        _winAnimationController.reset();
                        _winAnimationController.forward();
                    }
                }
            });
        }
      }
    } else if (widget.boardStatus == null && oldWidget.boardStatus != null) {
      // Board was reset
      _winAnimationController.reset();
      _drawAnimationController.reset(); // Also reset draw controller
      _isWinAnimationPlaying = false;
      _isDrawAnimationPlaying = false; // Add this
      _winningLineCoords = null;
      _winAnimationPlayer = null;
    }
  }

  @override
  void dispose() {
    _miniGridController.dispose();
    _winAnimationController.dispose(); 
    _drawAnimationController.dispose(); // Add this
    super.dispose();
  }

  List<Offset>? _calculateWinningLineCoords(List<String?> boardCells, Size boardSize) {
    const List<List<int>> winPatterns = [
      [0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]
    ];
    String? winner;
    List<int>? patternIndices;

    for (var pattern in winPatterns) {
      String? p1 = boardCells[pattern[0]];
      String? p2 = boardCells[pattern[1]];
      String? p3 = boardCells[pattern[2]];
      if (p1 != null && p1 == p2 && p1 == p3) {
        winner = p1;
        patternIndices = pattern;
        break;
      }
    }

    if (winner == null || patternIndices == null) return null;
    _winAnimationPlayer = winner; 

    double cellWidth = boardSize.width / 3;
    double cellHeight = boardSize.height / 3;

    Offset getCellCenter(int index) {
      int row = index ~/ 3;
      int col = index % 3;
      return Offset(col * cellWidth + cellWidth / 2, row * cellHeight + cellHeight / 2);
    }

    double extension = (35 / 300) * boardSize.width;
    Offset startCellCenter = getCellCenter(patternIndices[0]);
    Offset endCellCenter = getCellCenter(patternIndices[2]);
    
    Offset lineDirection = endCellCenter - startCellCenter;
    double distance = lineDirection.distance;
    if (distance == 0) return null; 
    lineDirection = lineDirection.scale(1 / distance, 1 / distance); 
    
    Offset extendedStart = startCellCenter - lineDirection * extension;
    Offset extendedEnd = endCellCenter + lineDirection * extension;
    
    return [extendedStart, extendedEnd];
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context, listen: false); 

    if (_isWinAnimationPlaying && _winningLineCoords != null && _winningLineAnimation != null && _winAnimationPlayer != null) {
      return AspectRatio(
        aspectRatio: 1.0,
        child: Stack(
          children: [
            CustomPaint(
              painter: MiniGridPainter(
                isPlayable: false, 
                progress: 1.0, 
              ),
              size: Size.infinite,
            ),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
              itemCount: 9,
              itemBuilder: (context, cellIndex) {
                String? cellMark = gameState.getCellState(widget.miniBoardIndex, cellIndex);
                return CellWidget( 
                  miniBoardIndex: widget.miniBoardIndex,
                  cellIndexInMiniBoard: cellIndex,
                  mark: cellMark,
                  isPlayableCell: false, 
                  onTap: null,
                );
              },
            ),
            CustomPaint(
              painter: WinningLinePainter(
                lineCoords: _winningLineCoords!,
                player: _winAnimationPlayer!,
                progress: _winningLineAnimation!.value,
              ),
              size: Size.infinite,
            ),
          ],
        ),
      );
    } else if (_isDrawAnimationPlaying) {
        // Draw Animation is Playing
        return AspectRatio(
          aspectRatio: 1.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Fading out Grid and Marks
              Opacity(
                opacity: 1.0 - _drawFadeOutAnimation.value, // Fade out
                child: Transform.scale(
                  scale: 1.0 - (_drawFadeOutAnimation.value * 0.5), // Scale down slightly
                  child: Stack( // Keep grid and marks together for unified fade/scale
                    children: [
                       CustomPaint(
                        painter: MiniGridPainter(
                          isPlayable: false, // Not playable during animation
                          progress: 1.0,   // Grid fully drawn initially
                        ),
                        size: Size.infinite,
                      ),
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                        itemCount: 9,
                        itemBuilder: (context, cellIndex) {
                          String? cellMark = gameState.getCellState(widget.miniBoardIndex, cellIndex);
                          return CellWidget(
                            miniBoardIndex: widget.miniBoardIndex,
                            cellIndexInMiniBoard: cellIndex,
                            mark: cellMark,
                            isPlayableCell: false, // Not playable
                            onTap: null,
                          );
                        },
                      ),
                    ]
                  ),
                ),
              ),
              // Fading and Scaling IN '½' Symbol
              Opacity(
                opacity: _drawSymbolFadeInAnimation.value,
                child: Transform.scale(
                  scale: _drawSymbolScaleUpAnimation.value,
                  child: const Center(
                    child: Text(
                      '½',
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
    } else if (widget.boardStatus != null) { 
      Widget finalDisplay;
      switch (widget.boardStatus) {
        case 'X':
          finalDisplay = CustomPaint(painter: XPainter(progress: 1.0), size: Size.infinite);
          break;
        case 'O':
          finalDisplay = CustomPaint(painter: OPainter(progress: 1.0), size: Size.infinite);
          break;
        case 'DRAW':
          finalDisplay = const Center(child: Text('½', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.grey)));
          break;
        default: finalDisplay = const SizedBox.shrink();
      }
      return AspectRatio(aspectRatio: 1.0, child: Container(child: finalDisplay));

    } else { 
      return AspectRatio(
        aspectRatio: 1.0,
        child: CustomPaint(
          painter: MiniGridPainter(
            isPlayable: widget.isPlayable,
            progress: _miniGridAnimation.value,
          ),
          child: (_miniGridAnimation.value == 1.0)
              ? GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                  itemCount: 9,
                  itemBuilder: (context, cellIndex) {
                    String? cellMark = gameState.getCellState(widget.miniBoardIndex, cellIndex);
                    bool isCellActuallyPlayable = widget.isPlayable && cellMark == null;
                    return CellWidget(
                      miniBoardIndex: widget.miniBoardIndex,
                      cellIndexInMiniBoard: cellIndex,
                      mark: cellMark,
                      isPlayableCell: isCellActuallyPlayable,
                      onTap: () { if (isCellActuallyPlayable) gameState.makeMove(widget.miniBoardIndex, cellIndex); },
                    );
                  },
                )
              : const SizedBox.shrink(),
        ),
      );
    }
  }
}
