// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 🚨 YENİ EKLENDİ
import '../providers/settings_provider.dart'; // 🚨 YENİ EKLENDİ
import 'home_screen.dart';
import 'profile_screen.dart';
import 'dictionary_screen.dart';
import 'leaderboard_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Alt menüdeki sekmeler (Sıralama ekranı 1. sıraya eklendi)
  final List<Widget> _screens = [
    HomeScreen(), // 0. index: Oyuna Başla sayfası
    LeaderboardScreen(), // 1. index: Sıralama (Liderlik) sayfası - YENİ
    DictionaryScreen(), // 2. index: Öğrenme(Sözlük) sayfası
    ProfileScreen(), // 3. index: Profil sayfası
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        // DİKKAT: 3'ten fazla ikon kullanıldığında 'fixed' yapmak zorunludur!
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors
            .amber, // Seçilen sekmenin rengi (Oyunun temasına uygun altın sarısı)
        unselectedItemColor: Colors.grey, // Seçili olmayanların rengi
        onTap: (index) {
          // 🚨 YENİ EKLENDİ: Alt sekmelere tıklandığında titreşim
          Provider.of<SettingsProvider>(
            context,
            listen: false,
          ).triggerButtonVibration();

          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.play_arrow), label: 'Oyun'),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard), // YENİ SIRALAMA İKONU
            label: 'Sıralama',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Öğren'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
