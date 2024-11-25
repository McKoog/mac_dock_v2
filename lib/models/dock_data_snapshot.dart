enum ExpandedSide { left, right, none }

/// DockDataSnapshot model containing snapshot of controller state at some point
/// of time, when drag is over.
class DockDataSnapshot {
  DockDataSnapshot({
    required this.targetIndex,
    required this.pointerItemIndex,
    required this.draggedIndex,
    required this.expandedSide,
  });

  final int draggedIndex;
  final int targetIndex;
  final int pointerItemIndex;
  final ExpandedSide expandedSide;
}