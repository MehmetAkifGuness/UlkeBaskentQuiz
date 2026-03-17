import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordDialog extends StatefulWidget {
  final String? email; // 🚨 DIŞARIDAN GELEN OTOMATİK MAİL İÇİN EKLENDİ

  const ForgotPasswordDialog({Key? key, this.email}) : super(key: key);

  @override
  _ForgotPasswordDialogState createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  int _step =
      1; // 1: Email/Username girme aşaması, 2: Kod ve yeni şifre aşaması
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 🚨 SİHİRLİ KISIM: Eğer email hazır gelmişse (Yani Profil ekranındaysak)
    if (widget.email != null && widget.email!.isNotEmpty) {
      _emailController.text = widget.email!;
      // Ekran açılır açılmaz arka planda otomatik olarak kodu gönder:
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendEmail();
      });
    }
  }

  void _sendEmail() async {
    if (_emailController.text.isEmpty) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final result = await authProvider.sendPasswordResetEmail(
      _emailController.text.trim(),
    );

    // Mesajın içinde hata ("Exception") geçmiyorsa başarılıdır
    if (!result.message!.contains("Exception")) {
      setState(() {
        _step = 2;
      }); // Başarılıysa 2. aşamaya geç
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message!), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Kullanıcı adı veya e-posta bulunamadı!"),
          backgroundColor: Colors.red,
        ),
      );
      if (widget.email != null)
        Navigator.pop(context); // Otomatik gönderimde hata varsa popup'ı kapat
    }
  }

  void _changePassword() async {
    if (_codeController.text.isEmpty ||
        _newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Lütfen kodu girin ve şifrenin en az 6 hane olduğuna emin olun.",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.resetPassword(
      _emailController.text.trim(),
      _codeController.text.trim(),
      _newPasswordController.text.trim(),
    );

    if (!result.message!.contains("Exception")) {
      Navigator.pop(context); // İşlem bittiyse popup'ı kapat
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message!), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Kod yanlış veya süresi dolmuş!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;

    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        "Şifre Değiştir", // Başlığı da daha genel yaptık
        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Eğer dışarıdan email GELMEMİŞSE (Giriş ekranından açılmışsa)
            if (_step == 1 && widget.email == null) ...[
              Text(
                "Hesabınıza kayıtlı e-posta adresinizi veya kullanıcı adınızı girin. Kayıtlı e-postanıza bir doğrulama kodu göndereceğiz.",
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 15),
              TextField(
                controller: _emailController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "E-posta veya Kullanıcı Adı", // 🚨 ETİKET DEĞİŞTİ
                  labelStyle: TextStyle(color: Colors.amber),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
              ),
              // Eğer dışarıdan email GELMİŞSE (Profil ekranından otomatik kod gönderiliyorsa)
            ] else if (_step == 1 && widget.email != null) ...[
              Text(
                "Kayıtlı e-postanıza doğrulama kodu gönderiliyor...",
                style: TextStyle(color: Colors.white70),
              ),
              // 2. Aşama: Şifre ve Kod girme ekranı
            ] else if (_step == 2) ...[
              Text(
                "E-postanıza gelen 6 haneli kodu ve yeni şifrenizi girin.",
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 15),
              TextField(
                controller: _codeController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Doğrulama Kodu",
                  labelStyle: TextStyle(color: Colors.amber),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Yeni Şifre",
                  labelStyle: TextStyle(color: Colors.amber),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("İptal", style: TextStyle(color: Colors.grey)),
        ),
        isLoading
            ? Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: CircularProgressIndicator(color: Colors.amber),
              )
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                onPressed: _step == 1 ? _sendEmail : _changePassword,
                child: Text(
                  _step == 1 ? "Kod Gönder" : "Şifreyi Değiştir",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
      ],
    );
  }
}
