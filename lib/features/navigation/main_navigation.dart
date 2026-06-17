import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/interfaces.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme.dart';
import '../home/home_screen.dart';
import '../profile/explorations_screen.dart';
import '../scan/scan_qr_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  late StreamSubscription<User?> _authSubscription;

  void setIndex(int index) {
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _authSubscription = ServiceLocator.authService.onAuthStateChanged.listen((
      user,
    ) {
      if (mounted) {
        setState(() {
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
      const ExplorationsScreen(),
      const ScanQrScreen(),
      const ProfileScreen(),
    ];
  }

  List<NavigationDestination> _getNavBarItems() {
    return const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: "Accueil",
      ),
      NavigationDestination(
        icon: Icon(Icons.bookmark_border_rounded),
        selectedIcon: Icon(Icons.bookmark_rounded),
        label: "A explorer",
      ),
      NavigationDestination(
        icon: Icon(Icons.qr_code_scanner_outlined),
        selectedIcon: Icon(Icons.qr_code_scanner),
        label: "Scanner",
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person),
        label: "Profil",
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pages = _getPages();
    final destinations = _getNavBarItems();

    // Note de soutenance : Choix de NavigationBar (Material 3) plutôt que BottomNavigationBar
    // pour offrir une expérience utilisateur moderne conforme aux recommandations actuelles de Flutter.
    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: const Color(0xFFFDFBF7),
        indicatorColor: AppColors.terracotta.withValues(alpha: 0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: destinations,
      ),
    );
  }
}
