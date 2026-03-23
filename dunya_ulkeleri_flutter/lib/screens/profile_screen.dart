// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../models/user_profile_model.dart';
import '../services/user.service.dart'; // Kendi import yoluna dikkat et
import 'login_screen.dart'; // Çıkış yapınca yönlendirmek için EKLENDİ
import 'forgot_password_dialog.dart'; // 🚨 Şifre yenileme popup'ı EKLENDİ
import 'dictionary_screen.dart'; // 🚨 Sözlüğe yönlendirme yapabilmek için eklendi
import 'mistake_screen.dart'; // 🚨 YENİ: Hata defterine yönlendirme yapabilmek için EKLENDİ

// 🚨 YENİLİK: Ekranın anlık güncellenebilmesi için StatefulWidget yapıldı
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    _profileFuture = _fetchProfileData(token!);
  }

  // Hem profil bilgilerini hem de kategori skorlarını aynı anda çekmek için özel bir metod
  Future<Map<String, dynamic>> _fetchProfileData(String token) async {
    final profile = await _userService.getUserProfile(token);
    final scores = await _userService.getMyCategoryScores(token);
    return {'profile': profile, 'scores': scores};
  }

  // --- ÇIKIŞ YAPMA İŞLEMİ ---
  void _handleLogout(BuildContext context) async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    // Tüm önceki ekranları kapatıp Giriş Ekranına (Login) yönlendirir
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  // --- 🚨 GÜNCELLENDİ: AYARLAR MENÜSÜ CANLANDIRILDI ---
  void _showSettings(BuildContext context, UserProfileModel profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          "Ayarlar",
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
        ),
        // 🚨 YENİLİK: Ayarları anlık dinleyebilmek için Consumer kullandık
        content: Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🔊 Ses Ayarı
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    "Ses Efektleri",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  secondary: Icon(
                    settings.isSoundEnabled
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    color: settings.isSoundEnabled ? Colors.amber : Colors.grey,
                  ),
                  activeColor: Colors.amber,
                  activeTrackColor: Colors.amber.withOpacity(0.4),
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey.shade800,
                  value: settings.isSoundEnabled,
                  onChanged: (value) => settings.toggleSound(value),
                ),

                // 📳 Titreşim Ayarı
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    "Titreşim",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  secondary: Icon(
                    settings.isVibrationEnabled
                        ? Icons.vibration_rounded
                        : Icons.smartphone_rounded,
                    color: settings.isVibrationEnabled
                        ? Colors.amber
                        : Colors.grey,
                  ),
                  activeColor: Colors.amber,
                  activeTrackColor: Colors.amber.withOpacity(0.4),
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey.shade800,
                  value: settings.isVibrationEnabled,
                  onChanged: (value) => settings.toggleVibration(value),
                ),

                SizedBox(height: 20),

                // 🔑 Şifre Değiştirme Butonu
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade800,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(Icons.lock_reset),
                  label: Text(
                    "Şifremi Değiştir",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Önce Ayarlar menüsünü kapat
                    showDialog(
                      context: context,
                      builder: (context) =>
                          ForgotPasswordDialog(email: profile.email),
                    );
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Kapat",
              style: TextStyle(color: Colors.amber, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // --- 🚨 YENİ EKLENDİ: RÜTBE BİLGİ LİSTESİ POPUP'I ---
  void _showTierInfoDialog(BuildContext context) {
    // Rütbelerin özellikleri (Senin belirlediğin isimler ve puanlarla)
    final List<Map<String, dynamic>> tiers = [
      {
        "name": "Turist",
        "score": "0 - 99.999",
        "color": Colors.green,
        "icon": Icons.backpack,
      },
      {
        "name": "Gezgin",
        "score": "100.000 - 249.999",
        "color": Colors.blue,
        "icon": Icons.explore,
      },
      {
        "name": "Yol Kaşifi",
        "score": "250.000 - 499.999",
        "color": Colors.yellow,
        "icon": Icons.explore,
      },
      {
        "name": "Dünya Yolcusu",
        "score": "500.000 - 999.999",
        "color": Colors.brown,
        "icon": Icons.explore,
      },
      {
        "name": "Kıta Fatihi",
        "score": "1.000.000 - 4.999.999",
        "color": Colors.cyanAccent,
        "icon": Icons.explore,
      },
      {
        "name": "Harita Ustası",
        "score": "5.000.000 - 9.999.999",
        "color": Colors.teal,
        "icon": Icons.explore,
      },
      {
        "name": "Küresel Zihin",
        "score": "10.000.000 - 19.999.999",
        "color": const Color.fromARGB(255, 1, 90, 90),
        "icon": Icons.map,
      },
      {
        "name": "Evrensel Bilge",
        "score": "20.000.000+",
        "color": Colors.amber,
        "icon": Icons.school,
      },
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.military_tech, color: Colors.amber, size: 28),
            SizedBox(width: 10),
            Text(
              "Rütbe Sistemi",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400, // Popup yüksekliği
          child: ListView.builder(
            itemCount: tiers.length,
            itemBuilder: (context, index) {
              final tier = tiers[index];
              return Card(
                color: Colors.grey[800],
                margin: EdgeInsets.symmetric(vertical: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: tier['color'].withOpacity(0.2),
                    child: Icon(tier['icon'], color: tier['color']),
                  ),
                  title: Text(
                    tier['name'],
                    style: TextStyle(
                      color: tier['color'],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "${tier['score']} Puan",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Anladım",
              style: TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 🚨 YENİLİK: AVATAR SEÇİM MENÜSÜ 🚨 ---
  void _showAvatarSelection(BuildContext context, String token) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              Text(
                "Profil Fotoğrafı Seç",
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 15),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, // Yanyana 4 resim
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: 15, // 15 adet avatar resmi olduğunu varsayıyoruz
                  itemBuilder: (context, index) {
                    int currentId = index + 1;
                    return GestureDetector(
                      onTap: () async {
                        Navigator.pop(context); // Menüyü kapat
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Avatar güncelleniyor..."),
                            duration: Duration(seconds: 1),
                          ),
                        );

                        bool success = await _userService.updateAvatar(
                          token,
                          currentId,
                        );

                        if (success) {
                          setState(() {
                            // Ekranı yeni verilerle güncelle
                            _profileFuture = _fetchProfileData(token);
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Hata oluştu! Lütfen tekrar deneyin.",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          );
                        }
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.grey[800],
                        backgroundImage: AssetImage(
                          'assets/avatars/avatar_$currentId.png',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🚨 YENİ: Ustalık Yüzdesine Göre Derece ve Renk Döndüren Fonksiyon
  Map<String, dynamic> _getMasteryLevel(double percentage) {
    if (percentage == 0) return {"text": "Oynanmadı", "color": Colors.grey};
    if (percentage >= 0.8) return {"text": "Çok İyi", "color": Colors.green};
    if (percentage >= 0.6) return {"text": "İyi", "color": Colors.lightGreen};
    if (percentage >= 0.4) return {"text": "Ortalama", "color": Colors.amber};
    if (percentage >= 0.2)
      return {"text": "Çalışılmalı", "color": Colors.orange};
    return {"text": "Kötü", "color": Colors.red};
  }

  // 🚨 YENİ VE AKILLI ANALİZ ALGORİTMASI 🚨
  String _generateAnalysisText(Map<String, dynamic> scores) {
    // Soru sayılarını gerçek rakamlarla veriyoruz
    final categories = [
      {"name": "Avrupa", "q": 44},
      {"name": "Asya", "q": 48},
      {"name": "Afrika", "q": 54},
      {"name": "Kuzey Amerika", "q": 23},
      {"name": "Güney Amerika", "q": 12},
      {"name": "Okyanusya", "q": 14},
    ];

    List<String> unplayed = [];
    List<String> weak = [];

    for (var catData in categories) {
      String cat = catData["name"] as String;
      int questions = catData["q"] as int;

      int c2c = scores["${cat}_COUNTRY_TO_CAPITAL"] ?? 0;
      int c2cRev = scores["${cat}_CAPITAL_TO_COUNTRY"] ?? 0;
      int mixed = scores["${cat}_MIXED"] ?? 0;

      // 🚨 DÜZELTME: Toplam yerine, kullanıcının o kıtadaki EN YÜKSEK skorunu alıyoruz (Max)
      int maxScoreMode = [c2c, c2cRev, mixed].reduce((a, b) => a > b ? a : b);

      // Kıtadaki soru sayısına göre alınabilecek tahmini max puan (Soru başı ~2000 puan)
      int maxPossible = questions * 2000;
      double percentage = maxPossible > 0 ? (maxScoreMode / maxPossible) : 0;

      if (maxScoreMode == 0) {
        unplayed.add(cat);
      } else if (percentage < 0.4) {
        // %40 altı ise (Kötü veya Çalışılmalı derecesindeyse) buraya girer
        weak.add(cat);
      }
    }

    String message = "";

    // Hiç oyun oynamamışsa
    if (unplayed.length == 6) {
      return "Henüz hiçbir kıtada oynamamışsın! Hemen bir oyuna girerek dünyayı keşfetmeye başla.";
    }

    // Zayıf olduğu kıtalar varsa
    if (weak.isNotEmpty) {
      message +=
          "İstatistiklerine göre ${weak.join(", ")} bölgelerinde biraz zorlanıyorsun. Farklı oyun modlarında (Örn: Başkentten Ülkeye) pratik yaparak ustalık puanını artırabilirsin.\n\n";
    }

    // Hiç oynamadığı kıtalar varsa
    if (unplayed.isNotEmpty) {
      message +=
          "Ayrıca ${unplayed.join(", ")} kıtalarında henüz hiç oynamamışsın. Şansını oralarda da denemeni kesinlikle tavsiye ederiz!";
    }

    // Her yerde mükemmelse
    if (weak.isEmpty && unplayed.isEmpty) {
      message =
          "Harika bir iş çıkarıyorsun! Bütün kıtalarda ve tüm modlarda gayet başarılısın, rekorlarını tazelemeye devam et!";
    }

    return message.trim();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text("Profilim & Analiz"), centerTitle: true),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture, // 🚨 YENİLİK: State'deki Future'ı dinliyoruz
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          } else if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!['profile'] == null) {
            return Center(child: Text("Profil bilgileri alınamadı."));
          }

          final profile = snapshot.data!['profile'] as UserProfileModel;
          final scores =
              snapshot.data!['scores']
                  as Map<String, dynamic>; // 🚨 int yerine dynamic

          // Tarihi daha güzel göstermek için parçalayabiliriz
          final date = DateTime.parse(profile.creationDate);
          final formattedDate = "${date.day}/${date.month}/${date.year}";

          // --- 🏆 LİG / RÜTBE HESAPLAMA (Genel Puan) ---
          int totalScore = scores.values.fold(
            0,
            (sum, item) => sum + (item as int),
          );

          String tierName;
          Color tierColor;
          IconData tierIcon;

          if (totalScore < 100000) {
            tierName = "Turist";
            tierColor = Colors.green;
            tierIcon = Icons.backpack;
          } else if (totalScore < 250000) {
            tierName = "Gezgin";
            tierColor = Colors.blue;
            tierIcon = Icons.explore;
          } else if (totalScore < 500000) {
            tierName = "Yol Kaşifi";
            tierColor = Colors.yellow;
            tierIcon = Icons.explore;
          } else if (totalScore < 1000000) {
            tierName = "Dünya Yolcusu";
            tierColor = Colors.brown;
            tierIcon = Icons.explore;
          } else if (totalScore < 5000000) {
            tierName = "Kıta Fatihi";
            tierColor = Colors.cyanAccent;
            tierIcon = Icons.explore;
          } else if (totalScore < 10000000) {
            tierName = "Harita Ustası";
            tierColor = Colors.teal;
            tierIcon = Icons.explore;
          } else if (totalScore < 20000000) {
            tierName = "Küresel Zihin";
            tierColor = const Color.fromARGB(255, 1, 90, 90);
            tierIcon = Icons.map;
          } else {
            tierName = "Evrensel Bilge";
            tierColor = Colors.amber;
            tierIcon = Icons.school;
          }

          // 🚨 Dinamik Analiz Metnini Oluşturuyoruz
          String analysisText = _generateAnalysisText(scores);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () =>
                        _showAvatarSelection(context, authProvider.token!),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: tierColor.withOpacity(0.3),
                          backgroundImage: AssetImage(
                            'assets/avatars/avatar_${profile.avatarId}.png',
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 20,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  profile.username,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),

                // --- 🏆 🚨 YENİ EKLENDİ: RÜTBE ROZETİ VE BİLGİ BUTONU ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: tierColor.withOpacity(0.2),
                        border: Border.all(color: tierColor, width: 2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tierIcon, color: tierColor, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "$tierName Seviyesi",
                            style: TextStyle(
                              color: tierColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.help_outline, color: Colors.amber),
                        tooltip: "Rütbeler ve Puanlar",
                        onPressed: () => _showTierInfoDialog(context),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),

                Card(
                  elevation: 5,
                  color: Colors.red[900]!.withOpacity(0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.query_stats,
                              color: Colors.white,
                              size: 30,
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Analiz & Tavsiye",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          analysisText,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 15),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          icon: Icon(Icons.menu_book),
                          label: Text(
                            "Sözlüğe Git",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DictionaryScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 15),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[800],
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                  icon: Icon(Icons.auto_stories, color: Colors.white),
                  label: Text(
                    "Hata Defterimi İncele",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MistakeScreen()),
                    );
                  },
                ),

                SizedBox(height: 30),

                // 🚨 YENİ GÜNCELLEME: Kıta Ustalık -> Ustalık Seviyeleri
                Text(
                  "Ustalık Seviyeleri",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                Divider(color: Colors.amber),

                // 1. Önce "Günün Görevi" ve "Sonsuz Mod" için özel barları ekliyoruz
                // 1. Önce "Günün Görevi" ve "Sonsuz Mod" için özel barları ekliyoruz
                ...[
                  {
                    "title": "Günün Görevi",
                    "icon": "🔥",
                    "scoreKey": "DailyChallenge_MIXED",
                    "max": 20000, // 10 Soru * 2000 Puan
                  },
                  {
                    "title": "Sonsuz Mod",
                    "icon": "♾️",
                    "scoreKey": "Dünya_ENDLESS",
                    // 🚨 Sonsuz modda 20-25 arası ülkeyi arka arkaya bilmek "Ustalık" sayılır.
                    "max": 40000,
                  },
                ].map((specialCat) {
                  int score = scores[specialCat["scoreKey"]] ?? 0;

                  // 🚨 DÜZELTME: Soru sayısıyla çarpmayı bırakıp doğrudan kendi gerçekçi max hedefini alıyoruz
                  int maxScore = specialCat["max"] as int;
                  double percentage = maxScore > 0
                      ? (score / maxScore).clamp(0.0, 1.0)
                      : 0;

                  // Derece ve renk ataması
                  Map<String, dynamic> mastery = _getMasteryLevel(percentage);
                  if (score == 0)
                    mastery = {"text": "Oynanmadı", "color": Colors.grey};

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${specialCat["icon"]} ${specialCat["title"]}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "$score Puan (${mastery["text"]})",
                              style: TextStyle(
                                color: mastery["color"],
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: percentage,
                            minHeight: 12,
                            backgroundColor: Colors.grey[800],
                            color: mastery["color"],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                SizedBox(height: 10),

                // 2. Sonra normal Kıta istatistiklerini çiziyoruz
                ...[
                  {"name": "Avrupa", "q": 44},
                  {"name": "Asya", "q": 48},
                  {"name": "Afrika", "q": 54},
                  {"name": "Kuzey Amerika", "q": 23},
                  {"name": "Güney Amerika", "q": 12},
                  {"name": "Okyanusya", "q": 14},
                ].map((catData) {
                  String cat = catData["name"] as String;
                  int questions = catData["q"] as int;

                  int c2c = scores["${cat}_COUNTRY_TO_CAPITAL"] ?? 0;
                  int c2cRev = scores["${cat}_CAPITAL_TO_COUNTRY"] ?? 0;
                  int mixed = scores["${cat}_MIXED"] ?? 0;

                  // 🚨 DÜZELTME: Toplam yerine EN YÜKSEK (max) skoru alıyoruz
                  int score = [
                    c2c,
                    c2cRev,
                    mixed,
                  ].reduce((a, b) => a > b ? a : b);

                  // Kıtaya özel dinamik max skor hesaplaması
                  int maxScore = questions * 2000;
                  double percentage = maxScore > 0
                      ? (score / maxScore).clamp(0.0, 1.0)
                      : 0;

                  Map<String, dynamic> mastery = _getMasteryLevel(percentage);
                  if (score == 0)
                    mastery = {"text": "Oynanmadı", "color": Colors.grey};

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cat,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "$score Puan (${mastery["text"]})",
                              style: TextStyle(
                                color: mastery["color"],
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: percentage,
                            minHeight: 12,
                            backgroundColor: Colors.grey[800],
                            color: mastery["color"],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                SizedBox(height: 30),

                // --- GENEL İSTATİSTİKLER BÖLÜMÜ ---
                Text(
                  "Genel İstatistikler",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                Divider(color: Colors.amber),
                _buildStatCard(
                  "Kayıt Tarihi",
                  formattedDate,
                  Icons.calendar_today,
                ),
                _buildStatCard(
                  "En Yüksek Skor (Tek Maç)",
                  profile.maxWinStreak.toString(),
                  Icons.emoji_events,
                ),
                _buildStatCard(
                  "Oynanan Oyun",
                  profile.totalGamesPlayed.toString(),
                  Icons.videogame_asset,
                ),
                _buildStatCard(
                  "Toplam Ustalık Puanı",
                  totalScore.toString(),
                  Icons.military_tech,
                ),

                SizedBox(height: 30),

                // --- ⚙️ AYARLAR VE ÇIKIŞ YAP BUTONLARI ---
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          backgroundColor:
                              Colors.deepPurple[800], // Koyu Mor/Lacivert Renk
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        icon: Icon(Icons.settings),
                        label: Text(
                          "Ayarlar",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        // 🚨 PROFİLİ PARAMETRE OLARAK VERİYORUZ
                        onPressed: () => _showSettings(context, profile),
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          backgroundColor:
                              Colors.red[800], // Kırmızı Çıkış Butonu
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        icon: Icon(Icons.logout),
                        label: Text(
                          "Çıkış Yap",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _handleLogout(context),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20), // Alt kısımdan biraz boşluk
              ],
            ),
          );
        },
      ),
    );
  }

  // İstatistik Kartlarını oluşturan yardımcı widget
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, size: 30, color: Colors.amber),
        title: Text(
          title,
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
