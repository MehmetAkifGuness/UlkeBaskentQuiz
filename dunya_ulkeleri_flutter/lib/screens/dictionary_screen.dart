import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/game_service.dart';
import '../models/dictionary_model.dart';

class DictionaryScreen extends StatefulWidget {
  @override
  _DictionaryScreenState createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final GameService _gameService = GameService();
  late Future<List<DictionaryModel>> _dictionaryFuture;

  @override
  void initState() {
    super.initState();
    // Ekran açılırken verileri bir kere çekmek için Future oluşturuyoruz.
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    _dictionaryFuture = _gameService.getDictionary(token!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Öğrenme Modu (Sözlük)"), centerTitle: true),
      body: FutureBuilder<List<DictionaryModel>>(
        future: _dictionaryFuture,
        builder: (context, snapshot) {
          // Yükleniyorsa dönen animasyon göster
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          // Hata varsa hatayı göster
          else if (snapshot.hasError) {
            return Center(child: Text("Bir hata oluştu: ${snapshot.error}"));
          }
          // Veri yoksa
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Sözlükte henüz veri yok."));
          }

          // Veriler başarıyla geldiyse listele
          final list = snapshot.data!;
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                elevation: 3,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Text(
                      item.countryName[0], // Baş harfini logoya koy
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    item.countryName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Başkent: ${item.capitalName}"),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.continent ?? "-",
                      style: TextStyle(
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
