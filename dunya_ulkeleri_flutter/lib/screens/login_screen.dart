// lib/screens/login_screen.dart
import 'package:dunya_ulkeleri_flutter/utils/page_trasitions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart'; // 🚨 YENİ EKLENDİ
import 'register_screen.dart';
import 'forgot_password_dialog.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text("Dünya Ülkeleri - Giriş"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: "Kullanıcı Adı",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Şifre",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),

            // --- 🚨 ŞİFREMİ UNUTTUM BUTONU ---
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Provider.of<SettingsProvider>(
                    context,
                    listen: false,
                  ).triggerButtonVibration(); // 🚨 YENİ
                  showDialog(
                    context: context,
                    builder: (context) => ForgotPasswordDialog(),
                  );
                },
                child: Text(
                  "Şifremi Unuttum",
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),

            authProvider.isLoading
                ? CircularProgressIndicator()
                : Column(
                    children: [
                      // NORMAL GİRİŞ YAP BUTONU
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                        ),
                        onPressed: () async {
                          Provider.of<SettingsProvider>(
                            context,
                            listen: false,
                          ).triggerButtonVibration(); // 🚨 YENİ
                          final result = await authProvider.login(
                            _usernameController.text,
                            _passwordController.text,
                          );

                          if (authProvider.token != null) {
                            Navigator.pushReplacement(
                              context,
                              FadePageRoute(page: MainScreen()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result.message ?? "Giriş başarısız!",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: Text(
                          "Giriş Yap",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      SizedBox(height: 15),
                      // --- MİSAFİR GİRİŞİ BUTONU ---
                      OutlinedButton(
                        onPressed: () async {
                          Provider.of<SettingsProvider>(
                            context,
                            listen: false,
                          ).triggerButtonVibration(); // 🚨 YENİ
                          bool success = await authProvider.loginAsGuest();
                          if (success) {
                            Navigator.pushReplacement(
                              context,
                              FadePageRoute(page: MainScreen()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Misafir girişi başarısız oldu."),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                          side: BorderSide(color: Colors.blueAccent),
                        ),
                        child: Text(
                          "Misafir Olarak Devam Et",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      // ------------------------------------------
                    ],
                  ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Provider.of<SettingsProvider>(
                  context,
                  listen: false,
                ).triggerButtonVibration(); // 🚨 YENİ
                Navigator.push(context, FadePageRoute(page: RegisterScreen()));
              },
              child: Text("Hesabın yok mu? Kayıt Ol"),
            ),
          ],
        ),
      ),
    );
  }
}
