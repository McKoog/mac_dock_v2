part of 'package:mac_dock_v2/widgets/dock/dock_item/dock_item_widget.dart';

/// Base UI widget of DockItem with icon
class _BaseDockItem extends StatelessWidget {
  const _BaseDockItem({
    required this.iconData,
  });

  final IconData iconData;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.primaries[iconData.hashCode % Colors.primaries.length],
      ),
      child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(iconData, color: Colors.white),
          )),
    );
  }
}

/// Animated widget showing empty space under the dragged item from
/// [isInitialSpotShowing] controller field.
class _AnimatedDummySlot extends StatelessWidget {
  const _AnimatedDummySlot({required this.dockController});

  final DockController dockController;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
        duration: const Duration(milliseconds: 250),
        child: SizedBox(
          height: dockController.isInitialSpotShowing ? 68 : 0,
          width: dockController.isInitialSpotShowing ? 68 : 0,
        ));
  }
}

/// Widget the creates two [MouseRegion] in stack over the [child] widget at it's
/// size. Then listening for pointer entering [left] and [right] zones and updates
/// controller values respectfully.
class _StartSideExpandingListener extends StatelessWidget {
  const _StartSideExpandingListener(
      {required this.index, required this.dockController, required this.child});

  final int index;
  final DockController dockController;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        MouseRegion(
          onEnter: (event) => dockController.handleStartExpanding(
              ExpandedSide.left, event, index),
          child: const SizedBox(
            height: 68,
            width: 34,
          ),
        ),
        Positioned(
          left: 34,
          child: MouseRegion(
            onEnter: (event) => dockController.handleStartExpanding(
                ExpandedSide.right, event, index),
            child: const SizedBox(
              height: 68,
              width: 34,
            ),
          ),
        ),
      ],
    );
  }
}