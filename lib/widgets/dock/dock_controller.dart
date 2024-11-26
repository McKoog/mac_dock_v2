import 'package:flutter/gestures.dart';
import 'package:mac_dock_v2/models/dock_data_snapshot.dart';
import 'package:mac_dock_v2/models/dock_item.dart';

/// Dock controller containing all necessary functions and variables for dock
class DockController {
  DockController({required this.dockItems, required this.rebuildDock});

  /// Current List of [DockItem] in the dock, can be updated by swapping items in it
  final List<DockItem> dockItems;

  /// Callback for updating whole dock
  final void Function() rebuildDock;

  /// Getter for getting is dock currently idle(all data at a stock state)
  bool get isItemsIdle =>
      isDragging == false &&
      isOutsideDock == false &&
      pointerItemIndex == null &&
      expandedSide == ExpandedSide.none &&
      targetIndex == null &&
      dockDataSnapshot == null &&
      !isAnimatingTarget &&
      !isAnimatingBackToSlot;

  /// Is any item being dragged
  bool get isDragging => draggedIndex != null;
  /// Is ant item is outside of the dock field
  bool isOutsideDock = false;

  /// Currently selected index of [DockItem] being hovered with pointer
  int? pointerItemIndex;
  /// Currently dragged index of [DockItem]
  int? draggedIndex;
  /// Calculated index for dropping [DockItem] to new position in Dock
  int? targetIndex;
  /// Currently expanded side of [DockItem]. Can be in 3 states [none],[left],
  /// [right]. Padding will be applied to the element at that side.
  ExpandedSide expandedSide = ExpandedSide.none;

  /// Snapshot of current state for different calculations in the future. State
  /// of controller is very dynamically changed, so we need snapshot of all the
  /// data at the right moment
  DockDataSnapshot? dockDataSnapshot;

  /// Flag for showing empty space under the initially selected [DockItem]
  bool isInitialSpotShowing = true;

  /// Flag giving information about current state of positioning [DockItem]
  /// after calculations of [targetIndex], if it's a new position then this flag
  /// should be true
  bool isAnimatingTarget = false;
  /// Flag giving information about current state of positioning [DockItem]
  /// after calculations of [targetIndex], if it's an old position then this flag
  /// should be true
  bool isAnimatingBackToSlot = false;

  /// Flag for correcting animation timing for expanded sides. After animation
  /// completes and item got to the new spot it'll tell current expanded item to
  /// instantly shrink
  bool shrinkDurationAfterInsertionCompleted = false;

  /// Showing is item at [index] is expanded to the left side
  bool isExpandedLeft(int index) =>
      expandedSide == ExpandedSide.left && pointerItemIndex == index;

  /// Showing is item at [index] is expanded to the right side
  bool isExpandedRight(int index) =>
      expandedSide == ExpandedSide.right && pointerItemIndex == index;

  /// Showing if animated dummy slot should show instead of current [DockItem]
  bool isShowAnimatedDummySlot(int index) =>
      (isDragging && draggedIndex == index) ||
      isAnimatingBackToSlot ||
      isAnimatingTarget;

  /// Callback changing controller data for selected [DockItem]
  void handleOnPointerDown(int index) {
    shrinkDurationAfterInsertionCompleted = false;
    isInitialSpotShowing = true;
    pointerItemIndex = index;
    draggedIndex = index;
  }

  /// Callback for [_StartSideExpandingListener], will fill all data necessary
  /// for expanding of [DockItem] to the right side - [left],[right].
  void handleStartExpanding(
      ExpandedSide side, PointerEnterEvent event, int index) {
    if ((!isDragging) || (isAnimatingBackToSlot || isAnimatingTarget)) return;

    isInitialSpotShowing = false;
    pointerItemIndex = index;
    expandedSide = side;

    rebuildDock();
  }

  /// Function calculating Offset correction for overlay widget to place it,
  /// to the right spot in the dock.
  Offset calculateBackToIndexCorrection(Offset pointerOffset) {
    if (dockDataSnapshot == null) return -pointerOffset.translate(0, -10);

    int diff = dockDataSnapshot!.draggedIndex - dockDataSnapshot!.targetIndex;

    Offset remainder = Offset(pointerOffset.dx + (diff * 68), 0);

    Offset correction = Offset(0, pointerOffset.dy - 10);

    if (diff == 0) {
      correction = correction.translate(pointerOffset.dx, 0);
    } else {
      correction = correction.translate(remainder.dx, 0);
    }

    return -correction;
  }

  /// Function calculating necessary [targetIndex] for future placing it.
  void calculateTargetIndex() {
    if (pointerItemIndex == null || draggedIndex == null) return;

    switch (expandedSide) {
      case ExpandedSide.left:
        if (draggedIndex! < pointerItemIndex!) {
          targetIndex = pointerItemIndex! - 1;
        } else {
          targetIndex = pointerItemIndex!;
        }

      case ExpandedSide.right:
        if (draggedIndex! > pointerItemIndex!) {
          targetIndex = pointerItemIndex! + 1;
        } else {
          targetIndex = pointerItemIndex!;
        }

      case ExpandedSide.none:
        return;
    }
  }

  /// Function creating snapshot of current data if it's necessary. If possible
  /// will create snapshot at [dockDataSnapshot] if not, it'll be null. Be careful
  /// this function reset controller main state and set flags for future animations.
  void prepareDockDataSnapshot() {
    calculateTargetIndex();
    if (targetIndex == null ||
        (targetIndex != null &&
            draggedIndex != null &&
            targetIndex == draggedIndex)) {
      isInitialSpotShowing = !(targetIndex != null);

      isOutsideDock = false;
      pointerItemIndex = null;
      expandedSide = ExpandedSide.none;
      draggedIndex = null;
      targetIndex = null;

      isAnimatingBackToSlot = true;
      return;
    }

    dockDataSnapshot = DockDataSnapshot(
        targetIndex: targetIndex!,
        pointerItemIndex: pointerItemIndex!,
        draggedIndex: draggedIndex!,
        expandedSide: expandedSide);

    isOutsideDock = false;
    pointerItemIndex = null;
    expandedSide = ExpandedSide.none;
    draggedIndex = null;
    targetIndex = null;

    isInitialSpotShowing = false;
    isAnimatingTarget = true;
  }

  /// Function starting reordering if [dockDataSnapshot] is not null. Swap items
  /// from [draggedIndex] to [targetIndex] from current snapshot. Be careful, this
  /// function fully rebuild UI of all Dock
  void onTryReorder() {
    if (dockDataSnapshot == null) {
      isAnimatingBackToSlot = false;
      isInitialSpotShowing = true;
      return;
    }

    final dockItem = dockItems[dockDataSnapshot!.draggedIndex];

    if (dockDataSnapshot!.targetIndex != dockDataSnapshot!.draggedIndex) {
      dockItems
        ..removeAt(dockDataSnapshot!.draggedIndex)
        ..insert(dockDataSnapshot!.targetIndex, dockItem);
    }

    isAnimatingTarget = false;
    isInitialSpotShowing = true;
    dockDataSnapshot = null;
    rebuildDock();
  }
}
