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
      backgroundColor: new Color.fromRGBO(212, 175, 55, 1),
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: [
        if(isAdmin)
          const NavigationDestination(
            icon: Icon(Icons.add_circle_outline, color: Color.fromRGBO(122, 30, 44, 1),),
            label: '',
          ),

        const NavigationDestination(
          icon: Icon(
            Icons.map,
            color: Color.fromRGBO(122, 30, 44, 1),
          ),
          label: '',
        ),
        const NavigationDestination(
          icon: Icon(
            Icons.menu_book,
            color: Color.fromRGBO(122, 30, 44, 1),
          ),
          label: '',
        ),
        if(isAdmin)
          const NavigationDestination(
            icon: Icon(Icons.rebase_edit, color: Color.fromRGBO(122, 30, 44, 1),),
            label: '',
          ),
        const NavigationDestination(
          icon: Icon(Icons.person, color: Color.fromRGBO(122, 30, 44, 1),),
          label: '',
        ),
      ],
    );
  }
}
