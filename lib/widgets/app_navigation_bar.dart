import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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
      backgroundColor: AppColors.azulOscuro,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      indicatorColor: AppColors.azulContenedor,
      destinations: [
        if(isAdmin)
          const NavigationDestination(
            icon: Icon(Icons.add_circle_outline, color: AppColors.doradoClaro,),
            label: '',
          ),

        const NavigationDestination(
          icon: Icon(
            Icons.map,
            color: AppColors.doradoClaro,
          ),
          label: '',
        ),
        const NavigationDestination(
          icon: Icon(
            Icons.menu_book,
            color: AppColors.doradoClaro,
          ),
          label: '',
        ),
        if(isAdmin)
          const NavigationDestination(
            icon: Icon(Icons.rebase_edit, color: AppColors.doradoClaro),
            label: '',
          ),
        const NavigationDestination(
          icon: Icon(
            Icons.leaderboard,
            color: AppColors.doradoClaro,
          ),
          label: '',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person, color: AppColors.doradoClaro),
          label: '',
        ),
      ],
    );
  }
}
