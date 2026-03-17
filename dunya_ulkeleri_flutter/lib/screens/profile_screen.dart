import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_profile_model.dart';
import '../services/user.service.dart'; // Kendi import yoluna dikkat et
import 'login_screen.dart'; // Çıkış yapınca yönlendirmek için EKLENDİ
import 'forgot_password_dialog.dart'; // 🚨 Şifre yenileme popup'ı EKLENDİ
import 'dictionary_screen.dart'; // 🚨 Sözlüğe yönlendirme yapabilmek için eklendi

class ProfileScreen extends StatelessWidget {
  final UserService _userService = UserService();

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

  // --- 🚨 AYARLAR MENÜSÜ (Artık parametre olarak profili alıyor) ---
  void _showSettings(BuildContext context, UserProfileModel profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text("Ayarlar", style: TextStyle(color: Colors.amber)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
              ),
              icon: Icon(Icons.lock_reset),
              label: Text("Şifremi Değiştir"),
              onPressed: () {
                Navigator.pop(context); // Önce Ayarlar menüsünü kapat
                // 🚨 E-POSTAYI POPUP'A GÖNDERİYORUZ:
                showDialog(
                  context: context,
                  builder: (context) =>
                      ForgotPasswordDialog(email: profile.email),
                );
              },
            ),
            SizedBox(height: 15),
            Text(
              "Ses ve titreşim ayarları çok yakında eklenecek!",
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Kapat", style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  // 🚨 YENİ VE AKILLI ANALİZ ALGORİTMASI 🚨
  String _generateAnalysisText(Map<String, int> scores) {
    final allCategories = [
      "Avrupa",
      "Asya",
      "Afrika",
      "Kuzey Amerika",
      "Güney Amerika",
      "Okyanusya",
    ];

    List<String> unplayed = [];
    List<String> weak = [];

    for (var cat in allCategories) {
      int score = scores[cat] ?? 0;
      if (score == 0) {
        unplayed.add(cat);
      } else if (score < 10000) {
        // 20.000 puan hedefine göre 10.000 altını zayıf kabul ediyoruz
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
          "İstatistiklerine göre ${weak.join(", ")} bölgelerinde biraz zorlanıyorsun. Puanlarını artırmak için sözlükten bu kıtalara çalışabilirsin.\n\n";
    }

    // Hiç oynamadığı kıtalar varsa
    if (unplayed.isNotEmpty) {
      message +=
          "Ayrıca ${unplayed.join(", ")} kıtalarında henüz hiç oynamamışsın. Şansını oralarda da denemeni kesinlikle tavsiye ederiz!";
    }

    // Her yerde mükemmelse
    if (weak.isEmpty && unplayed.isEmpty) {
      message =
          "Harika bir iş çıkarıyorsun! Bütün kıtalarda gayet başarılısın, rekorlarını tazelemeye devam et!";
    }

    return message.trim();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text("Profilim & Analiz"), centerTitle: true),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchProfileData(authProvider.token!),
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
          final scores = snapshot.data!['scores'] as Map<String, int>;

          // Tarihi daha güzel göstermek için parçalayabiliriz
          final date = DateTime.parse(profile.creationDate);
          final formattedDate = "${date.day}/${date.month}/${date.year}";

          // --- 🏆 LİG / RÜTBE HESAPLAMA ---
          int totalScore = scores.values.fold(
            0,
            (sum, item) => sum + item,
          ); // Tüm rekorların toplamı

          String tierName;
          Color tierColor;
          IconData tierIcon;

          if (totalScore < 150000) {
            tierName = "Turist";
            tierColor = Colors.green;
            tierIcon = Icons.backpack;
          } else if (totalScore < 500000) {
            tierName = "Gezgin";
            tierColor = Colors.blue;
            tierIcon = Icons.explore;
          } else if (totalScore < 4000000) {
            tierName = "Kâşif";
            tierColor = Colors.purpleAccent;
            tierIcon = Icons.map;
          } else {
            tierName = "Coğrafya Profesörü";
            tierColor = Colors.amber;
            tierIcon = Icons.school;
          }

          // 🚨 Dinamik Analiz Metnini Oluşturuyoruz
          String analysisText = _generateAnalysisText(scores);

          // Ekrana sığması için SingleChildScrollView kullanıyoruz
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: tierColor.withOpacity(
                    0.2,
                  ), // Rütbeye göre renk değişir
                  child: Icon(Icons.person, size: 50, color: tierColor),
                ),
                SizedBox(height: 20),
                Text(
                  profile.username,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),

                // --- 🏆 RÜTBE ROZETİ ---
                Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
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
                ),
                SizedBox(height: 30),

                // 🚨 YENİ EKLENEN: ZAYIF YÖN ANALİZ KARTI
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
                          analysisText, // 🚨 ÜRETTİĞİMİZ DİNAMİK METİN BURAYA GELDİ
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            height:
                                1.4, // Satır arası boşluk, okumayı kolaylaştırır
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
                SizedBox(height: 30),

                // 🚨 YENİ EKLENEN: KITA USTALIK ÇUBUKLARI
                Text(
                  "Kıta Ustalık Seviyeleri",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                Divider(color: Colors.amber),
                ...[
                  "Avrupa",
                  "Asya",
                  "Afrika",
                  "Kuzey Amerika",
                  "Güney Amerika",
                  "Okyanusya",
                ].map((cat) {
                  int score = scores[cat] ?? 0;
                  // Hedef skoru 20.000 puan olarak varsayıyoruz
                  double percentage = (score / 20000).clamp(0.0, 1.0);

                  Color barColor = Colors.red;
                  if (percentage >= 0.8)
                    barColor = Colors.green;
                  else if (percentage >= 0.4)
                    barColor = Colors.orange;

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
                              "$score Puan",
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
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
                            color: barColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

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
