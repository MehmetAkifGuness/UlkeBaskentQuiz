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
  List<String> _availableContinents = const ['Hepsi'];
  String? _selectedContinent;
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
          _availableContinents = _buildContinentOptions(data);
          _filteredData = _applyFiltersTo(data, query: _searchController.text);
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

  void _onSearchChanged(String query) {
    setState(() => _filteredData = _applyFiltersTo(_allData, query: query));
  }

  List<DictionaryModel> _applyFiltersTo(
    List<DictionaryModel> source, {
    required String query,
  }) {
    final selected = _selectedContinent?.trim();
    final normalizedQuery = _toTurkishLowerCase(query.trim());

    return source.where((item) {
      final continent = (item.continent ?? '').trim();

      if (selected != null &&
          selected.isNotEmpty &&
          selected != 'Hepsi' &&
          continent != selected) {
        return false;
      }

      if (normalizedQuery.isEmpty) return true;

      final country = _toTurkishLowerCase(item.countryName ?? '');
      final capital = _toTurkishLowerCase(item.capitalName ?? '');
      final continentLower = _toTurkishLowerCase(item.continent ?? '');

      return country.contains(normalizedQuery) ||
          capital.contains(normalizedQuery) ||
          continentLower.contains(normalizedQuery);
    }).toList();
  }

  List<String> _buildContinentOptions(List<DictionaryModel> data) {
    const order = [
      'Avrupa',
      'Asya',
      'Afrika',
      'Kuzey Amerika',
      'Güney Amerika',
      'Okyanusya',
    ];

    final set = <String>{};
    for (final item in data) {
      final continent = item.continent?.trim();
      if (continent == null || continent.isEmpty) continue;
      set.add(continent);
    }

    final list = set.toList();
    list.sort((a, b) {
      final ai = order.indexOf(a);
      final bi = order.indexOf(b);
      if (ai != -1 || bi != -1) {
        return (ai == -1 ? 999 : ai).compareTo(bi == -1 ? 999 : bi);
      }
      return a.compareTo(b);
    });

    return ['Hepsi', ...list];
  }

  void _openContinentFilter() {
    Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).triggerButtonVibration();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final current = _selectedContinent ?? 'Hepsi';
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Kıta Filtresi',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final continent in _availableContinents)
                      ChoiceChip(
                        label: Text(continent),
                        selected: continent == current,
                        onSelected: (_) {
                          Provider.of<SettingsProvider>(
                            context,
                            listen: false,
                          ).triggerButtonVibration();

                          setState(() {
                            _selectedContinent = continent == 'Hepsi'
                                ? null
                                : continent;
                            _filteredData = _applyFiltersTo(
                              _allData,
                              query: _searchController.text,
                            );
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                  ],
                ),
                if (_selectedContinent != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Provider.of<SettingsProvider>(
                          context,
                          listen: false,
                        ).triggerButtonVibration();
                        setState(() {
                          _selectedContinent = null;
                          _filteredData = _applyFiltersTo(
                            _allData,
                            query: _searchController.text,
                          );
                        });
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.refresh, color: Colors.amber),
                      label: const Text(
                        'Filtreyi Sıfırla',
                        style: TextStyle(color: Colors.amber),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.amber.withOpacity(0.6)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
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
        actions: [
          IconButton(
            tooltip: 'Filtrele',
            onPressed: _openContinentFilter,
            icon: Icon(
              _selectedContinent == null
                  ? Icons.filter_list_outlined
                  : Icons.filter_list,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _selectedContinent == null
                    ? "Ülke, Başkent veya Kıta Ara..."
                    : "Ülke / Başkent Ara (${_selectedContinent!})",
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
