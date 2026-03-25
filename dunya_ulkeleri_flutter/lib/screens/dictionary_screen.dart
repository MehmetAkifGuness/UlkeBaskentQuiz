// ignore_for_file: dead_null_aware_expression, dead_code

import 'package:dunya_ulkeleri_flutter/utils/page_trasitions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart'; // 🚨 TİTREŞİM İÇİN EKLENDİ
import '../services/game_service.dart';
import '../models/dictionary_model.dart';
import 'country_detail_screen.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

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
          final countryLower = (item.countryName ?? '').toLowerCase();
          final capitalLower = (item.capitalName ?? '').toLowerCase();
          final continentLower = (item.continent ?? '').toLowerCase();
          final searchLower = query.toLowerCase();

          return countryLower.contains(searchLower) ||
              capitalLower.contains(searchLower) ||
              continentLower.contains(searchLower);
        }).toList();
      });
    }
  }

  String _getFlagEmoji(String country) {
    const Map<String, String> flagMap = {
      "Afganistan": "🇦🇫",
      "Almanya": "🇩🇪",
      "Amerika Birleşik Devletleri": "🇺🇸",
      "Andorra": "🇦🇩",
      "Angola": "🇦🇴",
      "Antigua ve Barbuda": "🇦🇬",
      "Arjantin": "🇦🇷",
      "Arnavutluk": "🇦🇱",
      "Avustralya": "🇦🇺",
      "Avusturya": "🇦🇹",
      "Azerbaycan": "🇦🇿",
      "Bahamalar": "🇧🇸",
      "Bahreyn": "🇧🇭",
      "Bangladeş": "🇧🇩",
      "Barbados": "🇧🇧",
      "Belçika": "🇧🇪",
      "Belize": "🇧🇿",
      "Benin": "🇧🇯",
      "Belarus (Beyaz Rusya)": "🇧🇾",
      "Bhutan": "🇧🇹",
      "Birleşik Arap Emirlikleri": "🇦🇪",
      "Birleşik Krallık": "🇬🇧",
      "Bolivya": "🇧🇴",
      "Bosna-Hersek": "🇧🇦",
      "Botsvana": "🇧🇼",
      "Brezilya": "🇧🇷",
      "Brunei": "🇧🇳",
      "Bulgaristan": "🇧🇬",
      "Burkina Faso": "🇧🇫",
      "Burundi": "🇧🇮",
      "Cezayir": "🇩🇿",
      "Cibuti": "🇩🇯",
      "Çad": "🇹🇩",
      "Çekya": "🇨🇿",
      "Çin": "🇨🇳",
      "Danimarka": "🇩🇰",
      "Doğu Timor": "🇹🇱",
      "Dominik Cumhuriyeti": "🇩🇴",
      "Dominika": "🇩🇲",
      "Ekvador": "🇪🇨",
      "Ekvator Ginesi": "🇬🇶",
      "El Salvador": "🇸🇻",
      "Endonezya": "🇮🇩",
      "Eritre": "🇪🇷",
      "Ermenistan": "🇦🇲",
      "Estonya": "🇪🇪",
      "Esvatini": "🇸🇿",
      "Etiyopya": "🇪🇹",
      "Fas": "🇲🇦",
      "Fiji": "🇫🇯",
      "Fildişi Sahili": "🇨🇮",
      "Filipinler": "🇵🇭",
      "Filistin": "🇵🇸",
      "Finlandiya": "🇫🇮",
      "Fransa": "🇫🇷",
      "Gabon": "🇬🇦",
      "Gambiya": "🇬🇲",
      "Gana": "🇬🇭",
      "Gine": "🇬🇳",
      "Gine-Bissau": "🇬🇼",
      "Grenada": "🇬🇩",
      "Guatemala": "🇬🇹",
      "Guyana": "🇬🇾",
      "Güney Afrika": "🇿🇦",
      "Güney Kore": "🇰🇷",
      "Güney Sudan": "🇸🇸",
      "Gürcistan": "🇬🇪",
      "Haiti": "🇭🇹",
      "Hırvatistan": "🇭🇷",
      "Hindistan": "🇮🇳",
      "Hollanda": "🇳🇱",
      "Honduras": "🇭🇳",
      "Irak": "🇮🇶",
      "İran": "🇮🇷",
      "İrlanda": "🇮🇪",
      "İspanya": "🇪🇸",
      "İsrail": "🇮🇱",
      "İsveç": "🇸🇪",
      "İsviçre": "🇨🇭",
      "İtalya": "🇮🇹",
      "İzlanda": "🇮🇸",
      "Jamaika": "🇯🇲",
      "Japonya": "🇯🇵",
      "Kamboçya": "🇰🇭",
      "Kamerun": "🇨🇲",
      "Kanada": "🇨🇦",
      "Karadağ": "🇲🇪",
      "Katar": "🇶🇦",
      "Kazakistan": "🇰🇿",
      "Kenya": "🇰🇪",
      "Kıbrıs Cumhuriyeti": "🇨🇾",
      "Kırgızistan": "🇰🇬",
      "Kiribati": "🇰🇮",
      "Kolombiya": "🇨🇴",
      "Komorlar": "🇰🇲",
      "Kongo Cumhuriyeti": "🇨🇬",
      "Kongo Demokratik Cumhuriyeti": "🇨🇩",
      "Kosta Rika": "🇨🇷",
      "Kuveyt": "🇰🇼",
      "Kuzey Kore": "🇰🇵",
      "Kuzey Makedonya": "🇲🇰",
      "Küba": "🇨🇺",
      "Laos": "🇱🇦",
      "Lesotho": "🇱🇸",
      "Letonya": "🇱🇻",
      "Liberya": "🇱🇷",
      "Libya": "🇱🇾",
      "Liechtenstein": "🇱🇮",
      "Litvanya": "🇱🇹",
      "Lübnan": "🇱🇧",
      "Lüksemburg": "🇱🇺",
      "Macaristan": "🇭🇺",
      "Madagaskar": "🇲🇬",
      "Malavi": "🇲🇼",
      "Maldivler": "🇲🇻",
      "Malezya": "🇲🇾",
      "Mali": "🇲🇱",
      "Malta": "🇲🇹",
      "Marshall Adaları": "🇲🇭",
      "Mauritius": "🇲🇺",
      "Meksika": "🇲🇽",
      "Mısır": "🇪🇬",
      "Mikronezya": "🇫🇲",
      "Moğolistan": "🇲🇳",
      "Moldova": "🇲🇩",
      "Monako": "🇲🇨",
      "Moritanya": "🇲🇷",
      "Mozambik": "🇲🇿",
      "Myanmar": "🇲🇲",
      "Namibya": "🇳🇦",
      "Nauru": "🇳🇷",
      "Nepal": "🇳🇵",
      "Nikaragua": "🇳🇮",
      "Nijer": "🇳🇪",
      "Nijerya": "🇳🇬",
      "Norveç": "🇳🇴",
      "Orta Afrika Cumhuriyeti": "🇨🇫",
      "Özbekistan": "🇺🇿",
      "Pakistan": "🇵🇰",
      "Palau": "🇵🇼",
      "Panama": "🇵🇦",
      "Papua Yeni Gine": "🇵🇬",
      "Paraguay": "🇵🇾",
      "Peru": "🇵🇪",
      "Polonya": "🇵🇱",
      "Portekiz": "🇵🇹",
      "Romanya": "🇷🇴",
      "Ruanda": "🇷🇼",
      "Rusya": "🇷🇺",
      "Saint Kitts ve Nevis": "🇰🇳",
      "Saint Lucia": "🇱🇨",
      "Saint Vincent ve Grenadinler": "🇻🇨",
      "Samoa": "🇼🇸",
      "San Marino": "🇸🇲",
      "Sao Tome ve Principe": "🇸🇹",
      "Senegal": "🇸🇳",
      "Seyşeller": "🇸🇨",
      "Sırbistan": "🇷🇸",
      "Sierra Leone": "🇸🇱",
      "Singapur": "🇸🇬",
      "Slovakya": "🇸🇰",
      "Slovenya": "🇸🇮",
      "Solomon Adaları": "🇸🇧",
      "Somali": "🇸🇴",
      "Sri Lanka": "🇱🇰",
      "Sudan": "🇸🇩",
      "Surinam": "🇸🇷",
      "Suriye": "🇸🇾",
      "Suudi Arabistan": "🇸🇦",
      "Şili": "🇨🇱",
      "Tacikistan": "🇹🇯",
      "Tanzanya": "🇹🇿",
      "Tayland": "🇹🇭",
      "Togo": "🇹🇬",
      "Tonga": "🇹🇴",
      "Trinidad ve Tobago": "🇹🇹",
      "Tunus": "🇹🇳",
      "Tuvalu": "🇹🇻",
      "Türkiye": "🇹🇷",
      "Türkmenistan": "🇹🇲",
      "Uganda": "🇺🇬",
      "Ukrayna": "🇺🇦",
      "Umman": "🇴🇲",
      "Uruguay": "🇺🇾",
      "Ürdün": "🇯🇴",
      "Vanuatu": "🇻🇺",
      "Vatikan": "🇻🇦",
      "Venezuela": "🇻🇪",
      "Vietnam": "🇻🇳",
      "Yemen": "🇾🇪",
      "Yeni Zelanda": "🇳🇿",
      "Yeşil Burun Adaları": "🇨🇻",
      "Yunanistan": "🇬🇷",
      "Zambiya": "🇿🇲",
      "Zimbabve": "🇿🇼",
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
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

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
                        color: Colors.grey[900],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: Colors.white12, width: 1),
                        ),
                        elevation: 3,
                        child: ListTile(
                          onTap: () {
                            // 🚨 TİTREŞİM TETİKLENDİ
                            Provider.of<SettingsProvider>(
                              context,
                              listen: false,
                            ).triggerButtonVibration();

                            // 🚨 YUMUŞAK GEÇİŞ ENTEGRE EDİLDİ
                            Navigator.push(
                              context,
                              FadePageRoute(
                                page: CountryDetailScreen(
                                  countryName: item.countryName ?? 'Bilinmiyor',
                                  capitalName: item.capitalName ?? 'Bilinmiyor',
                                  continent: item.continent ?? 'Bilinmiyor',
                                ),
                              ),
                            );
                          },
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.white54,
                          ),
                          leading: Text(
                            _getFlagEmoji(item.countryName ?? ''),
                            style: TextStyle(fontSize: 35),
                          ),
                          title: Text(
                            item.countryName ?? 'Bilinmiyor',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
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
