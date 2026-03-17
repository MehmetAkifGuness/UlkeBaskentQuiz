import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/game_service.dart';
import '../models/dictionary_model.dart'; // Model dosyanın yolunun doğru olduğundan emin ol

class DictionaryScreen extends StatefulWidget {
  @override
  _DictionaryScreenState createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final GameService _gameService = GameService();
  final TextEditingController _searchController = TextEditingController();

  List<DictionaryModel> _allData = [];
  List<DictionaryModel> _filteredData = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDictionaryData();
  }

  Future<void> _fetchDictionaryData() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        final data = await _gameService.getDictionary(token);
        setState(() {
          _allData = data;
          _filteredData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Sözlük verileri yüklenemedi: $e";
        _isLoading = false;
      });
    }
  }

  // Arama çubuğuna yazı yazıldıkça listeyi filtreleyen metod
  String _toTurkishLowerCase(String text) {
    return text
        .replaceAll('I', 'ı')
        .replaceAll('İ', 'i')
        .replaceAll('Ğ', 'ğ')
        .replaceAll('Ü', 'ü')
        .replaceAll('Ş', 'ş')
        .replaceAll('Ö', 'ö')
        .replaceAll('Ç', 'ç')
        .toLowerCase();
  }

  void _filterData(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredData = _allData;
      });
    } else {
      setState(() {
        _filteredData = _allData.where((item) {
          // 🚨 Null güvenliği eklendi (item.değişken ?? '')
          final countryLower = (item.countryName ?? '').toLowerCase();
          final capitalLower = (item.capitalName ?? '').toLowerCase();
          final continentLower = (item.continent ?? '').toLowerCase();
          final searchLower = query.toLowerCase();

          // Ülke, Başkent veya Kıtaya göre arama yapabilir
          return countryLower.contains(searchLower) ||
              capitalLower.contains(searchLower) ||
              continentLower.contains(searchLower);
        }).toList();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Öğren & Keşfet",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- ARAMA ÇUBUĞU (SEARCH BAR) ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterData,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Ülke, Başkent veya Kıta Ara...",
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Colors.amber),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 0,
                ), // Dikey hizalamayı düzeltir
              ),
            ),
          ),

          // --- LİSTE VEYA YÜKLENİYOR EKRANI ---
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.amber))
                : _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                  )
                : _filteredData.isEmpty
                ? Center(
                    child: Text(
                      "Aradığınız kriterde sonuç bulunamadı.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredData.length,
                    itemBuilder: (context, index) {
                      final item = _filteredData[index];
                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        color: Colors.blueGrey[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 3,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.amber,
                            child: Icon(Icons.public, color: Colors.black),
                          ),
                          title: Text(
                            // 🚨 Null güvenliği eklendi
                            item.countryName ?? 'Bilinmiyor',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            // 🚨 Null güvenliği eklendi
                            "${item.capitalName ?? 'Bilinmiyor'} • ${item.continent ?? 'Bilinmiyor'}",
                            style: TextStyle(color: Colors.amber[200]),
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
