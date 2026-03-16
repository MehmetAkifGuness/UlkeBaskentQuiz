import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_profile_model.dart';
import '../services/user.service.dart'; // Kendi import yoluna dikkat et

class ProfileScreen extends StatelessWidget {
  final UserService _userService = UserService();

  // Hem profil bilgilerini hem de kategori skorlarını aynı anda çekmek için özel bir metod
  Future<Map<String, dynamic>> _fetchProfileData(String token) async {
    final profile = await _userService.getUserProfile(token);
    final scores = await _userService.getMyCategoryScores(token);
    return {'profile': profile, 'scores': scores};
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

          // Ekrana sığması için SingleChildScrollView kullanıyoruz
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.amber,
                  child: Icon(Icons.person, size: 50, color: Colors.black),
                ),
                SizedBox(height: 20),
                Text(
                  profile.username,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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

                SizedBox(height: 30),

                // --- KATEGORİ REKORLARI BÖLÜMÜ (YENİ EKLENDİ) ---
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

                SizedBox(height: 40), // Alt kısımdan biraz boşluk
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
      color: Colors.grey[900], // Koyu tema uyumu
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
