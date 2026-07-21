import 'dart:async';

import 'package:dunya_ulkeleri_flutter/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'app/navigation.dart';
import 'providers/auth_provider.dart';
import 'providers/conquest_multiplayer_provider.dart';
import 'providers/duel_provider.dart';
import 'providers/game_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/world_map_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/country_catalog_service.dart';
import 'services/iso_country_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env.local");
  } catch (_) {
    await dotenv.load(fileName: ".env");
  }

  unawaited(CountryCatalogService().preload());
  unawaited(IsoCountryService.ensureLoaded());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => WorldMapProvider()),
        ChangeNotifierProvider(create: (_) => ConquestMultiplayerProvider()),
        ChangeNotifierProvider(create: (_) => DuelProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Dünya Ülkeleri Bilgi Yarışması',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: Consumer<AuthProvider>(
        builder: (ctx, auth, _) {
          if (auth.token != null) {
            return MainScreen();
          }

          return FutureBuilder(
            future: auth.tryAutoLogin(),
            builder: (ctx, authResultSnapshot) {
              if (authResultSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                );
              }

              if (authResultSnapshot.data == true) {
                return MainScreen();
              }

              return LoginScreen();
            },
          );
        },
      ),
    );
  }
}
