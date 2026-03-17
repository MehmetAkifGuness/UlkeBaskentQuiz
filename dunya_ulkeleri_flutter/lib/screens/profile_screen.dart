import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_profile_model.dart';
import '../services/user.service.dart'; // Kendi import yoluna dikkat et
import 'login_screen.dart'; // Çıkış yapınca yönlendirmek için EKLENDİ

class ProfileScreen extends StatelessWidget {
  final UserService _userService = UserService();

  // Hem profil bilgilerini hem de kategori skorlarını aynı anda çekmek için özel bir metod
  Future<Map<String, dynamic>> _fetchProfileData(String token) async {
    final profile = await _userService.getUserProfile(token);
    final scores = await _userService.getMyCategoryScores(token);
    return {'profile': profile, 'scores': scores};
  }

  // --- 🚨 ÇIKIŞ YAPMA İŞLEMİ ---
  void _handleLogout(BuildContext context) async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    // Tüm önceki ekranları kapatıp Giriş Ekranına (Login) yönlendirir
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  // --- 🚨 AYARLAR MENÜSÜ (Şimdilik Pop-up) ---
  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text("Ayarlar", style: TextStyle(color: Colors.amber)),
        content: Text(
          "Ses efektleri ve titreşim ayarları çok yakında eklenecek!",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Tamam", style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text("Profilim"), centerTitle: true),
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
                  ), // 🚨 Rütbeye göre renk değişir
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
                // 🚨 YENİ EKLENDİ: Toplam Puan
                _buildStatCard(
                  "Toplam Ustalık Puanı",
                  totalScore.toString(),
                  Icons.military_tech,
                ),

                SizedBox(height: 30),

                // --- KATEGORİ REKORLARI BÖLÜMÜ ---
                Text(
                  "Kategori Rekorlarım",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                Divider(color: Colors.amber),

                if (scores.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Henüz hiçbir kategoride rekorunuz yok. Hemen oynamaya başlayın!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics:
                        NeverScrollableScrollPhysics(), // Scroll çakışmasını önler
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Yan yana 2 kutu
                      childAspectRatio: 2.5, // Kutuların en/boy oranı
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: scores.length,
                    itemBuilder: (context, index) {
                      String category = scores.keys.elementAt(index);
                      int score = scores.values.elementAt(index);

                      return Card(
                        color: Colors.blueGrey[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              category,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "$score Puan",
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                SizedBox(height: 40),

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
                          elevation: 4, // Hafif gölge eklendi
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        icon: Icon(Icons.settings),
                        label: Text(
                          "Ayarlar",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _showSettings(context),
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
                          elevation: 4, // Hafif gölge eklendi
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
