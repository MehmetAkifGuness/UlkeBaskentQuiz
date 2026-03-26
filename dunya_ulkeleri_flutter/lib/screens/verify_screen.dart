// lib/screens/verify_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/auth_service.dart';

class VerifyScreen extends StatefulWidget {
  final String email;

  const VerifyScreen({super.key, required this.email});

  @override
  _VerifyScreenState createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
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
      setState(() {
        _isLoading = false;
      });
      _showSnackBar("Girdiğiniz kod hatalı veya süresi dolmuş!", Colors.red);
    }
  }

  // --- KODU TEKRAR GÖNDERME METODU (YENİ) ---
  void _resendCode() async {
    Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).triggerButtonVibration();
    _showSnackBar("Kod e-posta adresinize tekrar gönderiliyor...", Colors.blue);

    // TODO: Backend'de kod tekrar gönderme endpoint'i (uç noktası)
    // varsa buraya entegre edebilirsiniz. Şuanlık sadece SnackBar gösteriyor.
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
                color: Colors.blue,
              ),
              SizedBox(height: 30),

              // Bilgilendirme Metinleri
              Text(
                "${widget.email}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900], // E-posta adresi koyu mavi yapıldı
                ),
              ),
              SizedBox(height: 12),

              // 🚨 FOTOĞRAFTA GÖRÜNMEYEN METİN ARTIK SİYAH VE OKUNABİLİR
              Text(
                "adresine gönderilen 6 haneli doğrulama kodunu aşağıya giriniz:",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black,
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
                  color:
                      Colors.black, // 🚨 DÜZELTİLDİ: Beyazdan siyaha çevrildi
                ),
                decoration: InputDecoration(
                  labelText: "Doğrulama Kodu",
                  hintText: "000000",
                  counterText:
                      "", // Alt köşede çıkan "0/6" sayaç yazısını gizler
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      20,
                    ), // Daha yuvarlak kenarlar
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.amber, width: 2),
                  ),
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
                  ? CircularProgressIndicator(color: Colors.amber)
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 55),
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            20,
                          ), // Daha modern yuvarlak kenarlar
                        ),
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
