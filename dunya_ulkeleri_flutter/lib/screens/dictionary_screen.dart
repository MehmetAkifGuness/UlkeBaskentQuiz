// ignore_for_file: dead_code

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
  // ignore: unused_element
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
          // ignore: duplicate_ignore
          // ignore: dead_null_aware_expression, dead_code
          final countryLower = (item.countryName ?? '').toLowerCase();
          // ignore: dead_null_aware_expression
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

  // 🚨 YENİ EKLENEN: Ülke isimlerini emoji bayraklara çeviren sözlük!
  // 🚨 EKSİKSİZ BAYRAK KÜTÜPHANESİ (143 ÜLKE)
  String _getFlagEmoji(String country) {
    const Map<String, String> flagMap = {
      // A
      "Afganistan": "🇦🇫",
      "Almanya": "🇩🇪",
      "Amerika Birleşik Devletleri": "🇺🇸",
      "Andorra": "🇦🇩", "Angola": "🇦🇴", "Antigua ve Barbuda": "🇦🇬",
      "Arjantin": "🇦🇷", "Arnavutluk": "🇦🇱", "Avustralya": "🇦🇺",
      "Avusturya": "🇦🇹", "Azerbaycan": "🇦🇿",

      // B
      "Bahamalar": "🇧🇸", "Bahreyn": "🇧🇭", "Bangladeş": "🇧🇩",
      "Barbados": "🇧🇧", "Belçika": "🇧🇪", "Belize": "🇧🇿",
      "Benin": "🇧🇯", "Belarus (Beyaz Rusya)": "🇧🇾", "Bhutan": "🇧🇹",
      "Birleşik Arap Emirlikleri": "🇦🇪", "Birleşik Krallık": "🇬🇧",
      "Bolivya": "🇧🇴", "Bosna-Hersek": "🇧🇦", "Botsvana": "🇧🇼",
      "Brezilya": "🇧🇷", "Brunei": "🇧🇳", "Bulgaristan": "🇧🇬",
      "Burkina Faso": "🇧🇫", "Burundi": "🇧🇮",

      // C - Ç
      "Cezayir": "🇩🇿", "Cibuti": "🇩🇯", "Çad": "🇹🇩",
      "Çekya": "🇨🇿", "Çin": "🇨🇳",

      // D
      "Danimarka": "🇩🇰", "Doğu Timor": "🇹🇱", "Dominik Cumhuriyeti": "🇩🇴",
      "Dominika": "🇩🇲",

      // E
      "Ekvador": "🇪🇨", "Ekvator Ginesi": "🇬🇶", "El Salvador": "🇸🇻",
      "Endonezya": "🇮🇩", "Eritre": "🇪🇷", "Ermenistan": "🇦🇲",
      "Estonya": "🇪🇪", "Esvatini": "🇸🇿", "Etiyopya": "🇪🇹",

      // F
      "Fas": "🇲🇦", "Fiji": "🇫🇯", "Fildişi Sahili": "🇨🇮",
      "Filipinler": "🇵🇭", "Filistin": "🇵🇸", "Finlandiya": "🇫🇮",
      "Fransa": "🇫🇷",

      // G
      "Gabon": "🇬🇦", "Gambiya": "🇬🇲", "Gana": "🇬🇭",
      "Gine": "🇬🇳", "Gine-Bissau": "🇬🇼", "Grenada": "🇬🇩",
      "Guatemala": "🇬🇹", "Guyana": "🇬🇾", "Güney Afrika": "🇿🇦",
      "Güney Kore": "🇰🇷", "Güney Sudan": "🇸🇸", "Gürcistan": "🇬🇪",

      // H
      "Haiti": "🇭🇹", "Hırvatistan": "🇭🇷", "Hindistan": "🇮🇳",
      "Hollanda": "🇳🇱", "Honduras": "🇭🇳",

      // I - İ
      "Irak": "🇮🇶", "İran": "🇮🇷", "İrlanda": "🇮🇪",
      "İspanya": "🇪🇸", "İsrail": "🇮🇱", "İsveç": "🇸🇪",
      "İsviçre": "🇨🇭", "İtalya": "🇮🇹", "İzlanda": "🇮🇸",

      // J
      "Jamaika": "🇯🇲", "Japonya": "🇯🇵",

      // K
      "Kamboçya": "🇰🇭", "Kamerun": "🇨🇲", "Kanada": "🇨🇦",
      "Karadağ": "🇲🇪", "Katar": "🇶🇦", "Kazakistan": "🇰🇿",
      "Kenya": "🇰🇪", "Kıbrıs Cumhuriyeti": "🇨🇾", "Kırgızistan": "🇰🇬",
      "Kiribati": "🇰🇮", "Kolombiya": "🇨🇴", "Komorlar": "🇰🇲",
      "Kongo Cumhuriyeti": "🇨🇬", "Kongo Demokratik Cumhuriyeti": "🇨🇩",
      "Kosta Rika": "🇨🇷",
      "Kuveyt": "🇰🇼",
      "Kuzey Kore": "🇰🇵", "Kuzey Makedonya": "🇲🇰", "Küba": "🇨🇺",

      // L
      "Laos": "🇱🇦", "Lesotho": "🇱🇸", "Letonya": "🇱🇻",
      "Liberya": "🇱🇷", "Libya": "🇱🇾", "Liechtenstein": "🇱🇮",
      "Litvanya": "🇱🇹", "Lübnan": "🇱🇧", "Lüksemburg": "🇱🇺",

      // M
      "Macaristan": "🇭🇺", "Madagaskar": "🇲🇬", "Malavi": "🇲🇼",
      "Maldivler": "🇲🇻", "Malezya": "🇲🇾", "Mali": "🇲🇱",
      "Malta": "🇲🇹", "Marshall Adaları": "🇲🇭", "Mauritius": "🇲🇺",
      "Meksika": "🇲🇽", "Mısır": "🇪🇬", "Mikronezya": "🇫🇲",
      "Moğolistan": "🇲🇳", "Moldova": "🇲🇩", "Monako": "🇲🇨",
      "Moritanya": "🇲🇷", "Mozambik": "🇲🇿", "Myanmar": "🇲🇲",

      // N
      "Namibya": "🇳🇦", "Nauru": "🇳🇷", "Nepal": "🇳🇵",
      "Nikaragua": "🇳🇮", "Nijer": "🇳🇪", "Nijerya": "🇳🇬",
      "Norveç": "🇳🇴",

      // O - Ö
      "Orta Afrika Cumhuriyeti": "🇨🇫", "Özbekistan": "🇺🇿",

      // P
      "Pakistan": "🇵🇰", "Palau": "🇵🇼", "Panama": "🇵🇦",
      "Papua Yeni Gine": "🇵🇬", "Paraguay": "🇵🇾", "Peru": "🇵🇪",
      "Polonya": "🇵🇱", "Portekiz": "🇵🇹",

      // R
      "Romanya": "🇷🇴", "Ruanda": "🇷🇼", "Rusya": "🇷🇺",

      // S - Ş
      "Saint Kitts ve Nevis": "🇰🇳", "Saint Lucia": "🇱🇨",
      "Saint Vincent ve Grenadinler": "🇻🇨", "Samoa": "🇼🇸",
      "San Marino": "🇸🇲", "Sao Tome ve Principe": "🇸🇹",
      "Senegal": "🇸🇳", "Seyşeller": "🇸🇨", "Sırbistan": "🇷🇸",
      "Sierra Leone": "🇸🇱", "Singapur": "🇸🇬", "Slovakya": "🇸🇰",
      "Slovenya": "🇸🇮", "Solomon Adaları": "🇸🇧", "Somali": "🇸🇴",
      "Sri Lanka": "🇱🇰", "Sudan": "🇸🇩", "Surinam": "🇸🇷",
      "Suriye": "🇸🇾", "Suudi Arabistan": "🇸🇦", "Şili": "🇨🇱",

      // T
      "Tacikistan": "🇹🇯", "Tanzanya": "🇹🇿", "Tayland": "🇹🇭",
      "Togo": "🇹🇬", "Tonga": "🇹🇴", "Trinidad ve Tobago": "🇹🇹",
      "Tunus": "🇹🇳", "Tuvalu": "🇹🇻", "Türkiye": "🇹🇷",
      "Türkmenistan": "🇹🇲",

      // U - Ü
      "Uganda": "🇺🇬", "Ukrayna": "🇺🇦", "Umman": "🇴🇲",
      "Uruguay": "🇺🇾", "Ürdün": "🇯🇴",

      // V
      "Vanuatu": "🇻🇺", "Vatikan": "🇻🇦", "Venezuela": "🇻🇪",
      "Vietnam": "🇻🇳",

      // Y
      "Yemen": "🇾🇪", "Yeni Zelanda": "🇳🇿", "Yeşil Burun Adaları": "🇨🇻",
      "Yunanistan": "🇬🇷",

      // Z
      "Zambiya": "🇿🇲", "Zimbabve": "🇿🇼",
    };

    String cleanCountry = country.trim();
    return flagMap[cleanCountry] ?? "🏳️";
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
                          // 🚨 DEĞİŞİKLİK BURADA YAPILDI: CircleAvatar kaldırıldı, Bayrak Emojisi eklendi.
                          leading: Text(
                            _getFlagEmoji(item.countryName ?? ''),
                            style: TextStyle(
                              fontSize: 35,
                            ), // Emojinin boyutunu ayarlayabilirsin
                          ),
                          title: Text(
                            // 🚨 Null güvenliği eklendi
                            // ignore: dead_null_aware_expression
                            item.countryName ?? 'Bilinmiyor',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            // 🚨 Null güvenliği eklendi
                            // ignore: dead_null_aware_expression
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
