// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 🚨 YENİ EKLENDİ
import '../providers/settings_provider.dart'; // 🚨 YENİ EKLENDİ
import '../services/auth_service.dart';
import 'verify_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Yeni Kayıt")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: "Kullanıcı Adı"),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "E-posta"),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: "Şifre"),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      Provider.of<SettingsProvider>(
                        context,
                        listen: false,
                      ).triggerButtonVibration(); // 🚨 YENİ
                      setState(() => _isLoading = true);
                      final result = await _authService.register(
                        _usernameController.text,
                        _emailController.text,
                        _passwordController.text,
                      );
                      setState(() => _isLoading = false);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result.message ?? "")),
                      );

                      if ((result.message?.contains("başarılı") ?? false) ||
                          (result.message?.contains("doğrulayın") ?? false)) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                VerifyScreen(email: _emailController.text),
                          ),
                        );
                      }
                    },
                    child: Text("Kayıt Ol"),
                  ),
          ],
        ),
      ),
    );
  }
}
