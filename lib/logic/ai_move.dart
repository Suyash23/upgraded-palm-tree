// In lib/logic/ai_move.dart
class AIMove {
  final int miniBoardIndex;
  final int cellIndex;

  AIMove(this.miniBoardIndex, this.cellIndex);

  // New method to add
  String toStringShort() {
    return "$miniBoardIndex-$cellIndex";
  }
}
