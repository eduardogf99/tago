import 'package:flutter/material.dart';
import 'package:tfg/services/auth_service.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'create_nfc_screen.dart';
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
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final userData = await AuthService().getUserData();
    if (mounted) {
      setState(() {
        _isAdmin = userData?.isAdmin ?? false;
        // Si es admin, empezamos en el mapa (índice 1). Si no, en el mapa (índice 0).
        _selectedIndex = _isAdmin ? 1 : 0;
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

    // Generamos la lista de páginas dinámicamente
    final List<Widget> pages = [
      if (_isAdmin) const CreateNfcScreen(),
      const MapScreen(),
      const Center(child: Text('Pantalla Libro')),
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
        physics: const NeverScrollableScrollPhysics(), // Evita desajustes de índice al deslizar
        children: pages,
      ),
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: _selectedIndex,
        isAdmin: _isAdmin,
        onDestinationSelected: (index) {
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
