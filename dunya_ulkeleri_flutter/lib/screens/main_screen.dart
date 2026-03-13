import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'dictionary_screen.dart'; // YENİ EKRANI IMPORT ET

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Alt menüdeki sekmeler (Sözlük eklendi)
  final List<Widget> _screens = [
    HomeScreen(), // 0. index: Oyuna Başla sayfası
    DictionaryScreen(), // 1. index: Öğrenme(Sözlük) sayfası
    ProfileScreen(), // 2. index: Profil sayfası
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.play_arrow), label: 'Oyun'),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book), // SÖZLÜK İKONU
            label: 'Öğren',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
