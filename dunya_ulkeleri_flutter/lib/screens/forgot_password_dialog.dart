// lib/screens/forgot_password_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart'; // 🚨 YENİ EKLENDİ
import '../theme/app_theme.dart';
import '../utils/error_message_utils.dart';

class ForgotPasswordDialog extends StatefulWidget {
  final String? email;

  const ForgotPasswordDialog({super.key, this.email});

  @override
  ForgotPasswordDialogState createState() => ForgotPasswordDialogState();
}

class ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  int _step = 1;
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.email != null && widget.email!.isNotEmpty) {
      _emailController.text = widget.email!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendEmail();
      });
    }
  }

  void _sendEmail() async {
    if (_emailController.text.isEmpty) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final result = await authProvider.sendPasswordResetEmail(
        _emailController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _step = 2;
      });

      final successMessage =
          result.message ?? "Eğer bu bilgilere ait bir hesap varsa, kod gönderildi.";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessageFrom(e)),
          backgroundColor: Colors.red,
        ),
      );
      if (widget.email != null) {
        Navigator.pop(context);
      }
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

    try {
      final result = await authProvider.resetPassword(
        _emailController.text.trim(),
        _codeController.text.trim(),
        _newPasswordController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? "Şifre başarıyla güncellendi."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessageFrom(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;

    return AlertDialog(
      backgroundColor: AppColors.surface2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        "Şifre Değiştir",
        style: const TextStyle(
          color: AppColors.primaryBlue,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_step == 1 && widget.email == null) ...[
              Text(
                "Hesabınıza kayıtlı e-posta adresinizi veya kullanıcı adınızı girin. Kayıtlı e-postanıza bir doğrulama kodu göndereceğiz.",
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 15),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: AppColors.textDark),
                decoration: InputDecoration(
                  labelText: "E-posta veya Kullanıcı Adı",
                ),
              ),
            ] else if (_step == 1 && widget.email != null) ...[
              Text(
                "Kayıtlı e-postanıza doğrulama kodu gönderiliyor...",
                style: TextStyle(color: Colors.white70),
              ),
            ] else if (_step == 2) ...[
              Text(
                "E-postanıza gelen 6 haneli kodu ve yeni şifrenizi girin.",
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 15),
              TextField(
                controller: _codeController,
                style: const TextStyle(color: AppColors.textDark),
                decoration: InputDecoration(
                  labelText: "Doğrulama Kodu",
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                style: const TextStyle(color: AppColors.textDark),
                decoration: InputDecoration(
                  labelText: "Yeni Şifre",
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Provider.of<SettingsProvider>(
              context,
              listen: false,
            ).triggerButtonVibration(); // 🚨 YENİ
            Navigator.pop(context);
          },
          child: Text("İptal", style: TextStyle(color: Colors.grey)),
        ),
        isLoading
            ? Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: CircularProgressIndicator(color: AppColors.primaryBlue),
              )
            : ElevatedButton(
                onPressed: () {
                  Provider.of<SettingsProvider>(
                    context,
                    listen: false,
                  ).triggerButtonVibration(); // 🚨 YENİ
                  _step == 1 ? _sendEmail() : _changePassword();
                },
                child: Text(
                  _step == 1 ? "Kod Gönder" : "Şifreyi Değiştir",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
      ],
    );
  }
}
