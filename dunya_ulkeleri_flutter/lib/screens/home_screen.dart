import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_profile_model.dart';
import '../services/user.service.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserService _userService = UserService();
  bool _hasPlayedDaily = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkDailyStatus();
  }

  // Kullanıcının bugün görevi yapıp yapmadığını kontrol ediyoruz
  Future<void> _checkDailyStatus() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      UserProfileModel? profile = await _userService.getUserProfile(token);
      if (profile != null && mounted) {
        setState(() {
          _hasPlayedDaily = profile.hasPlayedDaily;
          _isLoading = false;
        });
      }
    }
  }

  final List<String> categories = [
    "Dünya",
    "Avrupa",
    "Asya",
    "Afrika",
    "Kuzey Amerika",
    "Güney Amerika",
    "Okyanusya",
  ];

  // 🚨 YENİ: Şık BottomSheet ile hem Mod hem Kategori Seçimi
  void _showCategorySelection(BuildContext context) {
    String selectedMode = "COUNTRY_TO_CAPITAL"; // Varsayılan mod

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Listenin taşmaması için
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          // BottomSheet içindeki butonların renk değiştirmesi için
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Oyun Modunu Seç",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),

                  // OYUN MODU BUTONLARI (Chip)
                  Wrap(
                    spacing: 8.0,
                    alignment: WrapAlignment.center,
                    children: [
                      ChoiceChip(
                        label: Text("Ülke ➡ Başkent"),
                        selected: selectedMode == "COUNTRY_TO_CAPITAL",
                        onSelected: (bool selected) {
                          setModalState(() {
                            selectedMode = "COUNTRY_TO_CAPITAL";
                          });
                        },
                      ),
                      ChoiceChip(
                        label: Text("Başkent ➡ Ülke"),
                        selected: selectedMode == "CAPITAL_TO_COUNTRY",
                        onSelected: (bool selected) {
                          setModalState(() {
                            selectedMode = "CAPITAL_TO_COUNTRY";
                          });
                        },
                      ),
                      ChoiceChip(
                        label: Text("🔀 Karışık"),
                        selected: selectedMode == "MIXED",
                        onSelected: (bool selected) {
                          setModalState(() {
                            selectedMode = "MIXED";
                          });
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 15),
                  Divider(),

                  Text(
                    "Nerede Oynamak İstersin?",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),

                  // KITA LİSTESİ
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return ListTile(
                          leading: Icon(
                            category == "Dünya" ? Icons.public : Icons.map,
                            color: Colors.blueAccent,
                          ),
                          title: Text(category, style: TextStyle(fontSize: 18)),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GameScreen(
                                  category: category,
                                  mode: selectedMode,
                                ), // 🚨 YENİ: Seçilen modu gönderdik
                              ),
                            ).then(
                              (_) => _checkDailyStatus(),
                            ); // Oyun bitince ana ekranı yenile
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Ana Sayfa"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.amber))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              // 🚨 YENİ: Ekran taşmasın diye Column yerine ListView kullandık
              child: ListView(
                physics: BouncingScrollPhysics(),
                children: [
                  SizedBox(height: 30),
                  Text(
                    "Hoş Geldin, ${authProvider.username}!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 30),

                  // 🎯 GÜNÜN GÖREVİ KARTI (Eski Kodların Aynı)
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: _hasPlayedDaily
                        ? Colors.grey[800]
                        : Colors.deepPurple[800],
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _hasPlayedDaily
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GameScreen(
                                    category: "DailyChallenge",
                                    mode: "MIXED",
                                  ),
                                ),
                              ).then((_) => _checkDailyStatus());
                            },
                      child: Padding(
                        padding: const EdgeInsets.all(25.0),
                        child: Column(
                          children: [
                            Icon(
                              _hasPlayedDaily
                                  ? Icons.check_circle
                                  : Icons.calendar_month,
                              size: 60,
                              color: _hasPlayedDaily
                                  ? Colors.green
                                  : Colors.amber,
                            ),
                            SizedBox(height: 15),
                            Text(
                              "Günün Görevi",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              _hasPlayedDaily
                                  ? "Bugünkü görevi tamamladın!\nYarın tekrar gel."
                                  : "Dünyadaki herkesle aynı 10 soruyu çöz\nve liderlik tablosuna gir!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _hasPlayedDaily
                                    ? Colors.grey
                                    : Colors.amber[100],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20), // Kartlar arası boşluk
                  // ♾️ YENİ: SONSUZ MOD KARTI
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Colors.redAccent[700], // İddialı bir kırmızı renk
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        // Kategori "Dünya", Mod "ENDLESS" olarak başlatıyoruz
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                GameScreen(category: "Dünya", mode: "ENDLESS"),
                          ),
                        ).then((_) => _checkDailyStatus());
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(25.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.all_inclusive,
                              size: 60,
                              color: Colors.white,
                            ),
                            SizedBox(height: 15),
                            Text(
                              "Sonsuz Mod",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Tek bir yanlışta oyun biter!\nBakalım ne kadar dayanacaksın?",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 30),

                  // SERBEST MODDA OYNA BUTONU (Eski Kod)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Colors.blueGrey[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    icon: Icon(Icons.public, size: 28),
                    label: Text(
                      "Serbest Modda Oyna",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => _showCategorySelection(context),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
