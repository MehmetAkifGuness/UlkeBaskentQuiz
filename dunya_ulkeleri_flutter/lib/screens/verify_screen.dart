import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class VerifyScreen extends StatelessWidget {
  final String email;
  final _codeController = TextEditingController();
  final _authService = AuthService();

  VerifyScreen({required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("E-posta Doğrula"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.mark_email_unread_outlined, size: 80, color: Colors.blue),
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
              textAlign: TextAlign.center, // Kodu kutunun ortasına yazar
              // ✅ DOĞRU YER: Yazı stili burada tanımlanır
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 10, // Harf boşluğu artık burada
              ),
              decoration: InputDecoration(
                labelText: "Doğrulama Kodu",
                hintText: "000000",
                border: OutlineInputBorder(),
                // ❌ letterSpacing buradan kaldırıldı
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
              onPressed: () async {
                final result = await _authService.verify(
                  email,
                  _codeController.text,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result.message ?? "İşlem yapılıyor...")),
                );

                // Backend mesajını kontrol et (küçük/büyük harf duyarsız)
                if (result.message != null &&
                    (result.message!.toLowerCase().contains("başarı") ||
                        result.message!.toLowerCase().contains("success"))) {

                  // Giriş ekranına (ilk sayfaya) geri dön
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