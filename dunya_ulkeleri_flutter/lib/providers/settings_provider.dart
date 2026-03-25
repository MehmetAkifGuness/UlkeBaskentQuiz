// lib/providers/settings_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart'; // 🚨 YENİ EKLENDİ: Global titreşim motoru

class SettingsProvider with ChangeNotifier {
  bool _isSoundEnabled = true; // Varsayılan olarak ses açık
  bool _isVibrationEnabled = true; // Varsayılan olarak titreşim açık

  bool get isSoundEnabled => _isSoundEnabled;
  bool get isVibrationEnabled => _isVibrationEnabled;

  SettingsProvider() {
    _loadSettings();
  }

  // Uygulama açıldığında cihaz hafızasındaki ayarları yükler
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isSoundEnabled = prefs.getBool('soundEnabled') ?? true;
    _isVibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
    notifyListeners();
  }

  // Sesi aç/kapat ve hafızaya kaydet
  Future<void> toggleSound(bool value) async {
    _isSoundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', value);
    notifyListeners();
  }

  // Titreşimi aç/kapat ve hafızaya kaydet
  Future<void> toggleVibration(bool value) async {
    _isVibrationEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibrationEnabled', value);
    notifyListeners();
  }

  // 🚨 YENİ EKLENDİ: Uygulama genelindeki herhangi bir butonda çağrılabilecek "tık" hissi
  Future<void> triggerButtonVibration() async {
    if (_isVibrationEnabled) {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        // 40 milisaniyelik zarif ve klavye tuşuna basmış gibi hissettiren kısa titreşim
        Vibration.vibrate(duration: 40);
      }
    }
  }
}
