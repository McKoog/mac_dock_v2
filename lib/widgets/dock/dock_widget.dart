import 'package:flutter/material.dart';
import 'package:mac_dock_v2/models/dock_item.dart';
import 'package:mac_dock_v2/widgets/dock/dock_controller.dart';

/// Dock of the reorderable [items].
class Dock<T> extends StatefulWidget {
  const Dock(
      {super.key, required this.dockItems, required this.builder});

  /// Initial [T] items to put in this [Dock].
  final List<DockItem> dockItems;

  /// Builder building the provided [T] item.
  final Widget Function(int index, DockController dockController, DockItem item, void Function() rebuildDock) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

class _DockState<T> extends State<Dock<T>> {

  /// Dock controller containing all necessary functions and variables for dock
  late final DockController _dockController;

  @override
  void initState() {
    _dockController = DockController(dockItems: widget.dockItems, rebuildDock: _rebuildDock);
    super.initState();
  }

  /// Callback passed to items, necessary for updating whole dock from it's
  /// child widgets
  void _rebuildDock() => setState(() {});

  /// Function for getting index of [T] item
  int _getCurrentItemIndex(DockItem dockItem){
    return _dockController.dockItems.indexOf(dockItem);
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.4),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _dockController.dockItems.map((dockItem) => widget.builder(_getCurrentItemIndex(dockItem),_dockController,dockItem,_rebuildDock)).toList(),
      ),
    );
  }
}