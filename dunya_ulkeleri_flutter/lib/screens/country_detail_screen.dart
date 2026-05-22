import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_maps/maps.dart';
import 'dart:convert';
import '../theme/app_theme.dart'; // 👈 Açık temamızı dahil ettik


part 'country_detail_screen/section_card.dart';
part 'country_detail_screen/view.dart';
part 'country_detail_screen/iso_code_impl.dart';
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
  String population = "Aranıyor...";
  String currency = "Aranıyor...";
  String flagUrl = "";
  bool hasError = false;

  bool wikiLoading = false;
  String summary = "Aranıyor...";
  String history = "Aranıyor...";
  String? wikiPageUrl;
  MapLatLng? countryLatLng;

  @override
  void initState() {
    super.initState();
    _fetchLiveCountryData();
    _fetchWikiData();
  }

  // 🚨 YENİ EKLENDİ: RAM TEMİZLEYİCİ (MEMORY LEAK ZIRHI)
  @override
  void dispose() {
    // Sayfa kapatıldığında (pop edildiğinde), Flutter'ın resim önbelleğini RAM'den zorla sileriz.
    // Bu sayede üst üste açılan bayrak resimleri telefonu ısıtmaz ve RAM'i şişirmez.
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    super.dispose();
  }

  Future<void> _copyShareText() async {
    final url = (wikiPageUrl ?? '').trim();
    final text = url.isNotEmpty
        ? url
        : '${widget.countryName} - Başkent: ${widget.capitalName}';

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

  // 🚨 %100 KESİN SONUÇ İÇİN ÜLKE PLAKA (ISO) KODLARI SÖZLÜĞÜ (Hiç dokunulmadı)
  String? _getIsoCode(String country) {
    return _getIsoCodeImpl(country);
  }


  // İnternetten anlık ülke verisi çeken sihirli fonksiyon (Hiç dokunulmadı)
  Future<void> _fetchLiveCountryData() async {
    try {
      String? isoCode = _getIsoCode(widget.countryName);
      Uri url;

      if (isoCode != null) {
        url = Uri.parse('https://restcountries.com/v3.1/alpha/$isoCode');
      } else {
        final String encodedCountryName = Uri.encodeComponent(
          widget.countryName,
        );
        url = Uri.parse(
          'https://restcountries.com/v3.1/translation/$encodedCountryName',
        );
      }

      // 🚨 ÇÖZÜM BURADA: Eğer 3 saniye içinde cevap gelmezse patlat, bekleme!
      final response = await http.get(url).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data != null && data.isNotEmpty) {
          final countryData = data[0];

          int pop = countryData['population'] ?? 0;
          population = _formatPopulation(pop);

          if (countryData['currencies'] != null) {
            Map<String, dynamic> currencies = countryData['currencies'];
            currency =
                "${currencies.values.first['name']} (${currencies.values.first['symbol']})";
          }

          // 🚨 Bayrağı sağlam FlagCDN'den çekiyoruz
          if (isoCode != null) {
            flagUrl = 'https://flagcdn.com/w320/${isoCode.toLowerCase()}.png';
          } else if (countryData['flags'] != null) {
            flagUrl = countryData['flags']['png'] ?? "";
          }

          final latLng = countryData['latlng'];
          if (latLng is List && latLng.length >= 2) {
            final lat = latLng[0];
            final lng = latLng[1];
            if (lat is num && lng is num) {
              countryLatLng = MapLatLng(lat.toDouble(), lng.toDouble());
            }
          }
        }
      } else {
        debugPrint(
          "API Hatası (Kod ${response.statusCode}): ${widget.countryName} bulunamadı.",
        );
        hasError = true;
      }
    } catch (e) {
      // 🚨 3 saniyede cevap gelmezse buraya düşer ve sayfayı anında açar
      debugPrint("Bağlantı Hatası veya API Yavaş: $e");
      hasError = true;
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _wikiTitleFrom(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;
    // Örn: "Belarus (Beyaz Rusya)" -> "Belarus"
    return trimmed.replaceAll(RegExp(r'\s*\(.*?\)\s*'), '').trim();
  }

  Future<Map<String, String?>?> _fetchWikiSummary(String title) async {
    if (title.trim().isEmpty) return null;
    final uri = Uri.parse(
      'https://tr.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(title)}',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 3));
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) return null;

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map) return null;

    final extract = decoded['extract']?.toString().trim();
    if (extract == null || extract.isEmpty) return null;

    String? pageUrl;
    final contentUrls = decoded['content_urls'];
    if (contentUrls is Map) {
      final desktop = contentUrls['desktop'];
      if (desktop is Map) {
        pageUrl = desktop['page']?.toString().trim();
      }
    }

    return <String, String?>{
      'extract': extract,
      'url': (pageUrl != null && pageUrl.isNotEmpty) ? pageUrl : null,
    };
  }

  Future<void> _fetchWikiData() async {
    if (wikiLoading) return;

    final title = _wikiTitleFrom(widget.countryName);
    if (title.isEmpty) return;

    if (mounted) {
      setState(() => wikiLoading = true);
    } else {
      wikiLoading = true;
    }

    try {
      final summaryResult = await _fetchWikiSummary(title);
      final historyResult = await _fetchWikiSummary('$title tarihi');

      if (!mounted) return;
      setState(() {
        summary = summaryResult?['extract']?.trim().isNotEmpty == true
            ? summaryResult!['extract']!.trim()
            : 'Özet bilgisi bulunamadı.';

        history = historyResult?['extract']?.trim().isNotEmpty == true
            ? historyResult!['extract']!.trim()
            : 'Tarihçe bilgisi bulunamadı.';

        wikiPageUrl = summaryResult?['url']?.trim().isNotEmpty == true
            ? summaryResult!['url']!.trim()
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        summary = 'Özet bilgisi bulunamadı.';
        history = 'Tarihçe bilgisi bulunamadı.';
        wikiPageUrl = null;
      });
    } finally {
      if (mounted) {
        setState(() => wikiLoading = false);
      } else {
        wikiLoading = false;
      }
    }
  }

  // Sayıları noktalı yazmak için yardımcı fonksiyon (Hiç dokunulmadı)
  String _formatPopulation(int number) {
    if (number == 0) return "Bilinmiyor";
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
  @override
  Widget build(BuildContext context) => _buildView(context);


  Widget _buildFlagCard() {
    return _buildFlagCardImpl();
  }


  Widget _buildLocationCard() {
    return _buildLocationCardImpl();
  }


  // Şık bilgi kartları oluşturan yardımcı widget (Açık temaya uyarlandı)
  Widget _buildDetailCard(
    IconData icon,
    String title,
    String value,
    Color iconColor,
  ) {
    return _buildDetailCardImpl(icon, title, value, iconColor);
  }

}

