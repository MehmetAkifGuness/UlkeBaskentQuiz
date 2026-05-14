// ignore_for_file: dead_null_aware_expression, dead_code

import 'package:dunya_ulkeleri_flutter/utils/page_trasitions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart'; // 🚨 TİTREŞİM İÇİN EKLENDİ
import '../services/game_service.dart';
import '../models/dictionary_model.dart';
import '../theme/app_theme.dart';
import '../utils/error_message_utils.dart';
import '../widgets/geo_background.dart';
import '../widgets/glass_card.dart';
import 'country_detail_screen.dart';

class DictionaryScreen extends StatefulWidget {
  final String? initialQuery;

  const DictionaryScreen({super.key, this.initialQuery});

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

    final initial = (widget.initialQuery ?? '').trim();
    if (initial.isNotEmpty) {
      _searchController.text = initial;
    }
    _fetchDictionaryData();
  }

  Future<void> _fetchDictionaryData() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final data = await _gameService.getDictionary(token ?? '');
      setState(() {
        _allData = data;
        _availableContinents = _buildContinentOptions(data);
        _filteredData = _applyFiltersTo(data, query: _searchController.text);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = errorMessageFrom(e);
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
      backgroundColor: Colors.transparent,
      builder: (context) {
        final current = _selectedContinent ?? 'Hepsi';
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: GlassCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              blurSigma: 22,
              tint: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.filter_list,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Kıta Filtresi',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'İstersen sadece seçtiğin kıtayı görüntüleyebilirsin.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
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
                              _selectedContinent =
                                  continent == 'Hepsi' ? null : continent;
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
                    const SizedBox(height: 14),
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
                        icon: const Icon(
                          Icons.refresh,
                          color: AppColors.primaryBlue,
                        ),
                        label: const Text('Filtreyi Sıfırla'),
                      ),
                    ),
                  ],
                ],
              ),
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
    final hintText = _selectedContinent == null
        ? 'Ülke, Başkent veya Kıta ara...'
        : 'Ülke / Başkent ara (${_selectedContinent!})';
    final hasQuery = _searchController.text.trim().isNotEmpty;

    Widget scrollable;
    if (_isLoading) {
      scrollable = ListView(
        key: const ValueKey('loading'),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: const [
          SizedBox(height: 46),
          Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue),
          ),
        ],
      );
    } else if (_errorMessage != null) {
      scrollable = ListView(
        key: const ValueKey('error'),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          GlassCard(
            tint: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.wifi_off, color: AppColors.errorRed),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Veriler alınamadı',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Provider.of<SettingsProvider>(
                            context,
                            listen: false,
                          ).triggerButtonVibration();
                          setState(() {
                            _errorMessage = null;
                            _isLoading = true;
                          });
                          _fetchDictionaryData();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tekrar Dene'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    } else if (_filteredData.isEmpty) {
      scrollable = ListView(
        key: const ValueKey('empty'),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: const [
          SizedBox(height: 24),
          GlassCard(
            tint: AppColors.surface,
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              children: [
                Icon(Icons.search_off, color: AppColors.textMuted),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Aradığın kriterde sonuç bulunamadı.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      scrollable = ListView.separated(
        key: const ValueKey('list'),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: _filteredData.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _filteredData[index];
          final countryName = item.countryName ?? 'Bilinmiyor';
          final capitalName = item.capitalName ?? 'Bilinmiyor';
          final continent = item.continent ?? 'Bilinmiyor';

          return GlassCard(
            onTap: () {
              Provider.of<SettingsProvider>(
                context,
                listen: false,
              ).triggerButtonVibration();

              Navigator.push(
                context,
                FadePageRoute(
                  page: CountryDetailScreen(
                    countryName: countryName,
                    capitalName: capitalName,
                    continent: continent,
                  ),
                ),
              );
            },
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            tint: AppColors.surface,
            child: Row(
              children: [
                Text(
                  _getFlagEmoji(countryName),
                  style: const TextStyle(fontSize: 34),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        countryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$capitalName • $continent',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GeoBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                children: [
                  GlassCard(
                    onTap: () => Navigator.of(context).maybePop(),
                    padding: const EdgeInsets.all(10),
                    tint: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    child: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Öğren & Keşfet',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  GlassCard(
                    onTap: _openContinentFilter,
                    padding: const EdgeInsets.all(10),
                    tint: AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    child: Icon(
                      _selectedContinent == null
                          ? Icons.filter_list_outlined
                          : Icons.filter_list,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                tint: AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.primaryBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: hintText,
                          hintStyle: const TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (hasQuery)
                      IconButton(
                        tooltip: 'Temizle',
                        onPressed: () {
                          Provider.of<SettingsProvider>(
                            context,
                            listen: false,
                          ).triggerButtonVibration();
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_selectedContinent != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    GlassCard(
                      onTap: () {
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
                      },
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      tint: AppColors.surface,
                      borderRadius: BorderRadius.circular(999),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.public,
                            size: 18,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Kıta: ${_selectedContinent!}',
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_filteredData.length} sonuç',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryBlue,
                backgroundColor: AppColors.surface2,
                onRefresh: () async {
                  Provider.of<SettingsProvider>(
                    context,
                    listen: false,
                  ).triggerButtonVibration();
                  setState(() {
                    _errorMessage = null;
                    _isLoading = true;
                  });
                  await _fetchDictionaryData();
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: scrollable,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
