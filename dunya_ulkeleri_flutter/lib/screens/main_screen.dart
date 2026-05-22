// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 🚨 YENİ EKLENDİ
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/settings_provider.dart'; // 🚨 YENİ EKLENDİ
import '../widgets/geo_bottom_nav.dart';
import 'dashboard_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'leaderboard_screen.dart';
import 'world_map_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final Set<int> _loadedTabs = <int>{0};
  bool _didBootstrapProfile = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didBootstrapProfile) return;
    _didBootstrapProfile = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final token = context.read<AuthProvider>().token;
      if (token == null || token.trim().isEmpty) return;
      context.read<ProfileProvider>().refresh(token);
    });
  }

  void _setTabIndex(int index) {
    if (!mounted) return;
    setState(() {
      _currentIndex = index;
      _loadedTabs.add(index);
    });
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return DashboardScreen(
          onNavigateTab: _setTabIndex,
          isActive: _currentIndex == 0,
        );
      case 1:
        return const HomeScreen(); // Oyun
      case 2:
        return const WorldMapScreen(); // Dünya Haritası
      case 3:
        return const LeaderboardScreen(); // Sıralama
      case 4:
        return ProfileScreen(
          onNavigateTab: _setTabIndex,
          isActive: _currentIndex == 4,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = List<Widget>.generate(
      5,
      (index) => _loadedTabs.contains(index)
          ? _buildScreen(index)
          : const SizedBox.shrink(),
      growable: false,
    );

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: GeoBottomNav(
        currentIndex: _currentIndex,
        items: const [
          GeoNavItem(icon: Icons.home_rounded, label: 'Anasayfa'),
          GeoNavItem(icon: Icons.quiz, label: 'Oyun'),
          GeoNavItem(icon: Icons.public_rounded, label: 'Harita'),
          GeoNavItem(icon: Icons.leaderboard_rounded, label: 'Sıralama'),
          GeoNavItem(icon: Icons.person_rounded, label: 'Profil'),
        ],
        onChanged: (index) {
          Provider.of<SettingsProvider>(
            context,
            listen: false,
          ).triggerButtonVibration();
          _setTabIndex(index);
        },
      ),
    );
  }
}
