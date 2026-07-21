import 'package:flag/flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

import '../services/country_detail_service.dart';
import '../theme/app_theme.dart';

part 'country_detail_screen/section_card.dart';
part 'country_detail_screen/view.dart';
part 'country_detail_screen/flag_card_impl.dart';
part 'country_detail_screen/location_card_impl.dart';
part 'country_detail_screen/detail_card_impl.dart';

class CountryDetailScreen extends StatefulWidget {
  final String countryName;
  final String capitalName;
  final String continent;

  const CountryDetailScreen({
    super.key,
    required this.countryName,
    required this.capitalName,
    required this.continent,
  });

  @override
  CountryDetailScreenState createState() => CountryDetailScreenState();
}

class CountryDetailScreenState extends State<CountryDetailScreen> {
  bool isLoading = true;
  String flagAlpha2 = '';
  String flagEmoji = '';
  String resolvedCapitalName = '';
  String resolvedContinent = '';
  MapLatLng? countryLatLng;

  final CountryDetailService _countryDetailService = CountryDetailService();

  String get displayedCapitalName => resolvedCapitalName.trim().isNotEmpty
      ? resolvedCapitalName
      : widget.capitalName;

  String get displayedContinent => resolvedContinent.trim().isNotEmpty
      ? resolvedContinent
      : widget.continent;

  @override
  void initState() {
    super.initState();
    _fetchLiveCountryData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _copyShareText() async {
    final text =
        '${widget.countryName} - Başkent: $displayedCapitalName, Kıta: $displayedContinent';

    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Kopyalandı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _fetchLiveCountryData() async {
    try {
      final data = await _countryDetailService.load(
        countryName: widget.countryName,
        alpha2: null,
        fallbackCapital: widget.capitalName,
        fallbackContinent: widget.continent,
      );

      if (!mounted) return;
      setState(() {
        flagAlpha2 = data.alpha2;
        flagEmoji = data.flagEmoji;
        resolvedCapitalName = data.capitalName;
        resolvedContinent = data.continent;
        countryLatLng = data.countryLatLng;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Country detail asset load failed: $e');
      if (!mounted) return;
      setState(() {
        flagAlpha2 = '';
        flagEmoji = '';
        resolvedCapitalName = widget.capitalName;
        resolvedContinent = widget.continent;
        countryLatLng = null;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => _buildView(context);

  Widget _buildFlagCard() => _buildFlagCardImpl();

  Widget _buildLocationCard() => _buildLocationCardImpl();

  Widget _buildDetailCard(
    IconData icon,
    String title,
    String value,
    Color iconColor,
  ) {
    return _buildDetailCardImpl(icon, title, value, iconColor);
  }
}
