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


part 'dictionary_screen/flags.dart';
part 'dictionary_screen/view.dart';
part 'dictionary_screen/scrollable.dart';

class DictionaryScreen extends StatefulWidget {
  final String? initialQuery;

  const DictionaryScreen({super.key, this.initialQuery});

  @override
  DictionaryScreenState createState() => DictionaryScreenState();
}

class DictionaryScreenState extends State<DictionaryScreen> {
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
    final cleanCountry = country.trim();
    return _dictionaryFlagMap[cleanCountry] ?? '???';
  }

  void _clearSelectedContinent() {
    Provider.of<SettingsProvider>(context, listen: false).triggerButtonVibration();
    setState(() {
      _selectedContinent = null;
      _filteredData = _applyFiltersTo(_allData, query: _searchController.text);
    });
  }

  void _retryFetchDictionary() {
    Provider.of<SettingsProvider>(context, listen: false).triggerButtonVibration();
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    _fetchDictionaryData();
  }

  Future<void> _handlePullToRefresh() async {
    Provider.of<SettingsProvider>(context, listen: false).triggerButtonVibration();
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    await _fetchDictionaryData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => _buildView(context);

}

