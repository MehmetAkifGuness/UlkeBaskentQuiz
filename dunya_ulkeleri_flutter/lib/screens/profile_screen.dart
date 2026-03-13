import 'package:dunya_ulkeleri_flutter/services/user.service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_profile_model.dart';

class ProfileScreen extends StatelessWidget {
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text("Profilim")),
      body: FutureBuilder<UserProfileModel?>(
        future: _userService.getUserProfile(authProvider.token!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text("Profil bilgileri alınamadı."));
          }

          final profile = snapshot.data!;
          // Tarihi daha güzel göstermek için parçalayabiliriz
          final date = DateTime.parse(profile.creationDate);
          final formattedDate = "${date.day}/${date.month}/${date.year}";

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
                SizedBox(height: 20),
                Text(
                  profile.username,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 30),
                _buildStatCard(
                  "Kayıt Tarihi",
                  formattedDate,
                  Icons.calendar_today,
                ),
                _buildStatCard(
                  "En Yüksek Skor",
                  profile.maxWinStreak.toString(),
                  Icons.emoji_events,
                ),
                _buildStatCard(
                  "Oynanan Oyun",
                  profile.totalGamesPlayed.toString(),
                  Icons.videogame_asset,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(icon, size: 30, color: Colors.blue),
        title: Text(title, style: TextStyle(fontSize: 18)),
        trailing: Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
