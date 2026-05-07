import 'package:flutter/material.dart';
import 'package:tfg/screens/manage_admins_screen.dart';
import 'package:tfg/screens/ranking_screen.dart';
import 'package:tfg/services/auth_service.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'map_admin_screen.dart';
import 'library_screen.dart';
import '../widgets/app_navigation_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isAdmin = false;
  bool _isLoading = true;
  
  PageController _pageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  // Comprobamos si el usuario tiene permisos de administrador para mostrar pestañas extra
  Future<void> _checkAdminStatus() async {
    final userData = await AuthService().getUserData();
    if (mounted) {
      setState(() {
        _isAdmin = userData?.isAdmin ?? false;
        
        // Ajustamos el índice inicial según el rol
        _selectedIndex = _isAdmin ? 1 : 0;
        
        _pageController.dispose(); 
        _pageController = PageController(initialPage: _selectedIndex);
        
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Definición de las pantallas que componen el menú inferior
    final List<Widget> pages = [
      if (_isAdmin) const MapAdminScreen(),
      const MapScreen(),
      const LibraryScreen(),
      if (_isAdmin) const ManageAdminsScreen(),
      const RankingScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        physics: const NeverScrollableScrollPhysics(),
        children: pages,
      ),
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: _selectedIndex,
        isAdmin: _isAdmin,
        onDestinationSelected: (index) {
          // Animación suave al cambiar de pestaña
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      ),
    );
  }
}
