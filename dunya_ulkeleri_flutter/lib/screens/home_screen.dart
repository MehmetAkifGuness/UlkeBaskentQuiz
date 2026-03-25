// lib/screens/home_screen.dart
import 'package:dunya_ulkeleri_flutter/utils/page_trasitions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart'; // 🚨 YENİ EKLENDİ
import '../models/user_profile_model.dart';
import '../services/user.service.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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

  // Şık BottomSheet ile hem Mod hem Kategori Seçimi
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
                          Provider.of<SettingsProvider>(
                            context,
                            listen: false,
                          ).triggerButtonVibration(); // 🚨 YENİ
                          setModalState(() {
                            selectedMode = "COUNTRY_TO_CAPITAL";
                          });
                        },
                      ),
                      ChoiceChip(
                        label: Text("Başkent ➡ Ülke"),
                        selected: selectedMode == "CAPITAL_TO_COUNTRY",
                        onSelected: (bool selected) {
                          Provider.of<SettingsProvider>(
                            context,
                            listen: false,
                          ).triggerButtonVibration(); // 🚨 YENİ
                          setModalState(() {
                            selectedMode = "CAPITAL_TO_COUNTRY";
                          });
                        },
                      ),
                      ChoiceChip(
                        label: Text("🔀 Karışık"),
                        selected: selectedMode == "MIXED",
                        onSelected: (bool selected) {
                          Provider.of<SettingsProvider>(
                            context,
                            listen: false,
                          ).triggerButtonVibration(); // 🚨 YENİ
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
                            Provider.of<SettingsProvider>(
                              context,
                              listen: false,
                            ).triggerButtonVibration(); // 🚨 YENİ
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              FadePageRoute(
                                page: GameScreen(
                                  category: category,
                                  mode: selectedMode,
                                  isContinuing: false,
                                ),
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
    final gameProvider = Provider.of<GameProvider>(context);
    bool hasActiveGame =
        gameProvider.status != null && gameProvider.status?.finished == false;

    return Scaffold(
      appBar: AppBar(
        title: Text("Ana Sayfa"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Provider.of<SettingsProvider>(
                context,
                listen: false,
              ).triggerButtonVibration(); // 🚨 YENİ
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.amber))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
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

                  if (hasActiveGame) ...[
                    Container(
                      margin: EdgeInsets.only(bottom: 20),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: Colors.green.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(
                              color: Colors.lightGreenAccent,
                              width: 2,
                            ),
                          ),
                        ),
                        icon: Icon(Icons.play_arrow_rounded, size: 30),
                        label: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Kaldığın Yerden Devam Et",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Skor: ${gameProvider.status?.currentScore ?? 0} | Can: ${gameProvider.status?.remainingLives ?? 0}",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        onPressed: () {
                          Provider.of<SettingsProvider>(
                            context,
                            listen: false,
                          ).triggerButtonVibration(); // 🚨 YENİ
                          // Oyuna kaldığı yerden yönlendir (isContinuing: true)
                          Navigator.push(
                            context,
                            FadePageRoute(
                              page: GameScreen(
                                category: "Devam",
                                mode: "Devam",
                                isContinuing: true,
                              ),
                            ),
                          ).then((_) => _checkDailyStatus());
                        },
                      ),
                    ),
                  ],

                  // 🎯 GÜNÜN GÖREVİ KARTI
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
                              Provider.of<SettingsProvider>(
                                context,
                                listen: false,
                              ).triggerButtonVibration(); // 🚨 YENİ
                              Provider.of<GameProvider>(
                                context,
                                listen: false,
                              ).resetGame();
                              Navigator.push(
                                context,
                                FadePageRoute(
                                  page: GameScreen(
                                    category: "DailyChallenge",
                                    mode: "MIXED",
                                    isContinuing: false,
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
                  // ♾️ SONSUZ MOD KARTI
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Colors.redAccent[700], // İddialı bir kırmızı renk
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Provider.of<SettingsProvider>(
                          context,
                          listen: false,
                        ).triggerButtonVibration(); // 🚨 YENİ
                        Provider.of<GameProvider>(
                          context,
                          listen: false,
                        ).resetGame();
                        Navigator.push(
                          context,
                          FadePageRoute(
                            page: GameScreen(
                              category: "Dünya",
                              mode: "ENDLESS",
                              isContinuing: false,
                            ),
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

                  // SERBEST MODDA OYNA BUTONU
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
                    onPressed: () {
                      Provider.of<SettingsProvider>(
                        context,
                        listen: false,
                      ).triggerButtonVibration(); // 🚨 YENİ
                      _showCategorySelection(context);
                    },
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
