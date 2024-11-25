import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mac_dock_v2/models/dock_data_snapshot.dart';
import 'package:mac_dock_v2/widgets/dock/dock_controller.dart';

part 'package:mac_dock_v2/widgets/dock/dock_item/item_components_part.dart';

/// Animated widget of DockItem, containing state with all animation controllers
class AnimatedDockItemWidget extends StatefulWidget {
  const AnimatedDockItemWidget({
    super.key,
    required this.index,
    required this.dockController,
    required this.iconData,
  });

  final int index;
  final DockController dockController;
  final IconData iconData;

  @override
  State<AnimatedDockItemWidget> createState() => AnimatedDockItemWidgetState();
}

class AnimatedDockItemWidgetState extends State<AnimatedDockItemWidget>
    with TickerProviderStateMixin {
  /// Controller for positioning overlay widget on the screen while dragging
  late final AnimationController _controllerDragPositioning;
  /// Controller for positioning overlay back to [targetIndex] or previous spot
  late final AnimationController _controllerBackPositioning;
  /// Controller controlling rotation animation of widget
  late final AnimationController _controllerRotation;
  /// Controller controlling sliding animation of widget
  late final AnimationController _controllerSliding;

  late Animation<double> rotationTween;
  late final Animation<Offset> _slidingTween;

  @override
  void initState() {
    // Initialization of controllers
    _controllerDragPositioning = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 50));
    _controllerBackPositioning = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _controllerRotation = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _controllerSliding = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));

    // Initializations of Tweens
    _slidingTween = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -10))
        .animate(
            CurvedAnimation(parent: _controllerSliding, curve: Curves.ease));

    // Status listener for sliding animation it chained to rotation animation.
    // When sliding animation completed widget start to rotate(shake).
    _controllerSliding.addStatusListener((status) {
      switch (status) {
        case AnimationStatus.dismissed:
          setState(() {
            _rotationValue = 0;
            _controllerRotation.reset();
          });
        case AnimationStatus.completed:
          setState(() {
            _rotationValue = -0.012;
            _controllerRotation.repeat(reverse: true);
          });
        default:
          return;
      }
    });

    // Necessary for updating overlay position while animating to the right spot
    _controllerBackPositioning
        .addListener(() => _overlayEntry?.markNeedsBuild());

    super.initState();
  }

  @override
  void dispose() {
    _controllerRotation.dispose();
    _controllerSliding.dispose();
    _controllerDragPositioning.dispose();
    _controllerBackPositioning.dispose();
    super.dispose();
  }

  /// Value setting the begin of tween rotation.
  double _rotationValue = 0;

  /// After drag is started offset will translate through delta. Used for back
  /// positioning.
  Offset pointerOffset = Offset.zero;

  /// Dynamic duration of expanding widgets. Depend on [shrinkDurationAfterInsertionCompleted]
  /// from [DockController]
  Duration get _expandingDuration => Duration(
      milliseconds: widget.dockController.shrinkDurationAfterInsertionCompleted
          ? 0
          : 250);

  /// Getter for size of left padding for dock item
  double get _leftExpansionValue =>
      widget.dockController.isExpandedLeft(widget.index) ? 68 : 0;

  /// Getter for size of left padding for dock item
  double get _rightExpansionValue =>
      widget.dockController.isExpandedRight(widget.index) ? 68 : 0;

  /// Overlay entry will contain animated widget that can be dragged.
  OverlayEntry? _overlayEntry;

  /// Function for inserting overlay to the screen at the right position, with
  /// the right size. Entry contains IgnorePointer, so expanding through
  /// [_StartSideExpandingListener] could be possible.
  void _showOverlay(BuildContext context) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset position = box.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
        maintainState: true,
        builder: (overlayContext) {
          Offset endOffset = widget.dockController
              .calculateBackToIndexCorrection(pointerOffset);

          final rotationTween = Tween<double>(begin: _rotationValue, end: 0.012)
              .animate(_controllerRotation);
          final positioningTween =
              Tween<Offset>(begin: Offset.zero, end: endOffset).animate(
                  CurvedAnimation(
                      parent: _controllerBackPositioning,
                      curve: Curves.easeOutExpo));

          return Positioned(
            top: position.dy,
            left: position.dx,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controllerDragPositioning,
                builder: (BuildContext context, Widget? child) {
                  return Transform.translate(
                    offset: pointerOffset,
                    child: child,
                  );
                },
                child: AnimatedBuilder(
                  animation: positioningTween,
                  builder: (BuildContext context, Widget? child) {
                    return Transform.translate(
                      offset: positioningTween.value,
                      child: child,
                    );
                  },
                  child: Transform.translate(
                    offset: const Offset(0, -10),
                    child: RotationTransition(
                        turns: rotationTween,
                        child: _BaseDockItem(iconData: widget.iconData)),
                  ),
                ),
              ),
            ),
          );
        });

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Function for removing overlay from the screen
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;
  }

  /// Callback handling actions on pointer hover event. Start sliding animation
  /// if possible
  void _onPointerHover(PointerHoverEvent event) {
    if (!widget.dockController.isItemsIdle ||
        widget.dockController.isAnimatingBackToSlot ||
        widget.dockController.isAnimatingTarget) return;

    if (!_controllerSliding.isAnimating) {
      _controllerSliding.forward();
    }
  }

  /// Callback handling actions on pointer down event. Start drag positioning
  /// animation necessary for dragging overlay to the new position.
  void _onPointerDown(PointerDownEvent event) {
    if (!widget.dockController.isItemsIdle ||
        widget.dockController.isAnimatingBackToSlot ||
        widget.dockController.isAnimatingTarget) return;

    setState(() {
      widget.dockController.handleOnPointerDown(widget.index);
    });
    _controllerDragPositioning.repeat();
    _showOverlay(context);
  }

  /// Callback handling actions on pointer up event. Preparing [DockDataSnapshot]
  /// reset sliding,rotation and drag positioning controllers, also starts
  /// back positioning animation with provided callback.
  void _onPointerUp(PointerUpEvent event) {
    if (!widget.dockController.isDragging ||
        widget.dockController.isAnimatingBackToSlot ||
        widget.dockController.isAnimatingTarget) return;

    widget.dockController.prepareDockDataSnapshot();

    _rotationValue = 0;
    _controllerDragPositioning.reset();
    _controllerRotation.reset();
    _controllerSliding.reset();

    _controllerBackPositioning.forward().then((_) {
      pointerOffset = Offset.zero;
      _controllerBackPositioning.reset();
      widget.dockController.shrinkDurationAfterInsertionCompleted = true;
      _removeOverlay();
      widget.dockController.onTryReorder();
    });
  }

  /// Callback handling actions on pointer move event. Update [pointerOffset]
  /// with [delta] provided from [PointerMoveEvent]. Calculating is dragged item
  /// is outside of the dock and updating controller [isOutSideDock] field
  /// respectfully. Update the whole Dock through controller function [rebuildDock]
  void _onPointerMove(PointerMoveEvent event) {
    if (!widget.dockController.isDragging) return;

    pointerOffset += event.delta;

    final box =
        context.findAncestorRenderObjectOfType<RenderFlex>() as RenderBox;
    final localPosition = box.globalToLocal(event.position);

    final isOutsideHorizontal =
        localPosition.dx > box.size.width || localPosition.dx < 0;
    final isOutsideVertical =
        localPosition.dy > box.size.height || localPosition.dy < 0;

    if (widget.dockController.isOutsideDock !=
        (isOutsideVertical || isOutsideHorizontal)) {
      widget.dockController.isOutsideDock =
          isOutsideHorizontal || isOutsideVertical;

      if (widget.dockController.isOutsideDock) {
        widget.dockController.isInitialSpotShowing = false;
        widget.dockController.pointerItemIndex = null;
        widget.dockController.expandedSide = ExpandedSide.none;
      }

      widget.dockController.rebuildDock();
    }
  }

  /// Callback handling actions on pointer exit event. Used for reversing sliding
  /// animation through [_controllerSliding] controller.
  void _onExitItem(PointerExitEvent event) {
    if (!widget.dockController.isDragging) {
      _controllerSliding.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rotationTween = Tween<double>(begin: _rotationValue, end: 0.012)
        .animate(_controllerRotation);

    return AnimatedPadding(
      duration: _expandingDuration,
      padding: EdgeInsets.only(
        left: _leftExpansionValue,
        right: _rightExpansionValue,
      ),
      child: widget.dockController.isShowAnimatedDummySlot(widget.index)
          ? _AnimatedDummySlot(dockController: widget.dockController)
          : MouseRegion(
              hitTestBehavior: HitTestBehavior.translucent,
              onExit: _onExitItem,
              child: AnimatedBuilder(
                animation: _slidingTween,
                builder: (context, child) {
                  return Transform.translate(
                    offset: _slidingTween.value,
                    child: child,
                  );
                },
                child: RotationTransition(
                    turns: rotationTween,
                    child: Listener(
                      behavior: HitTestBehavior.translucent,
                      onPointerHover: _onPointerHover,
                      onPointerDown: _onPointerDown,
                      onPointerUp: _onPointerUp,
                      onPointerMove: _onPointerMove,
                      child: _StartSideExpandingListener(
                          index: widget.index,
                          dockController: widget.dockController,
                          child: _BaseDockItem(iconData: widget.iconData)),
                    )),
              ),
            ),
    );
  }
}
