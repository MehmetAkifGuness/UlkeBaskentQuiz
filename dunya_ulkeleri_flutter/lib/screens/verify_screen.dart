// lib/screens/verify_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/error_message_utils.dart';

class VerifyScreen extends StatefulWidget {
  final String email;

  const VerifyScreen({super.key, required this.email});

  @override
  VerifyScreenState createState() => VerifyScreenState();
}

class VerifyScreenState extends State<VerifyScreen> {
  // --- DEĞİŞKENLER VE KONTROLCÜLER ---
  final _codeController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  // --- ONAYLAMA METODU ---
  void _verifyCode() async {
    // Butona tıklandığında titreşim hissi
    Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).triggerButtonVibration();

    String enteredCode = _codeController.text.trim();

    // Kontroller
    if (enteredCode.isEmpty) {
      _showSnackBar("Lütfen doğrulama kodunu giriniz.", Colors.orange);
      return;
    }
    if (enteredCode.length != 6) {
      _showSnackBar("Doğrulama kodu tam 6 haneli olmalıdır.", Colors.orange);
      return;
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(enteredCode)) {
      _showSnackBar(
        "Doğrulama kodu sadece rakamlardan oluşmalıdır.",
        Colors.orange,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 🚨 YENİ EKLENDİ: Yanlış kod girildiğinde uygulamanın donmaması için try-catch bloğu eklendi
    try {
      final result = await _authService.verify(widget.email, enteredCode);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      bool isSuccess =
          result.message != null &&
          (result.message!.toLowerCase().contains("başarı") ||
              result.message!.toLowerCase().contains("success"));

      _showSnackBar(
        result.message ?? "İşlem tamamlandı.",
        isSuccess ? Colors.green : Colors.red,
      );

      // Başarılıysa Giriş Ekranına (Login) yönlendir
      if (isSuccess) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      // 🚨 EĞER KOD YANLIŞSA VEYA BACKEND HATA FIRLATIRSA DONMAYIP BURAYA DÜŞECEK
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showSnackBar(errorMessageFrom(e), Colors.red);
    }
  }

  // --- KODU TEKRAR GÖNDERME METODU (YENİ) ---
  // --- KODU TEKRAR GÖNDERME METODU ---
  void _resendCode() async {
    Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).triggerButtonVibration();

    setState(() {
      _isLoading = true;
    });

    try {
      // Backend'deki yeni API'mizi tetikliyoruz
      final result = await _authService.resendVerification(widget.email);
      if (!mounted) return;
      _showSnackBar(result.message ?? "Yeni kod gönderildi.", Colors.green);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(errorMessageFrom(e), Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      } else {
        _isLoading = false;
      }
    }
  }

  // --- UYARI MESAJI GÖSTERME (SNACKBAR) ---
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar ile sol üst köşeye geri tuşu ve başlık eklendi
      appBar: AppBar(
        title: Text("Hesabını Onayla"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // Kayıt ekranına döner
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Üst Kısım İkon (Daha ciddiyet veren MAVİ renk yapıldı)
              Icon(
                Icons.mark_email_unread_outlined,
                size: 90,
                color: AppColors.primaryBlue,
              ),
              SizedBox(height: 30),

              // Bilgilendirme Metinleri
              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              SizedBox(height: 12),

              // 🚨 FOTOĞRAFTA GÖRÜNMEYEN METİN ARTIK SİYAH VE OKUNABİLİR
              Text(
                "adresine gönderilen 6 haneli doğrulama kodunu aşağıya giriniz:",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 40),

              // --- 🚨 STİLLENDİRİLMİŞ KOD GİRİŞ ALANI ---
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 15, // Rakamların arasını açar
                  color: AppColors.textDark,
                ),
                decoration: InputDecoration(
                  labelText: "Doğrulama Kodu",
                  hintText: "000000",
                  counterText:
                      "", // Alt köşede çıkan "0/6" sayaç yazısını gizler
                  contentPadding: EdgeInsets.symmetric(vertical: 18),
                ),
              ),
              SizedBox(height: 10),

              // --- 🚨 KODU TEKRAR GÖNDER BUTONU (YENİ) ---
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _resendCode,
                  child: Text(
                    "Kodu Tekrar Gönder",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),

              // --- 🚨 ONAYLA BUTONU (YÜKLENİYOR İKONU DAHİL) ---
              _isLoading
                  ? const CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 55),
                      ),
                      onPressed: _verifyCode,
                      child: Text(
                        "Kodu Onayla",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              SizedBox(height: 20), // Alt kısımdan biraz boşluk
            ],
          ),
        ),
      ),
    );
  }
}
