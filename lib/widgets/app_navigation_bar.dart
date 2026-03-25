import 'package:flutter/material.dart';

class AppNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isAdmin;

  const AppNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      backgroundColor: Colors.blue.shade200,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: [
        if(isAdmin)
          const NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: '',
          ),

        const NavigationDestination(
          icon: Icon(Icons.map),
          label: '',
        ),
        const NavigationDestination(
          icon: Icon(Icons.menu_book),
          label: '',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person),
          label: '',
        ),
      ],
    );
  }
}
