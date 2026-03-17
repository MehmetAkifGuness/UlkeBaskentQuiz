import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/user.service.dart'; // isme dikkat et, senin projende user_service.dart olabilir

class LeaderboardScreen extends StatefulWidget {
  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final UserService _userService = UserService();

  // 🚨 YENİ EKLENDİ: "🔥 Günün Görevi" listeye en başa alındı
  final List<String> _categories = [
    "🔥 Günün Görevi",
    "Dünya",
    "Avrupa",
    "Asya",
    "Afrika",
    "Kuzey Amerika",
    "Güney Amerika",
    "Okyanusya",
  ];

  // 🚨 Varsayılan açılış kategorisi değiştirildi
  String _selectedCategory = "🔥 Günün Görevi";

  List<Map<String, dynamic>> _leaderboardData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        // 🚨 SİHİRLİ DOKUNUŞ: Eğer "Günün Görevi" seçiliyse, backend'e "DailyChallenge" yazısını yolla
        String apiCategory = _selectedCategory == "🔥 Günün Görevi"
            ? "DailyChallenge"
            : _selectedCategory;

        _leaderboardData = await _userService.getCategoryLeaderboard(
          token,
          apiCategory,
        );
      }
    } catch (e) {
      print("Leaderboard hatası: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // İlk 3 kişi için şık madalyalar
  Widget _getMedal(int index) {
    if (index == 0)
      return Icon(
        Icons.workspace_premium,
        color: Colors.amber,
        size: 32,
      ); // Altın
    if (index == 1)
      return Icon(
        Icons.workspace_premium,
        color: Colors.grey[400],
        size: 32,
      ); // Gümüş
    if (index == 2)
      return Icon(
        Icons.workspace_premium,
        color: Colors.brown[300],
        size: 32,
      ); // Bronz
    return CircleAvatar(
      backgroundColor: Colors.blueGrey,
      radius: 14,
      child: Text(
        "${index + 1}",
        style: TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("🏆 Liderlik Tablosu"), centerTitle: true),
      body: Column(
        children: [
          // YATAY KATEGORİ SEÇİCİ
          Container(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;

                // 🚨 TASARIM DOKUNUŞU: Günün Görevi seçili değilse arka planı Kırmızı kalsın ki dikkat çeksin!
                Color? bgColor = isSelected ? Colors.amber : Colors.grey[800];
                if (category == "🔥 Günün Görevi" && !isSelected) {
                  bgColor = Colors.red[900];
                }

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                    _fetchLeaderboard();
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.amber))
                : _leaderboardData.isEmpty
                ? Center(
                    // 🚨 EĞER GÜNLÜK GÖREVSE MESAJI DAHA GÜZEL VERELİM
                    child: Text(
                      _selectedCategory == "🔥 Günün Görevi"
                          ? "Bugün listeye henüz kimse giremedi.\nİlk giren sen ol!"
                          : "Bu kategoride henüz skor yok.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                    ),
                  )
                : ListView.builder(
                    itemCount: _leaderboardData.length,
                    itemBuilder: (context, index) {
                      final user = _leaderboardData[index];
                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        elevation: index < 3 ? 4 : 1, // İlk 3'e özel gölge
                        color: index == 0
                            ? Colors.amber.withOpacity(0.1)
                            : null,
                        child: ListTile(
                          leading: _getMedal(index),
                          title: Text(
                            user['username'].toString(),
                            style: TextStyle(
                              fontWeight: index < 3
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 18,
                            ),
                          ),
                          trailing: Text(
                            "${user['score']} Puan",
                            style: TextStyle(
                              color: Colors.amber[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
