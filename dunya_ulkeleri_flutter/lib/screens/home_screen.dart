import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'game_screen.dart'; // GameScreen'i import ediyoruz

class HomeScreen extends StatelessWidget {
  // Veritabanındaki isimlerle birebir aynı olmalı
  final List<String> categories = [
    "Dünya",
    "Avrupa",
    "Asya",
    "Afrika",
    "Kuzey Amerika",
    "Güney Amerika",
    "Okyanusya",
  ];

  // Aşağıdan açılan Kategori Seçim Menüsü
  void _showCategorySelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Nerede Oynamak İstersin?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Divider(),
              Expanded(
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
                        // 1. Önce bu menüyü kapat
                        Navigator.pop(context);

                        // 2. Seçilen kategoriyle beraber Oyun Ekranına geç
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                GameScreen(category: category),
                          ),
                        );
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Hoş Geldin, ${authProvider.username}!",
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Artık doğrudan oyunu başlatmıyor, seçim menüsünü açıyor
                _showCategorySelection(context);
              },
              child: Text("Oyuna Başla", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
