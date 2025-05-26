import 'dart:async'; // Add this import
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

  late AnimationController _drawAnimationController;
  late Animation<double> _drawFadeOutAnimation; 
  late Animation<double> _drawSymbolFadeInAnimation; 
  late Animation<double> _drawSymbolScaleUpAnimation; 
  bool _isDrawAnimationPlaying = false;

  late AnimationController _shakeAnimationController; // Re-added
  late Animation<Offset> _shakeAnimation; // Re-added

  AnimationController? _stage2WinConvergeController;
  List<Animation<Offset>> _convergingMarkPositionAnims = [];
  List<Animation<double>> _convergingMarkScaleAnims = [];
  List<Animation<double>> _convergingMarkOpacityAnims = [];
  List<int>? _winningCellIndices; 
  int? _heroMarkIndexInPattern; 
  bool _isStage2WinConverging = false;
  Animation<double>? _stage2WinningLineOpacityAnim;
  Animation<double>? _stage2WinningLineScaleAnim; 

  AnimationController? _stage3_4WinClearAndGrowController;
  Animation<double>? _stage3GridOpacityAnim;
  Animation<double>? _stage3GridScaleAnim;
  List<Animation<double>> _stage3NonWinningMarkOpacityAnims = [];
  List<Animation<double>> _stage3NonWinningMarkScaleAnims = [];
  List<int> _nonWinningCellIndicesStage3 = []; 
  bool _isStage3_4WinClearingAndGrowing = false; 
  Animation<double>? _stage4HeroMarkScaleAnim; // Declare the missing animation field

  bool _pendingWinAnimationSetup = false; 
  Completer<void>? _winAnimationCompleter; // Added Completer

  // Added getter for the Future
  Future<void>? get winAnimationCompleteFuture => _winAnimationCompleter?.future;

  @override
  void initState() {
    super.initState();
    _winAnimationCompleter = Completer<void>(); // Initialize Completer
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

    _drawAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400), 
      vsync: this,
    );

    // Re-added _shakeAnimationController and _shakeAnimation initialization
    _shakeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..addListener(() { 
      setState(() {}); 
    });

    _shakeAnimation = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(-0.10, 0.0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.10, 0.0), end: const Offset(0.10, 0.0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.10, 0.0), end: const Offset(-0.10, 0.0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.10, 0.0), end: const Offset(0.10, 0.0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.10, 0.0), end: Offset.zero), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeAnimationController,
      curve: const Cubic(.36,.07,.19,.97),
    ));
  }

  @override
  void didUpdateWidget(covariant MiniBoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startAnimation && !oldWidget.startAnimation && !_miniGridController.isAnimating) {
      _miniGridController.reset();
      _miniGridController.forward();
    }

    if (widget.boardStatus != null && oldWidget.boardStatus == null) { // A win or draw just occurred
      if (widget.boardStatus == 'DRAW') {
        if (mounted) {
          _isDrawAnimationPlaying = true;
          _drawFadeOutAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
            parent: _drawAnimationController, curve: const Interval(0.0, 0.75, curve: Curves.easeOut)))
            ..addListener(() { setState(() {}); });
          _drawSymbolFadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
            parent: _drawAnimationController, curve: const Interval(0.25, 1.0, curve: Curves.easeIn)))
            ..addListener(() { setState(() {}); });
          _drawSymbolScaleUpAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(
            parent: _drawAnimationController, curve: const Interval(0.25, 1.0, curve: Curves.elasticOut)))
            ..addListener(() { setState(() {}); });
          _drawAnimationController.reset();
          _drawAnimationController.forward().whenCompleteOrCancel(() {
            if (mounted && _drawAnimationController.status == AnimationStatus.completed) {
               // Keep the final state of draw animation (symbol visible)
               // setState(() { _isDrawAnimationPlaying = false; }); // Don't set to false
            }
          });
        }
      } else { // A win ('X' or 'O') just happened
         if (mounted) {
          _winAnimationPlayer = widget.boardStatus; 
          setState(() {
            _pendingWinAnimationSetup = true; 
            _isWinAnimationPlaying = false; 
            _isStage2WinConverging = false; 
            _isStage3_4WinClearingAndGrowing = false;
            _winAnimationController.reset(); 
            _stage2WinConvergeController?.reset();
            _stage3_4WinClearAndGrowController?.reset();
          });
        }
      } else { // A win ('X' or 'O') just happened
         if (mounted) {
          if (_winAnimationCompleter!.isCompleted) {
            _winAnimationCompleter = Completer<void>(); // Re-initialize if completed
          }
          _winAnimationPlayer = widget.boardStatus; 
          setState(() {
            _pendingWinAnimationSetup = true; 
            _isWinAnimationPlaying = false; 
            _isStage2WinConverging = false; 
            _isStage3_4WinClearingAndGrowing = false;
            _winAnimationController.reset(); 
            _stage2WinConvergeController?.reset();
            _stage3_4WinClearAndGrowController?.reset();
          });
        }
      }
    } else if (widget.boardStatus == null && oldWidget.boardStatus != null) {
      // Board was reset
      if (_winAnimationCompleter != null && !_winAnimationCompleter!.isCompleted) {
        // If a win animation was in progress but didn't complete,
        // and the board is reset, we might want to cancel it or signal an error.
        // For now, we just create a new one.
      }
      _winAnimationCompleter = Completer<void>(); // Always re-initialize on reset

      _winAnimationController.reset();
      _drawAnimationController.reset();
      _stage2WinConvergeController?.reset(); 
      _stage3_4WinClearAndGrowController?.reset(); 
      _isWinAnimationPlaying = false;
      _isDrawAnimationPlaying = false;
      _isStage2WinConverging = false; 
      _isStage3_4WinClearingAndGrowing = false; 
      _pendingWinAnimationSetup = false; // Reset flag
      _winningLineCoords = null;
      _winAnimationPlayer = null;
      _winningCellIndices = null;
      _heroMarkIndexInPattern = null;
      _convergingMarkPositionAnims.clear();
      _convergingMarkScaleAnims.clear();
      _convergingMarkOpacityAnims.clear();
      _stage3NonWinningMarkOpacityAnims.clear(); 
      _stage3NonWinningMarkScaleAnims.clear(); 
      _nonWinningCellIndicesStage3.clear(); 
    }
  }

  @override
  void dispose() {
    _miniGridController.dispose();
    _winAnimationController.dispose(); 
    _drawAnimationController.dispose(); 
    _shakeAnimationController.dispose(); // Re-added
    _stage2WinConvergeController?.dispose(); 
    _stage3_4WinClearAndGrowController?.dispose(); 
    super.dispose();
  }

  void _startStage2WinConvergence(Size boardSize) { 
    if (!mounted || _winningCellIndices == null || _winAnimationPlayer == null) return;

    setState(() {
      _isWinAnimationPlaying = false; 
      _isStage2WinConverging = true;

      _stage2WinConvergeController?.dispose(); 
      _stage2WinConvergeController = AnimationController(
        duration: const Duration(milliseconds: 700), 
        vsync: this,
      )..addListener(() { setState(() {}); }) 
       ..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            if (mounted) {
              _startStage3_4WinClearAndGrow(boardSize); // Pass boardSize
            }
          }
        });

      _convergingMarkPositionAnims.clear();
      _convergingMarkScaleAnims.clear();
      _convergingMarkOpacityAnims.clear();

      double cellWidth = boardSize.width / 3;
      double cellHeight = boardSize.height / 3;
      Offset boardCenter = Offset(boardSize.width / 2, boardSize.height / 2);

      if (_winningCellIndices!.contains(4)) { 
          _heroMarkIndexInPattern = _winningCellIndices!.indexOf(4);
      } else {
          _heroMarkIndexInPattern = 1; 
      }
      
      for (int i = 0; i < 3; i++) {
        int cellIndex = _winningCellIndices![i];
        int row = cellIndex ~/ 3;
        int col = cellIndex % 3;
        Offset startPos = Offset(col * cellWidth + cellWidth / 2, row * cellHeight + cellHeight / 2);
        
        _convergingMarkPositionAnims.add(
          Tween<Offset>(begin: startPos, end: boardCenter).animate(CurvedAnimation(
            parent: _stage2WinConvergeController!, curve: Curves.easeOutCubic))
        );

        bool isHero = (i == _heroMarkIndexInPattern);
        _convergingMarkScaleAnims.add(
          Tween<double>(begin: 1.0, end: isHero ? 0.35 : 0.01).animate(CurvedAnimation(
            parent: _stage2WinConvergeController!, curve: Curves.easeOutCubic))
        );
        _convergingMarkOpacityAnims.add(
          Tween<double>(begin: 1.0, end: isHero ? 1.0 : 0.0).animate(CurvedAnimation(
            parent: _stage2WinConvergeController!, curve: isHero ? Curves.linear : const Interval(0.0, 0.85, curve: Curves.easeOut)))
        );
      }
      
      _stage2WinningLineOpacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _stage2WinConvergeController!, curve: const Interval(0.0, 0.7, curve: Curves.easeOut))
      );
      _stage2WinningLineScaleAnim = Tween<double>(begin: 1.0, end: 0.01).animate(
        CurvedAnimation(parent: _stage2WinConvergeController!, curve: const Interval(0.0, 0.7, curve: Curves.easeOut))
      );
      
      _stage2WinConvergeController!.forward();
    });
  }

  void _startStage3_4WinClearAndGrow(Size boardSize) { 
    if (!mounted || _winningCellIndices == null || _winAnimationPlayer == null) {
      setState(() {
        _isStage2WinConverging = false;
        _isWinAnimationPlaying = false; 
        _isDrawAnimationPlaying = false;
      });
      return;
    }
    final gameState = Provider.of<GameState>(context, listen: false);

    setState(() {
      _isStage2WinConverging = false; 
      _isStage3_4WinClearingAndGrowing = true;

      _stage3_4WinClearAndGrowController?.dispose();
      _stage3_4WinClearAndGrowController = AnimationController(
        duration: const Duration(milliseconds: 600), 
        vsync: this,
      );

      _stage3GridOpacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(
          parent: _stage3_4WinClearAndGrowController!,
          curve: const Interval(0.0, 0.83, curve: Curves.easeOut))); 
      _stage3GridScaleAnim = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(
          parent: _stage3_4WinClearAndGrowController!,
          curve: const Interval(0.0, 0.83, curve: Curves.easeOut)));

      _nonWinningCellIndicesStage3.clear();
      _stage3NonWinningMarkOpacityAnims.clear();
      _stage3NonWinningMarkScaleAnims.clear();

      for (int i = 0; i < 9; i++) {
        if (!(_winningCellIndices?.contains(i) ?? false)) {
          if (gameState.miniBoardStates[widget.miniBoardIndex][i] != null) {
            _nonWinningCellIndicesStage3.add(i);
            _stage3NonWinningMarkOpacityAnims.add(Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(
                parent: _stage3_4WinClearAndGrowController!,
                curve: const Interval(0.0, 0.5, curve: Curves.easeOut)))); 
            _stage3NonWinningMarkScaleAnims.add(Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(
                parent: _stage3_4WinClearAndGrowController!,
                curve: const Interval(0.0, 0.5, curve: Curves.easeOut))));
          }
        }
      }
      
      // Stage 4: Hero Mark Growth (driven by the same controller)
      _stage4HeroMarkScaleAnim = Tween<double>(begin: 0.35, end: 2.4).animate(CurvedAnimation(
          parent: _stage3_4WinClearAndGrowController!,
          curve: const Interval(0.0, 1.0, curve: Cubic(0.68, -0.55, 0.27, 1.55)) 
      ));

      _stage3_4WinClearAndGrowController!.addListener(() { setState(() {}); });
      _stage3_4WinClearAndGrowController!.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted) {
            setState(() { 
              _isStage3_4WinClearingAndGrowing = false; 
            });
            _winAnimationCompleter?.complete(); // Complete the completer here
          }
        }
      });
      _stage3_4WinClearAndGrowController!.forward();
    });
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
    _winningCellIndices = List<int>.from(patternIndices); 

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

  Future<void> _attemptMoveOnCell(int cellIndexInMiniBoard) async {
      final gameState = Provider.of<GameState>(context, listen: false);

      // Shake only if it's not this mini-board's turn (another mini-board is active).
      if (gameState.activeMiniBoardIndex != null && widget.miniBoardIndex != gameState.activeMiniBoardIndex) {
        _shakeAnimationController.reset();
        _shakeAnimationController.forward();
        return; 
      }

      // If it IS this mini-board's turn (or no board is specifically active),
      // check if the cell is already occupied. If so, return silently (no shake).
      if (gameState.getCellState(widget.miniBoardIndex, cellIndexInMiniBoard) != null) {
        // Optionally, print a debug message here like: print("Cell is already occupied, move not processed.");
        return; 
      }

      // Changed from makeMove to processPlayerMove. 
      // processPlayerMove is async void and handles notifyListeners itself.
      // The 'moveMade' boolean is no longer returned.
      // Shake animation for invalid (already taken) moves is handled by the check above.
      // If a move is valid, processPlayerMove will update the state and trigger rebuilds.
      await gameState.processPlayerMove(widget.miniBoardIndex, cellIndexInMiniBoard);

      // The following block is removed as moveMade is no longer available.
      // if (!moveMade && mounted) { 
      //   _shakeAnimationController.reset();
      //   _shakeAnimationController.forward();
      // }
    }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context, listen: false); 

    return LayoutBuilder( 
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size boardSize = constraints.biggest; 

        if (_pendingWinAnimationSetup && widget.boardStatus != null && widget.boardStatus != 'DRAW') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_pendingWinAnimationSetup) return; 

            List<String?> currentMiniBoardCells = gameState.miniBoardStates[widget.miniBoardIndex];
            final tempWinningLineCoords = _calculateWinningLineCoords(currentMiniBoardCells, boardSize);

            if (tempWinningLineCoords != null && _winAnimationPlayer != null) {
              setState(() {
                _winningLineCoords = tempWinningLineCoords;
                _isWinAnimationPlaying = true;
                _pendingWinAnimationSetup = false; 

                _winningLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(parent: _winAnimationController, curve: Curves.easeInOut)
                )..addListener(() { setState(() {}); })
                 ..addStatusListener((status) {
                    if (status == AnimationStatus.completed) {
                        if (mounted) {
                            _startStage2WinConvergence(boardSize); 
                        }
                    }
                 });
                _winAnimationController.reset();
                _winAnimationController.forward();
              });
            } else {
              if (mounted) setState(() { _pendingWinAnimationSetup = false; });
            }
          });
          // Render a basic grid or empty container while win animation setup is pending
          // to prevent the flash of the final large X/O.
          return AspectRatio(
            aspectRatio: 1.0,
            child: CustomPaint(
              painter: MiniGridPainter(isPlayable: false, progress: 1.0), // Basic grid
              size: Size.infinite,
            ),
          );
        }
        
        if (_isStage3_4WinClearingAndGrowing) {
          double cellWidth = boardSize.width / 3;
          double cellHeight = boardSize.height / 3;
          Offset boardCenter = Offset(boardSize.width / 2, boardSize.height / 2);

          List<Widget> stage3_4Elements = []; // Renamed for clarity

          // Animated Grid
          if (_stage3GridOpacityAnim != null && _stage3GridScaleAnim != null) {
            stage3_4Elements.add(Opacity(
              opacity: _stage3GridOpacityAnim!.value,
              child: Transform.scale(
                scale: _stage3GridScaleAnim!.value,
                child: CustomPaint(painter: MiniGridPainter(isPlayable: false, progress: 1.0), size: Size.infinite),
              ),
            ));
          }

          // Animated Non-Winning Marks
          for (int i = 0; i < _nonWinningCellIndicesStage3.length; i++) {
            int cellIndex = _nonWinningCellIndicesStage3[i];
            String? mark = gameState.miniBoardStates[widget.miniBoardIndex][cellIndex]; 
            if (mark == null) continue; 

            int r = cellIndex ~/ 3; int c = cellIndex % 3;
            stage3_4Elements.add(Positioned(
              left: c * cellWidth, top: r * cellHeight,
              width: cellWidth, height: cellHeight,
              child: Opacity(
                opacity: _stage3NonWinningMarkOpacityAnims[i].value,
                child: Transform.scale(
                  scale: _stage3NonWinningMarkScaleAnims[i].value,
                  child: mark == 'X'
                      ? CustomPaint(painter: XPainter(progress: 1.0), size: Size.infinite)
                      : CustomPaint(painter: OPainter(progress: 1.0), size: Size.infinite),
                ),
              ),
            ));
          }
          
          // Stage 4: Animated "Hero" Mark (growing)
          if (_heroMarkIndexInPattern != null && _winAnimationPlayer != null && _winningCellIndices != null && _stage4HeroMarkScaleAnim != null) {
            double heroAnimatedScale = _stage4HeroMarkScaleAnim!.value; 
            
            Widget heroMarkWidget = (_winAnimationPlayer == 'X')
                ? CustomPaint(painter: XPainter(progress: 1.0), size: Size(cellWidth, cellHeight))
                : CustomPaint(painter: OPainter(progress: 1.0), size: Size(cellWidth, cellHeight));
            
            stage3_4Elements.add(
              Positioned(
                left: boardCenter.dx - (cellWidth / 2 * heroAnimatedScale),
                top: boardCenter.dy - (cellHeight / 2 * heroAnimatedScale),
                width: cellWidth * heroAnimatedScale,
                height: cellHeight * heroAnimatedScale,
                child: Opacity(
                  opacity: 1.0, // Hero mark remains fully opaque during its growth in Stage 4
                  child: heroMarkWidget,
                ),
              )
            );
          }
          return AspectRatio(aspectRatio: 1.0, child: Stack(children: stage3_4Elements));
        } else if (_isWinAnimationPlaying && _winningLineCoords != null && _winningLineAnimation != null && _winAnimationPlayer != null) {
          return AspectRatio(
            aspectRatio: 1.0,
            child: Stack(
              children: [
                CustomPaint(
                  painter: MiniGridPainter(isPlayable: false, progress: 1.0),
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
        } else if (_isStage2WinConverging) {
          double cellWidth = boardSize.width / 3;
          double cellHeight = boardSize.height / 3;

          List<Widget> convergingElements = [];

          convergingElements.add(CustomPaint(painter: MiniGridPainter(isPlayable: false, progress: 1.0), size: Size.infinite));
          
          for (int i = 0; i < 9; i++) {
            bool isWinningCell = _winningCellIndices?.contains(i) ?? false;
            if (!isWinningCell) { 
              String? mark = gameState.getCellState(widget.miniBoardIndex, i);
              if (mark != null) {
                int r = i ~/ 3; int c = i % 3;
                convergingElements.add(Positioned(
                  left: c * cellWidth, top: r * cellHeight,
                  width: cellWidth, height: cellHeight,
                  child: mark == 'X' 
                      ? CustomPaint(painter: XPainter(progress:1.0), size: Size.infinite) 
                      : CustomPaint(painter: OPainter(progress:1.0), size: Size.infinite),
                ));
              }
            }
          }
          
          if (_winningCellIndices != null && _winAnimationPlayer != null && 
              _convergingMarkPositionAnims.length == 3 &&
              _convergingMarkScaleAnims.length == 3 &&
              _convergingMarkOpacityAnims.length == 3) {
            for (int i = 0; i < 3; i++) { 
              Offset currentPos = _convergingMarkPositionAnims[i].value;
              double currentScale = _convergingMarkScaleAnims[i].value;
              double currentOpacity = _convergingMarkOpacityAnims[i].value;

              Widget markWidget = (_winAnimationPlayer == 'X')
                  ? CustomPaint(painter: XPainter(progress: 1.0), size: Size(cellWidth, cellHeight))
                  : CustomPaint(painter: OPainter(progress: 1.0), size: Size(cellWidth, cellHeight));

              convergingElements.add(
                Positioned(
                  left: currentPos.dx - (cellWidth / 2 * currentScale), 
                  top: currentPos.dy - (cellHeight / 2 * currentScale),
                  width: cellWidth * currentScale, 
                  height: cellHeight * currentScale,
                  child: Opacity(
                    opacity: currentOpacity,
                    child: markWidget,
                  ),
                )
              );
            }
          }
          
          if (_winningLineCoords != null && _winAnimationPlayer != null && 
              _stage2WinningLineOpacityAnim != null && _stage2WinningLineScaleAnim != null) {
            convergingElements.add(
              Opacity(
                opacity: _stage2WinningLineOpacityAnim!.value,
                child: Transform.scale(
                  scale: _stage2WinningLineScaleAnim!.value,
                  child: CustomPaint(
                    painter: WinningLinePainter(
                      lineCoords: _winningLineCoords!, 
                      player: _winAnimationPlayer!,
                      progress: 1.0, 
                    ),
                    size: Size.infinite, 
                  ),
                ),
              )
            );
          }

          return AspectRatio(aspectRatio: 1.0, child: Stack(children: convergingElements));
        } else if (_isDrawAnimationPlaying) {
            return AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 1.0 - _drawFadeOutAnimation.value, 
                    child: Transform.scale(
                      scale: 1.0 - (_drawFadeOutAnimation.value * 0.5), 
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
                        ]
                      ),
                    ),
                  ),
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
          switch(widget.boardStatus){
            case 'X':finalDisplay=CustomPaint(painter:XPainter(progress:1.0),size:Size.infinite);break;
            case 'O':finalDisplay=CustomPaint(painter:OPainter(progress:1.0),size:Size.infinite);break;
            case 'DRAW':finalDisplay=const Center(child:Text('½',style:TextStyle(fontSize:40,fontWeight:FontWeight.bold,color:Colors.grey)));break;
            default:finalDisplay=const SizedBox.shrink();
          }
          return AspectRatio(aspectRatio:1.0,child:Container(child:finalDisplay));
        } else { 
          // Re-added SlideTransition wrapper for _shakeAnimation
          return SlideTransition( 
            position: _shakeAnimation,
            child: AspectRatio(
              aspectRatio:1.0,
              child:CustomPaint(
                painter:MiniGridPainter(isPlayable:widget.isPlayable,progress:_miniGridAnimation.value),
                child:(_miniGridAnimation.value==1.0)
                    ?GridView.builder(physics:const NeverScrollableScrollPhysics(),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3),itemCount:9,itemBuilder:(c,ci){String? m=gameState.getCellState(widget.miniBoardIndex,ci);bool iCAP=widget.isPlayable&&m==null;return CellWidget(miniBoardIndex:widget.miniBoardIndex,cellIndexInMiniBoard:ci,mark:m,isPlayableCell:iCAP,onTap:()=>_attemptMoveOnCell(ci));})
                    :const SizedBox.shrink()
              )
            )
          );
        }
      }
    );
  }
}
