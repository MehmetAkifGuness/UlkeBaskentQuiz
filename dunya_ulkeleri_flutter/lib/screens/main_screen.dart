// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 🚨 YENİ EKLENDİ
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
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _setTabIndex(int index) {
    if (!mounted) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        onNavigateTab: _setTabIndex,
        isActive: _currentIndex == 0,
      ),
      const HomeScreen(), // Oyun
      const WorldMapScreen(), // Dünya Haritası
      const LeaderboardScreen(), // Sıralama
      ProfileScreen(onNavigateTab: _setTabIndex),
    ];

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
