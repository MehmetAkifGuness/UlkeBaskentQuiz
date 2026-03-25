// lib/screens/verify_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 🚨 YENİ EKLENDİ
import '../providers/settings_provider.dart'; // 🚨 YENİ EKLENDİ
import '../services/auth_service.dart';

class VerifyScreen extends StatelessWidget {
  final String email;
  final _codeController = TextEditingController();
  final _authService = AuthService();

  VerifyScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("E-posta Doğrula"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.mark_email_unread_outlined,
              size: 80,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            Text(
              "$email adresine gelen 6 haneli kodu giriniz:",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 10,
              ),
              decoration: InputDecoration(
                labelText: "Doğrulama Kodu",
                hintText: "000000",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
              onPressed: () async {
                Provider.of<SettingsProvider>(
                  context,
                  listen: false,
                ).triggerButtonVibration(); // 🚨 YENİ
                final result = await _authService.verify(
                  email,
                  _codeController.text,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message ?? "İşlem yapılıyor..."),
                  ),
                );

                if (result.message != null &&
                    (result.message!.toLowerCase().contains("başarı") ||
                        result.message!.toLowerCase().contains("success"))) {
                  Navigator.popUntil(context, (route) => route.isFirst);
                }
              },
              child: Text("Onayla ve Giriş Ekranına Dön"),
            ),
          ],
        ),
      ),
    );
  }
}
