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
  // Grid animation
  late AnimationController _miniGridController;
  late Animation<double> _miniGridAnimation;

  // Draw animation
  late AnimationController _drawAnimationController;
  late Animation<double> _drawFadeOutAnimation;
  late Animation<double> _drawSymbolFadeInAnimation;
  late Animation<double> _drawSymbolScaleUpAnimation;
  bool _isDrawAnimationPlaying = false; // Keep for draw, separate from win

  // Shake animation
  late AnimationController _shakeAnimationController;
  late Animation<Offset> _shakeAnimation;

  // --- Unified Win Animation ---
  late AnimationController _masterWinController;
  bool _isMasterWinAnimationActive = false; // True if win animation is running or has completed
  
  // Shared properties derived during win setup
  List<Offset>? _winningLineCoords;
  String? _winAnimationPlayer; // 'X' or 'O'
  List<int>? _winningCellIndices; // e.g., [0, 1, 2]
  int? _heroMarkIndexInPattern; // Index within _winningCellIndices for the mark that grows
  List<int> _nonWinningCellIndicesStage3 = []; // Cells with marks that are not part of winning line

  // Stage 1: Winning Line Animation
  Animation<double>? _s1WinningLineProgress;

  // Stage 2: Marks Converge & Line Fades
  List<Animation<Offset>> _s2ConvergingMarkPositionAnims = [];
  List<Animation<double>> _s2ConvergingMarkScaleAnims = [];
  List<Animation<double>> _s2ConvergingMarkOpacityAnims = [];
  Animation<double>? _s2WinningLineOpacity;
  Animation<double>? _s2WinningLineScale;

  // Stage 3: Grid & Non-Winning Marks Clear
  Animation<double>? _s3GridOpacity;
  Animation<double>? _s3GridScale;
  List<Animation<double>> _s3NonWinningMarkOpacityAnims = [];
  List<Animation<double>> _s3NonWinningMarkScaleAnims = [];
  
  // Stage 4: Hero Mark Growth (part of Stage 3-4 controller time)
  Animation<double>? _s4HeroMarkScaleAnim;
  // --- End Unified Win Animation ---

  bool _pendingWinAnimationSetup = false;

  // Durations and Intervals for Unified Win Animation
  static const Duration _s1Duration = Duration(milliseconds: 500);
  static const Duration _s2Duration = Duration(milliseconds: 700);
  static const Duration _s3_4Duration = Duration(milliseconds: 600);
  static final Duration _totalWinDuration = _s1Duration + _s2Duration + _s3_4Duration; // 1800ms

  static final double _s1Start = 0.0;
  static final double _s1End = _s1Duration.inMilliseconds / _totalWinDuration.inMilliseconds;
  
  static final double _s2Start = _s1End;
  static final double _s2End = (_s1Duration.inMilliseconds + _s2Duration.inMilliseconds) / _totalWinDuration.inMilliseconds;
  
  static final double _s3_4Start = _s2End;
  static final double _s3_4End = 1.0;


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

    // Initialize _masterWinController
    _masterWinController = AnimationController(
      duration: _totalWinDuration,
      vsync: this,
    );
    // Listeners for _masterWinController will be added in _setupWinAnimationsAndStart

    _drawAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..addListener(_setStateListener); // Consolidated listener for draw animation

    _shakeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
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

    if (widget.boardStatus != null && oldWidget.boardStatus == null) {
      // Board has just been won or drawn
      if (widget.boardStatus == 'DRAW') {
        if (mounted) {
          _isDrawAnimationPlaying = true; // This flag is still used for draw animation
          // Draw animation setup
          _drawFadeOutAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
            parent: _drawAnimationController, curve: const Interval(0.0, 0.75, curve: Curves.easeOut)));
            // Removed individual listener: ..addListener(() { setState(() {}); });
          _drawSymbolFadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
            parent: _drawAnimationController, curve: const Interval(0.25, 1.0, curve: Curves.easeIn)));
            // Removed individual listener: ..addListener(() { setState(() {}); });
          _drawSymbolScaleUpAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(
            parent: _drawAnimationController, curve: const Interval(0.25, 1.0, curve: Curves.elasticOut)));
            // Removed individual listener: ..addListener(() { setState(() {}); });
          _drawAnimationController.reset();
          _drawAnimationController.forward();
        }
      } else { // A win ('X' or 'O') just happened
         if (mounted) {
          _winAnimationPlayer = widget.boardStatus; // Store the winner
          setState(() {
            _pendingWinAnimationSetup = true; // Flag to setup animations in build via LayoutBuilder
            _isMasterWinAnimationActive = true; // Mark that a win animation sequence will start/is active
            _masterWinController.reset(); // Reset controller if it was used before
            // Clear any previous win-specific animation objects
            _clearWinAnimationCache();
          });
        }
      }
    } else if (widget.boardStatus == null && oldWidget.boardStatus != null) {
      // Board was reset
      _masterWinController.reset();
      _drawAnimationController.reset(); // Draw animation also resets
      
      setState(() {
        _isMasterWinAnimationActive = false;
        _isDrawAnimationPlaying = false;
        _pendingWinAnimationSetup = false;
        _clearWinAnimationCache();
      });
    }
  }
  
  void _clearWinAnimationCache() {
    _winningLineCoords = null;
    // _winAnimationPlayer is cleared by board reset logic in didUpdateWidget or remains for current win
    _winningCellIndices = null;
    _heroMarkIndexInPattern = null;
    
    _s1WinningLineProgress = null;
    
    _s2ConvergingMarkPositionAnims.clear();
    _s2ConvergingMarkScaleAnims.clear();
    _s2ConvergingMarkOpacityAnims.clear();
    _s2WinningLineOpacity = null;
    _s2WinningLineScale = null;
    
    _s3GridOpacity = null;
    _s3GridScale = null;
    _s3NonWinningMarkOpacityAnims.clear();
    _s3NonWinningMarkScaleAnims.clear();
    _nonWinningCellIndicesStage3.clear();
    
    _s4HeroMarkScaleAnim = null;
  }

  @override
  void dispose() {
    _miniGridController.dispose();
    _masterWinController.dispose(); // Dispose new master controller
    _drawAnimationController.dispose();
    _shakeAnimationController.dispose();
    super.dispose();
  }

  // This method will be called from build() via LayoutBuilder's context
  // when _pendingWinAnimationSetup is true.
  void _setupWinAnimationsAndStart(Size boardSize, GameState gameState) {
    if (!mounted || _winAnimationPlayer == null) {
      setState(() { _pendingWinAnimationSetup = false; });
      return;
    }

    _masterWinController.removeListener(_setStateListener);
    _masterWinController.removeStatusListener(_masterWinStatusListener);

    // 1. Calculate necessary coordinates and indices (formerly part of _calculateWinningLineCoords and others)
    _calculateWinningLineData(gameState.miniBoardStates[widget.miniBoardIndex], boardSize);
    if (_winningLineCoords == null || _winningCellIndices == null) {
       setState(() { _pendingWinAnimationSetup = false; _isMasterWinAnimationActive = false; });
       return; // Cannot proceed if basic win data is not found
    }
    _determineNonWinningCells(gameState);


    // 2. Define all animations based on _masterWinController and Intervals
    // Stage 1: Winning Line Animation
    _s1WinningLineProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _masterWinController, curve: Interval(_s1Start, _s1End, curve: Curves.easeInOut)),
    );

    // Stage 2: Marks Converge & Line Fades
    _s2ConvergingMarkPositionAnims.clear();
    _s2ConvergingMarkScaleAnims.clear();
    _s2ConvergingMarkOpacityAnims.clear();
    
    double cellWidth = boardSize.width / 3;
    double cellHeight = boardSize.height / 3;
    Offset boardCenter = Offset(boardSize.width / 2, boardSize.height / 2);

    for (int i = 0; i < 3; i++) { // For each of the 3 marks in the winning line
      int cellIndex = _winningCellIndices![i];
      int row = cellIndex ~/ 3;
      int col = cellIndex % 3;
      Offset startPos = Offset(col * cellWidth + cellWidth / 2, row * cellHeight + cellHeight / 2);
      
      _s2ConvergingMarkPositionAnims.add(
        Tween<Offset>(begin: startPos, end: boardCenter).animate(CurvedAnimation(
          parent: _masterWinController, curve: Interval(_s2Start, _s2End, curve: Curves.easeOutCubic)))
      );

      bool isHero = (i == _heroMarkIndexInPattern);
      _s2ConvergingMarkScaleAnims.add(
        Tween<double>(begin: 1.0, end: isHero ? 0.35 : 0.01).animate(CurvedAnimation(
          parent: _masterWinController, curve: Interval(_s2Start, _s2End, curve: Curves.easeOutCubic)))
      );
      _s2ConvergingMarkOpacityAnims.add(
        Tween<double>(begin: 1.0, end: isHero ? 1.0 : 0.0).animate(CurvedAnimation(
          parent: _masterWinController, curve: Interval(_s2Start, _s2End, curve: isHero ? Curves.linear : const Interval(0.0, 0.85, curve: Curves.easeOut)))) // Relative interval
      );
    }
    
    _s2WinningLineOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _masterWinController, curve: Interval(_s2Start, _s2End, curve: const Interval(0.0, 0.7, curve: Curves.easeOut))) // Relative interval
    );
    _s2WinningLineScale = Tween<double>(begin: 1.0, end: 0.01).animate(
      CurvedAnimation(parent: _masterWinController, curve: Interval(_s2Start, _s2End, curve: const Interval(0.0, 0.7, curve: Curves.easeOut))) // Relative interval
    );

    // Stage 3: Grid & Non-Winning Marks Clear
    _s3GridOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(
        parent: _masterWinController, curve: Interval(_s3_4Start, _s3_4End, curve: const Interval(0.0, 0.83, curve: Curves.easeOut)))); // Relative
    _s3GridScale = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(
        parent: _masterWinController, curve: Interval(_s3_4Start, _s3_4End, curve: const Interval(0.0, 0.83, curve: Curves.easeOut)))); // Relative

    _s3NonWinningMarkOpacityAnims.clear();
    _s3NonWinningMarkScaleAnims.clear();
    for (int i = 0; i < _nonWinningCellIndicesStage3.length; i++) {
      _s3NonWinningMarkOpacityAnims.add(Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(
          parent: _masterWinController, curve: Interval(_s3_4Start, _s3_4End, curve: const Interval(0.0, 0.5, curve: Curves.easeOut))))); // Relative
      _s3NonWinningMarkScaleAnims.add(Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(
          parent: _masterWinController, curve: Interval(_s3_4Start, _s3_4End, curve: const Interval(0.0, 0.5, curve: Curves.easeOut))))); // Relative
    }
    
    // Stage 4: Hero Mark Growth
    _s4HeroMarkScaleAnim = Tween<double>(begin: 0.35, end: 2.4).animate(CurvedAnimation(
        parent: _masterWinController, curve: Interval(_s3_4Start, _s3_4End, curve: const Cubic(0.68, -0.55, 0.27, 1.55)))); // Relative interval for curve

    // Add listeners and start animation
    _masterWinController.addListener(_setStateListener);
    _masterWinController.addStatusListener(_masterWinStatusListener);
    
    _masterWinController.forward();
    _pendingWinAnimationSetup = false; // Setup is done
  }

  void _setStateListener() {
    if (mounted) {
      setState(() {});
    }
  }

  void _masterWinStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (mounted) {
        // Potentially call a general onWinAnimationComplete callback if needed by parent
        // For now, just ensure state reflects completion.
        // _isMasterWinAnimationActive might remain true to show final win state.
        // Or set another flag like _hasMasterWinAnimationCompleted = true;
      }
    } else if (status == AnimationStatus.dismissed) {
        // Animation was reset or dismissed
        if (mounted) {
            setState(() {
                _isMasterWinAnimationActive = false;
                 _clearWinAnimationCache(); 
            });
        }
    }
  }
  
  // Combines logic from _calculateWinningLineCoords and determining hero mark
  void _calculateWinningLineData(List<String?> boardCells, Size boardSize) {
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
        winner = p1; // This should match _winAnimationPlayer
        patternIndices = pattern;
        break;
      }
    }

    if (winner == null || patternIndices == null) {
      _winningLineCoords = null;
      _winningCellIndices = null;
      _heroMarkIndexInPattern = null;
      return;
    }
    
    _winningCellIndices = List<int>.from(patternIndices);

    // Determine hero mark index
    if (_winningCellIndices!.contains(4)) { // Cell 4 (center) is part of the win
        _heroMarkIndexInPattern = _winningCellIndices!.indexOf(4);
    } else { // Center is not part of the win, default to the middle mark (index 1) of the 3.
        _heroMarkIndexInPattern = 1; 
    }

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
    if (distance == 0) { // Should not happen for a valid win line
       _winningLineCoords = null; return;
    }
    lineDirection = lineDirection.scale(1 / distance, 1 / distance); 
    
    Offset extendedStart = startCellCenter - lineDirection * extension;
    Offset extendedEnd = endCellCenter + lineDirection * extension;
    
    _winningLineCoords = [extendedStart, extendedEnd];
  }

  void _determineNonWinningCells(GameState gameState) {
    _nonWinningCellIndicesStage3.clear();
    if (_winningCellIndices == null) return;

    for (int i = 0; i < 9; i++) {
      if (!(_winningCellIndices!.contains(i))) {
        if (gameState.miniBoardStates[widget.miniBoardIndex][i] != null) {
          _nonWinningCellIndicesStage3.add(i);
        }
      }
    }
  }

  // Orphaned signature and deprecated method below were removed.
  // List<Offset>? _calculateWinningLineCoords(List<String?> boardCells, Size boardSize) { // REMOVED ORPHANED LINE
  // List<Offset>? _calculateWinningLineCoords_old(List<String?> boardCells, Size boardSize) { ... } // REMOVED METHOD BLOCK

  Future<void> _attemptMoveOnCell(int cellIndexInMiniBoard) async {
      final gameState = Provider.of<GameState>(context, listen: false);
      if (gameState.getCellState(widget.miniBoardIndex, cellIndexInMiniBoard) != null) {
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
    // _winAnimationPlayer = winner; // Set by didUpdateWidget
          _shakeAnimationController.reset();
          _shakeAnimationController.forward();
          return;
      }

      bool moveMade = await gameState.makeMove(widget.miniBoardIndex, cellIndexInMiniBoard);
      if (!moveMade && mounted) {
        _shakeAnimationController.reset();
        _shakeAnimationController.forward();
      }
    }

  @override
  Widget build(BuildContext context) {
    // GameState for actions, not for reactive UI building directly here.
    // Reactive parts will be wrapped in Selectors.
    final gameStateForActions = Provider.of<GameState>(context, listen: false);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size boardSize = constraints.biggest; // Keep only one declaration

        if (_pendingWinAnimationSetup && widget.boardStatus != null && widget.boardStatus != 'DRAW') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_pendingWinAnimationSetup) return;
             _setupWinAnimationsAndStart(boardSize, gameStateForActions); // Use gameStateForActions
          });
        }
        
        // Selector for the miniBoardState relevant to this widget instance
        return Selector<GameState, List<String?>>(
          selector: (_, gameState) => gameState.miniBoardStates[widget.miniBoardIndex],
          shouldRebuild: (previous, next) => previous != next, // Default shallow list comparison is fine
          builder: (context, miniBoardCells, child) {
            // miniBoardCells is now reactively providing the state for this specific mini-board
            
            // The rest of the build logic, using `miniBoardCells` instead of `gameState.getCellState` for marks
            // and `gameStateForActions` for any non-reactive data or actions.

            if (_isMasterWinAnimationActive) {
              List<Widget> winAnimationElements = [];
              double cellWidth = boardSize.width / 3;
              double cellHeight = boardSize.height / 3;
              Offset boardCenter = Offset(boardSize.width / 2, boardSize.height / 2);
              double masterProgress = _masterWinController.value;

              double currentGridOpacity = _s3GridOpacity?.value ?? 1.0;
              double currentGridScale = _s3GridScale?.value ?? 1.0;

              if (currentGridOpacity > 0.0 && currentGridScale > 0.0) {
                winAnimationElements.add(
                  Opacity(
                    opacity: currentGridOpacity,
                    child: Transform.scale(
                      scale: currentGridScale,
                      child: CustomPaint(painter: MiniGridPainter(isPlayable: false, progress: 1.0), size: Size.infinite),
                    ),
                  )
                );
              }

              if (masterProgress < _s3_4Start) {
                for (int cellIndex = 0; cellIndex < 9; cellIndex++) {
                  bool isWinningCell = _winningCellIndices?.contains(cellIndex) ?? false;
                  String? cellMark = miniBoardCells[cellIndex]; // Use selected state

                  if (cellMark != null) {
                    bool partOfConvergingAnimation = isWinningCell && masterProgress >= _s2Start;
                    if (!partOfConvergingAnimation) {
                      if (!isWinningCell && _s3NonWinningMarkOpacityAnims.isNotEmpty) {
                        // Skip, handled by S3 loop
                      } else {
                         winAnimationElements.add(Positioned(
                            left: (cellIndex % 3) * cellWidth, top: (cellIndex ~/ 3) * cellHeight,
                            width: cellWidth, height: cellHeight,
                            child: Opacity( opacity: 1.0, child: Transform.scale( scale: 1.0,
                                child: cellMark == 'X'
                                    ? CustomPaint(painter: XPainter(progress: 1.0), size: Size.infinite)
                                    : CustomPaint(painter: OPainter(progress: 1.0), size: Size.infinite),
                              ),),),);
                      }
                    }
                  }
                }
              }
              
              if (_s1WinningLineProgress != null && _winningLineCoords != null && _winAnimationPlayer != null) {
                double lineProg = _s1WinningLineProgress!.value;
                double lineOpacity = _s2WinningLineOpacity?.value ?? 1.0;
                double lineScale = _s2WinningLineScale?.value ?? 1.0;
                if (lineProg > 0 && masterProgress < _s2End && lineOpacity > 0.01 && lineScale > 0.01) {
                   winAnimationElements.add(Opacity(opacity: lineOpacity, child: Transform.scale(scale: lineScale,
                        child: CustomPaint(painter: WinningLinePainter(
                            lineCoords: _winningLineCoords!, player: _winAnimationPlayer!, progress: lineProg),
                            size: Size.infinite,),),),);
                }
              }

              if (_s2ConvergingMarkPositionAnims.isNotEmpty && _winAnimationPlayer != null) {
                for (int i = 0; i < _s2ConvergingMarkPositionAnims.length; i++) {
                  if (i < _s2ConvergingMarkScaleAnims.length && i < _s2ConvergingMarkOpacityAnims.length) {
                    Offset currentPos = _s2ConvergingMarkPositionAnims[i].value;
                    double currentScale = _s2ConvergingMarkScaleAnims[i].value;
                    double currentOpacity = _s2ConvergingMarkOpacityAnims[i].value;
                    if (currentScale > 0.01 && currentOpacity > 0.01) {
                      Widget markWidget = (_winAnimationPlayer == 'X')
                          ? CustomPaint(painter: XPainter(progress: 1.0), size: Size(cellWidth, cellHeight))
                          : CustomPaint(painter: OPainter(progress: 1.0), size: Size(cellWidth, cellHeight));
                      winAnimationElements.add(Positioned(left: currentPos.dx - (cellWidth / 2 * currentScale),
                          top: currentPos.dy - (cellHeight / 2 * currentScale), width: cellWidth * currentScale,
                          height: cellHeight * currentScale, child: Opacity(opacity: currentOpacity, child: markWidget,),),);
                    }
                  }
                }
              }
              
              if (_s3NonWinningMarkOpacityAnims.isNotEmpty) {
                for (int i = 0; i < _nonWinningCellIndicesStage3.length; i++) {
                  if (i < _s3NonWinningMarkOpacityAnims.length && i < _s3NonWinningMarkScaleAnims.length) {
                    int cellIndex = _nonWinningCellIndicesStage3[i];
                    String? mark = miniBoardCells[cellIndex]; // Use selected state
                    if (mark == null) continue;
                    double opacity = _s3NonWinningMarkOpacityAnims[i].value;
                    double scale = _s3NonWinningMarkScaleAnims[i].value;
                    if (opacity > 0.01 && scale > 0.01) {
                      int r = cellIndex ~/ 3; int c = cellIndex % 3;
                      winAnimationElements.add(Positioned(left: c * cellWidth, top: r * cellHeight,
                          width: cellWidth, height: cellHeight, child: Opacity(opacity: opacity,
                            child: Transform.scale(scale: scale, child: mark == 'X'
                                  ? CustomPaint(painter: XPainter(progress: 1.0), size: Size.infinite)
                                  : CustomPaint(painter: OPainter(progress: 1.0), size: Size.infinite),),),),);
                    }
                  }
                }
              }
              
              if (_s4HeroMarkScaleAnim != null && _winAnimationPlayer != null && _heroMarkIndexInPattern != null) {
                 double heroAnimatedScale = _s4HeroMarkScaleAnim!.value;
                 double heroOpacity = (masterProgress >= _s3_4Start && heroAnimatedScale > 0.01) ? 1.0 : 0.0;
                if (heroAnimatedScale > 0.01 && heroOpacity > 0.0) { 
                  Widget heroMarkWidget = (_winAnimationPlayer == 'X')
                      ? CustomPaint(painter: XPainter(progress: 1.0), size: Size(cellWidth, cellHeight))
                      : CustomPaint(painter: OPainter(progress: 1.0), size: Size(cellWidth, cellHeight));
                  winAnimationElements.add(Positioned(left: boardCenter.dx - (cellWidth / 2 * heroAnimatedScale),
                      top: boardCenter.dy - (cellHeight / 2 * heroAnimatedScale), width: cellWidth * heroAnimatedScale,
                      height: cellHeight * heroAnimatedScale, child: Opacity(opacity: heroOpacity, child: heroMarkWidget,),),);
                }
              }
              
              if (_masterWinController.status == AnimationStatus.completed && widget.boardStatus != null && widget.boardStatus != 'DRAW') {
                winAnimationElements.clear();
                Widget finalMarkWidget = (widget.boardStatus == 'X')
                    ? CustomPaint(painter: XPainter(progress: 1.0), size: Size(cellWidth, cellHeight))
                    : CustomPaint(painter: OPainter(progress: 1.0), size: Size(cellWidth, cellHeight));
                double finalScale = _s4HeroMarkScaleAnim?.value ?? 2.4; 
                if (_s4HeroMarkScaleAnim != null && _masterWinController.value == 1.0) {
                     finalScale = _s4HeroMarkScaleAnim!.drive(Tween<double>(begin:0.35, end:2.4)).value;
                }
                winAnimationElements.add(Positioned(left: boardCenter.dx - (cellWidth / 2 * finalScale),
                    top: boardCenter.dy - (cellHeight / 2 * finalScale), width: cellWidth * finalScale,
                    height: cellHeight * finalScale, child: finalMarkWidget,),);
              }
              
              return AspectRatio(aspectRatio: 1.0, child: Stack(children: winAnimationElements));

            } else if (_isDrawAnimationPlaying) {
                // Draw animation logic
                return AspectRatio(aspectRatio: 1.0, child: Stack(alignment: Alignment.center, children: [
                    Opacity(opacity: 1.0 - _drawFadeOutAnimation.value, child: Transform.scale(scale: 1.0 - (_drawFadeOutAnimation.value * 0.5),
                        child: Stack(children: [
                           CustomPaint(painter: MiniGridPainter(isPlayable: false, progress: 1.0), size: Size.infinite,),
                           GridView.builder(physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3), itemCount: 9,
                              itemBuilder: (context, cellIndex) {
                                String? cellMark = miniBoardCells[cellIndex]; // Use selected state
                                return CellWidget(miniBoardIndex: widget.miniBoardIndex, cellIndexInMiniBoard: cellIndex,
                                    mark: cellMark, isPlayableCell: false, onTap: null,);},),
                        ]),),),
                    Opacity(opacity: _drawSymbolFadeInAnimation.value, child: Transform.scale(scale: _drawSymbolScaleUpAnimation.value,
                        child: const Center(child: Text('½', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.grey)),),),),
                  ],),);
            } else if (widget.boardStatus != null && !_isMasterWinAnimationActive) {
              Widget finalDisplay;
              switch(widget.boardStatus){
                case 'X':finalDisplay=CustomPaint(painter:XPainter(progress:1.0),size:Size.infinite);break;
                case 'O':finalDisplay=CustomPaint(painter:OPainter(progress:1.0),size:Size.infinite);break;
                case 'DRAW':finalDisplay=const Center(child:Text('½',style:TextStyle(fontSize:40,fontWeight:FontWeight.bold,color:Colors.grey)));break;
                default:finalDisplay=const SizedBox.shrink();
              }
              return AspectRatio(aspectRatio:1.0,child:Container(child:finalDisplay));
            } else {
              // Default view: Playable or empty grid
              return SlideTransition(position: _shakeAnimation, child: AspectRatio(aspectRatio:1.0,
                  child:CustomPaint(painter:MiniGridPainter(isPlayable:widget.isPlayable,progress:_miniGridAnimation.value),
                    child:(_miniGridAnimation.value==1.0)
                        ?GridView.builder(physics:const NeverScrollableScrollPhysics(),
                            gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3),itemCount:9,
                            itemBuilder:(c,ci){
                              String? m = miniBoardCells[ci]; // Use selected state
                              bool iCAP=widget.isPlayable && m==null;
                              return CellWidget(miniBoardIndex:widget.miniBoardIndex,cellIndexInMiniBoard:ci,mark:m,isPlayableCell:iCAP,onTap:()=>_attemptMoveOnCell(ci));
                            })
                        :const SizedBox.shrink()
                  ),),);
            }
          }
        );
      }
    );
  }
}
