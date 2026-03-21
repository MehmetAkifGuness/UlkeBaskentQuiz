// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/game_provider.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart'; // 👈 YENİ: Temamızı import ettik

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dünya Ülkeleri Quiz',
      debugShowCheckedModeBanner: false, // Sağ üstteki debug yazısını kaldırır
      theme: AppTheme.lightTheme, // 👈 YENİ: Artık senin renk sistemin devrede!
      home: LoginScreen(),
    );
  }
}
