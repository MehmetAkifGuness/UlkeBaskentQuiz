// lib/screens/leaderboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/user.service.dart';

class LeaderboardScreen extends StatefulWidget {
  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final UserService _userService = UserService();

  final List<String> _categories = [
    "🔥 Günün Görevi",
    "♾️ Sonsuz Mod", // 🚨 YENİ EKLENDİ: Ana kategoriler arasına alındı
    "Dünya",
    "Avrupa",
    "Asya",
    "Afrika",
    "Kuzey Amerika",
    "Güney Amerika",
    "Okyanusya",
  ];

  String _selectedCategory = "🔥 Günün Görevi";
  String _selectedMode = "COUNTRY_TO_CAPITAL";

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
        String apiCategory = _selectedCategory;
        String apiMode = _selectedMode;

        // 🚨 YENİ EKLENDİ: Seçime göre API'ye gidecek kategori ve modları ayarlıyoruz
        if (_selectedCategory == "🔥 Günün Görevi") {
          apiCategory = "DailyChallenge";
          apiMode = "MIXED";
        } else if (_selectedCategory == "♾️ Sonsuz Mod") {
          apiCategory = "Dünya";
          apiMode =
              "ENDLESS"; // Sonsuz Mod backend'de Dünya_ENDLESS olarak tutuluyor
        }

        _leaderboardData = await _userService.getCategoryLeaderboard(
          token,
          apiCategory,
          apiMode,
        );
      }
    } catch (e) {
      print("Leaderboard hatası: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _getMedal(int index) {
    if (index == 0)
      return Icon(Icons.workspace_premium, color: Colors.amber, size: 32);
    if (index == 1)
      return Icon(Icons.workspace_premium, color: Colors.grey[400], size: 32);
    if (index == 2)
      return Icon(Icons.workspace_premium, color: Colors.brown[300], size: 32);
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

                Color? bgColor = isSelected ? Colors.amber : Colors.grey[800];
                if (category == "🔥 Günün Görevi" && !isSelected) {
                  bgColor = Colors.red[900];
                } else if (category == "♾️ Sonsuz Mod" && !isSelected) {
                  bgColor = Colors
                      .deepOrange[800]; // Sonsuz modun arkası dikkat çekici olsun
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

          // 🚨 YENİ EKLENDİ: Günün Görevi ve Sonsuz Modda Alt Seçenekler Gizleniyor
          if (_selectedCategory != "🔥 Günün Görevi" &&
              _selectedCategory != "♾️ Sonsuz Mod")
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Wrap(
                spacing: 8.0,
                alignment: WrapAlignment.center,
                children: [
                  ChoiceChip(
                    label: Text(
                      "Ülke ➡ Başkent",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    selected: _selectedMode == "COUNTRY_TO_CAPITAL",
                    selectedColor: Colors.blueAccent,
                    onSelected: (bool selected) {
                      setState(() => _selectedMode = "COUNTRY_TO_CAPITAL");
                      _fetchLeaderboard();
                    },
                  ),
                  ChoiceChip(
                    label: Text(
                      "Başkent ➡ Ülke",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    selected: _selectedMode == "CAPITAL_TO_COUNTRY",
                    selectedColor: Colors.blueAccent,
                    onSelected: (bool selected) {
                      setState(() => _selectedMode = "CAPITAL_TO_COUNTRY");
                      _fetchLeaderboard();
                    },
                  ),
                  ChoiceChip(
                    label: Text(
                      "🔀 Karışık",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    selected: _selectedMode == "MIXED",
                    selectedColor: Colors.blueAccent,
                    onSelected: (bool selected) {
                      setState(() => _selectedMode = "MIXED");
                      _fetchLeaderboard();
                    },
                  ),
                ],
              ),
            ),

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.amber))
                : _leaderboardData.isEmpty
                ? Center(
                    child: Text(
                      // 🚨 YENİ EKLENDİ: Listeler boşsa verilecek akıllı mesajlar
                      _selectedCategory == "🔥 Günün Görevi"
                          ? "Bugün listeye henüz kimse giremedi.\nİlk giren sen ol!"
                          : _selectedCategory == "♾️ Sonsuz Mod"
                          ? "Sonsuz modda henüz kimse rekor kırmadı.\nİlk rekoru sen belirle!"
                          : "Bu modda henüz skor yok.",
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
                        elevation: index < 3 ? 4 : 1,
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
