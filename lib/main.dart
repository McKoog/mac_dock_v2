import 'package:flutter/material.dart';
import 'package:mac_dock_v2/widgets/dock/dock_item/dock_item_widget.dart';
import 'package:mac_dock_v2/widgets/dock/dock_widget.dart';
import 'package:mac_dock_v2/models/dock_item.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height,
      width: MediaQuery.sizeOf(context).width,
      color: Colors.deepPurple.shade800.withOpacity(0.4),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 16,
            child: Dock<DockItem>(
              dockItems: [
                DockItem(iconData: Icons.person),
                DockItem(iconData: Icons.message),
                DockItem(iconData: Icons.call),
                DockItem(iconData: Icons.camera),
                DockItem(iconData: Icons.photo),
              ],
              builder: (index, dockController, dockItem, updateDock) {
                return AnimatedDockItemWidget(
                  index: index,
                  dockController: dockController,
                  iconData: dockItem.iconData,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
