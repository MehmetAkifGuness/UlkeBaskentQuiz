// lib/main.dart
import 'package:dunya_ulkeleri_flutter/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'app/navigation.dart';
import 'providers/auth_provider.dart';
import 'providers/conquest_provider.dart';
import 'providers/conquest_multiplayer_provider.dart';
import 'providers/duel_provider.dart';
import 'providers/game_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/world_map_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart'; // 🚨 DÜZELTME: HomeScreen yerine MainScreen'i import ettik!
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 🚨 YENİ: Asenkron işlemlerden önce Flutter motorunu hazırla
  try {
    await dotenv.load(fileName: ".env.local");
  } catch (_) {
    await dotenv.load(fileName: ".env");
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => WorldMapProvider()),
        ChangeNotifierProvider(create: (_) => ConquestProvider()),
        ChangeNotifierProvider(create: (_) => ConquestMultiplayerProvider()),
        ChangeNotifierProvider(create: (_) => DuelProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 🚨 YENİ EKLENDİ: Global anahtarı uygulamaya bağladık
      navigatorKey: navigatorKey,
      title: 'Dünya Ülkeleri Bilgi Yarışması',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      // 🚨 Akıllı Yönlendirme (Beni Hatırla)
      home: Consumer<AuthProvider>(
        builder: (ctx, auth, _) {
          // Eğer AuthProvider'da token varsa direkt içeri al
          if (auth.token != null) {
            return MainScreen(); // 🚨 DÜZELTME: Alt menülerin olduğu ana ekran
          }

          // Token yoksa cihazın arka planına (SharedPreferences) bak
          return FutureBuilder(
            future: auth.tryAutoLogin(),
            builder: (ctx, authResultSnapshot) {
              // Cihaz hafızası kontrol edilirken yükleniyor ekranı göster
              if (authResultSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(color: AppColors.primaryBlue),
                  ),
                );
              }

              // Hafızada token bulunduysa ana ekrana at
              if (authResultSnapshot.data == true) {
                return MainScreen(); // 🚨 DÜZELTME: Alt menülerin olduğu ana ekran
              }

              // Hiçbiri olmadıysa (İlk defa giren veya çıkış yapan), Login ekranına at
              return LoginScreen();
            },
          );
        },
      ),
    );
  }
}
