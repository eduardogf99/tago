import 'package:flutter/material.dart';

class AppNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.wifi),
          label: '',
        ),
        NavigationDestination(
          icon: Icon(Icons.map),
          label: '',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book),
          label: '',
        ),
      ],
    );
  }
}
