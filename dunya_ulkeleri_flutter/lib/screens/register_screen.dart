// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
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

  // 🚨 YARDIMCI METOD: Hata Mesajı Gösterici
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Yeni Kayıt")),
      body: Center(
        child: SingleChildScrollView(
          // Klavye açılınca taşmaması için
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Üstte ufak bir ikon ekleyelim (Opsiyonel şıklık)
              Icon(
                Icons.person_add_alt_1_rounded,
                size: 80,
                color: Colors.amber,
              ),
              SizedBox(height: 20),

              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: "Kullanıcı Adı",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              SizedBox(height: 15),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "E-posta",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              SizedBox(height: 15),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Şifre (En az 6 hane)",
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              SizedBox(height: 30),

              _isLoading
                  ? CircularProgressIndicator(color: Colors.amber)
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 55),
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () async {
                        Provider.of<SettingsProvider>(
                          context,
                          listen: false,
                        ).triggerButtonVibration();

                        String username = _usernameController.text.trim();
                        String email = _emailController.text.trim();
                        String password = _passwordController.text.trim();

                        // 🛑 KONTROL 1: Boş alan var mı?
                        if (username.isEmpty ||
                            email.isEmpty ||
                            password.isEmpty) {
                          _showError("Lütfen tüm alanları doldurun.");
                          return;
                        }

                        // 🛑 KONTROL 2: Şifre uzunluğu en az 6 mı?
                        if (password.length < 6) {
                          _showError("Şifreniz en az 6 karakter olmalıdır.");
                          return;
                        }

                        // 🛑 KONTROL 3: Email formatı doğru mu? (Basit kontrol)
                        if (!email.contains("@") || !email.contains(".")) {
                          _showError(
                            "Lütfen geçerli bir e-posta adresi girin.",
                          );
                          return;
                        }

                        setState(() => _isLoading = true);

                        // 🚨 YENİLİK: TRY-CATCH BLOĞU EKLENDİ (Hata yakalama kalkanı)
                        try {
                          final result = await _authService.register(
                            username,
                            email,
                            password,
                          );

                          setState(() => _isLoading = false);

                          // Cevap içinde "başarı" veya "doğrulayın" kelimesi geçiyorsa kayıt başarılıdır
                          bool isSuccess =
                              (result.message?.toLowerCase().contains(
                                    "başarı",
                                  ) ??
                                  false) ||
                              (result.message?.toLowerCase().contains(
                                    "doğrulayın",
                                  ) ??
                                  false);

                          if (isSuccess) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result.message!),
                                backgroundColor: Colors.green,
                              ),
                            );
                            // Başarılıysa doğrulama ekranına at
                            Navigator.pushReplacement(
                              // Geri tuşuyla tekrar kayıta dönmemesi için pushReplacement
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    VerifyScreen(email: email),
                              ),
                            );
                          } else {
                            // Arka yüzden hata mesajı sorunsuz döndüyse (Örn: Bu mail kullanılıyor)
                            _showError(
                              result.message ??
                                  "Kayıt başarısız. Lütfen bilgilerinizi kontrol edin.",
                            );
                          }
                        } catch (e) {
                          // 🚨 EĞER BACKEND ÇÖKERSE VEYA 400/500 HATASI FIRLATIRSA UYGULAMA DONMASIN DİYE BURAYA DÜŞER
                          setState(() => _isLoading = false);

                          // Kullanıcıya şık bir şekilde arka plan hatasını bildiriyoruz
                          _showError(
                            "Kayıt işlemi başarısız! Girdiğiniz e-posta veya kullanıcı adı zaten sistemde kayıtlı olabilir.",
                          );
                        }
                      },
                      child: Text(
                        "Kayıt Ol",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
