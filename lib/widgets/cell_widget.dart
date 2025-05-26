import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/game_state.dart';
import '../themes/color_schemes.dart'; // Assuming this path
import '../painters/x_painter.dart';
import '../painters/o_painter.dart';

class CellWidget extends StatefulWidget {
  final int miniBoardIndex;
  final int cellIndexInMiniBoard;
  final String? mark;
  final bool isPlayableCell;
  final VoidCallback? onTap;

  const CellWidget({
    super.key,
    required this.miniBoardIndex,
    required this.cellIndexInMiniBoard,
    this.mark,
    required this.isPlayableCell,
    this.onTap,
  });

  @override
  State<CellWidget> createState() => _CellWidgetState();
}

class _CellWidgetState extends State<CellWidget> with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _markController;
  late Animation<double> _markAnimation;

  @override
  void initState() {
    super.initState();
    _markController = AnimationController(
      // Duration will be set based on mark type when animation starts
      vsync: this,
    );
    _markAnimation = CurvedAnimation(
      parent: _markController,
      curve: Curves.linear, // Or a specific curve for mark drawing
    )..addListener(() {
        setState(() {});
      });

    // If widget initializes with a mark, show it fully drawn (no animation)
    if (widget.mark != null) {
      _markController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant CellWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If mark changes from null to X or O, start animation
    if (widget.mark != null && oldWidget.mark == null) {
      if (widget.mark == 'X') {
        _markController.duration = const Duration(milliseconds: 450); // e.g. line1=300ms, delay=150ms for line2 start
      } else if (widget.mark == 'O') {
        _markController.duration = const Duration(milliseconds: 400); // As per spec
      }
      _markController.reset();
      _markController.forward();
    } else if (widget.mark == null && oldWidget.mark != null) {
      // Mark is removed, reset controller (marks will instantly disappear)
      _markController.reset();
    }
  }

  @override
  void dispose() {
    _markController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context, listen: false); // Or listen:true if other parts depend
    final AppColorScheme scheme = gameState.currentColorScheme;

    return MouseRegion(
      onEnter: (_) { if (widget.isPlayableCell) setState(() => _isHovering = true); },
      onExit: (_) { if (_isHovering) setState(() => _isHovering = false); },
      cursor: widget.isPlayableCell ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap, // Changed to be unconditional
        child: Container(
          decoration: BoxDecoration(
            color: _isHovering && widget.isPlayableCell ? Colors.yellow[100] : Colors.transparent,
          ),
          child: Center(
            child: _buildMark(),
          ),
        ),
      ),
    );
  }

  Widget _buildMark(AppColorScheme scheme) { // Pass scheme to _buildMark
    if (widget.mark == 'X') {
      return CustomPaint(
        painter: XPainter(progress: _markAnimation.value, color: scheme.xColor),
        size: Size.infinite,
      );
    } else if (widget.mark == 'O') {
      return CustomPaint(
        painter: OPainter(progress: _markAnimation.value, color: scheme.oColor),
        size: Size.infinite,
      );
    }
    return const SizedBox.shrink();
  }
}
