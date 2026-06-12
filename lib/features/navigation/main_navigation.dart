import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/interfaces.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme.dart';
import '../home/home_screen.dart';
import '../discover/discover_screen.dart';
import '../scan/scan_qr_screen.dart';
import '../profile/profile_screen.dart';
import '../auth/login_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  late StreamSubscription<User?> _authSubscription;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = ServiceLocator.authService.currentUser;
    _authSubscription = ServiceLocator.authService.onAuthStateChanged.listen((
      user,
    ) {
      if (mounted) {
        setState(() {
          _currentUser = user;
          // Si l'index actuel dépasse le nombre d'onglets dispo pour le nouveau rôle, on le réinitialise
          final tabsCount = _getTabsCount();
          if (_currentIndex >= tabsCount) {
            _currentIndex = 0;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  int _getTabsCount() {
    return 4;
  }

  void _goToProfileTab() {
    setState(() {
      _currentIndex = 3;
    });
  }

  List<Widget> _getPages() {
    return [
      HomeScreen(onProfileTap: _goToProfileTab),
      const DiscoverScreen(),
      const ScanQrScreen(),
      const ProfileScreen(),
    ];
  }

  List<BottomNavigationBarItem> _getNavBarItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: "Accueil",
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.explore_outlined),
        activeIcon: Icon(Icons.explore),
        label: "Découvrir",
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.qr_code_scanner_outlined),
        activeIcon: Icon(Icons.qr_code_scanner),
        label: "Scanner",
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline_rounded),
        activeIcon: Icon(Icons.person),
        label: "Profil",
      ),
    ];
  }

  void _showRoleSwitcherSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.creme,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Simulateur de Rôles (Débogage)",
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Basculez instantanément d'un profil à l'autre pour tester tous les cas d'utilisation.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grisTexte, fontSize: 13),
              ),
              const Divider(height: 24, color: AppColors.grisBordure),

              _buildRoleTile(
                "visiteur",
                "Visiteur anonyme",
                Icons.visibility,
                Colors.grey,
              ),
              _buildRoleTile(
                "utilisateur",
                "Utilisateur inscrit (Marie L.)",
                Icons.person,
                AppColors.sauge,
              ),
              _buildRoleTile(
                "gerant",
                "Gérant de restaurant (Chez Marcel)",
                Icons.restaurant,
                AppColors.terracotta,
              ),
              _buildRoleTile(
                "admin",
                "Administrateur de l'app",
                Icons.admin_panel_settings,
                Colors.blue,
              ),

              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ServiceLocator.authService.logout();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.rougeSignalement,
                  side: const BorderSide(color: AppColors.rougeSignalement),
                ),
                child: const Text("Déconnexion"),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoleTile(String role, String label, IconData icon, Color color) {
    final isSelected =
        (_currentUser?.role == role) ||
        (role == 'visiteur' && _currentUser == null);

    return ListTile(
      leading: Icon(icon, color: isSelected ? color : AppColors.grisTexte),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.marronFonce : AppColors.grisTexte,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check_circle, color: color) : null,
      onTap: () {
        ServiceLocator.authService.setRole(role);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Bascule vers le rôle : ${label.split(' (').first}"),
            backgroundColor: color,
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = _getPages();
    final items = _getNavBarItems();

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.grisBordure, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFFFDFBF7),
          selectedItemColor: AppColors.terracotta,
          unselectedItemColor: AppColors.grisTexte.withValues(alpha: 0.6),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
          ),
          items: items,
        ),
      ),

      // Bouton de débogage pour basculer facilement de rôle
      floatingActionButton: FloatingActionButton(
        onPressed: _showRoleSwitcherSheet,
        backgroundColor: AppColors.cremeFonce,
        mini: true,
        tooltip: "Changer de rôle",
        child: const Icon(
          Icons.settings,
          color: AppColors.marronFonce,
          size: 20,
        ),
      ),
    );
  }
}
