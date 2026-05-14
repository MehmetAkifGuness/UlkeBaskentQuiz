import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_maps/maps.dart';
import 'dart:convert';
import '../theme/app_theme.dart'; // 👈 Açık temamızı dahil ettik

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
  _CountryDetailScreenState createState() => _CountryDetailScreenState();
}

class _CountryDetailScreenState extends State<CountryDetailScreen> {
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
    const Map<String, String> isoMap = {
      "Afganistan": "AF",
      "Almanya": "DE",
      "Amerika Birleşik Devletleri": "US",
      "Andorra": "AD",
      "Angola": "AO",
      "Antigua ve Barbuda": "AG",
      "Arjantin": "AR",
      "Arnavutluk": "AL",
      "Avustralya": "AU",
      "Avusturya": "AT",
      "Azerbaycan": "AZ",
      "Bahamalar": "BS",
      "Bahreyn": "BH",
      "Bangladeş": "BD",
      "Barbados": "BB",
      "Belçika": "BE",
      "Belize": "BZ",
      "Benin": "BJ",
      "Belarus (Beyaz Rusya)": "BY",
      "Bhutan": "BT",
      "Birleşik Arap Emirlikleri": "AE",
      "Birleşik Krallık": "GB",
      "Bolivya": "BO",
      "Bosna-Hersek": "BA",
      "Botsvana": "BW",
      "Brezilya": "BR",
      "Brunei": "BN",
      "Bulgaristan": "BG",
      "Burkina Faso": "BF",
      "Burundi": "BI",
      "Cezayir": "DZ",
      "Cibuti": "DJ",
      "Çad": "TD",
      "Çekya": "CZ",
      "Çin": "CN",
      "Danimarka": "DK",
      "Doğu Timor": "TL",
      "Dominik Cumhuriyeti": "DO",
      "Dominika": "DM",
      "Ekvador": "EC",
      "Ekvator Ginesi": "GQ",
      "El Salvador": "SV",
      "Endonezya": "ID",
      "Eritre": "ER",
      "Ermenistan": "AM",
      "Estonya": "EE",
      "Esvatini": "SZ",
      "Etiyopya": "ET",
      "Fas": "MA",
      "Fiji": "FJ",
      "Fildişi Sahili": "CI",
      "Filipinler": "PH",
      "Filistin": "PS",
      "Finlandiya": "FI",
      "Fransa": "FR",
      "Gabon": "GA",
      "Gambiya": "GM",
      "Gana": "GH",
      "Gine": "GN",
      "Gine-Bissau": "GW",
      "Grenada": "GD",
      "Guatemala": "GT",
      "Guyana": "GY",
      "Güney Afrika": "ZA",
      "Güney Kore": "KR",
      "Güney Sudan": "SS",
      "Gürcistan": "GE",
      "Haiti": "HT",
      "Hırvatistan": "HR",
      "Hindistan": "IN",
      "Hollanda": "NL",
      "Honduras": "HN",
      "Irak": "IQ",
      "İran": "IR",
      "İrlanda": "IE",
      "İspanya": "ES",
      "İsrail": "IL",
      "İsveç": "SE",
      "İsviçre": "CH",
      "İtalya": "IT",
      "İzlanda": "IS",
      "Jamaika": "JM",
      "Japonya": "JP",
      "Kamboçya": "KH",
      "Kamerun": "CM",
      "Kanada": "CA",
      "Karadağ": "ME",
      "Katar": "QA",
      "Kazakistan": "KZ",
      "Kenya": "KE",
      "Kıbrıs Cumhuriyeti": "CY",
      "Kırgızistan": "KG",
      "Kiribati": "KI",
      "Kolombiya": "CO",
      "Komorlar": "KM",
      "Kongo Cumhuriyeti": "CG",
      "Kongo Demokratik Cumhuriyeti": "CD",
      "Kosta Rika": "CR",
      "Kuveyt": "KW",
      "Kuzey Kore": "KP",
      "Kuzey Makedonya": "MK",
      "Küba": "CU",
      "Laos": "LA",
      "Lesotho": "LS",
      "Letonya": "LV",
      "Liberya": "LR",
      "Libya": "LY",
      "Liechtenstein": "LI",
      "Litvanya": "LT",
      "Lübnan": "LB",
      "Lüksemburg": "LU",
      "Macaristan": "HU",
      "Madagaskar": "MG",
      "Malavi": "MW",
      "Maldivler": "MV",
      "Malezya": "MY",
      "Mali": "ML",
      "Malta": "MT",
      "Marshall Adaları": "MH",
      "Mauritius": "MU",
      "Meksika": "MX",
      "Mısır": "EG",
      "Mikronezya": "FM",
      "Moğolistan": "MN",
      "Moldova": "MD",
      "Monako": "MC",
      "Moritanya": "MR",
      "Mozambik": "MZ",
      "Myanmar": "MM",
      "Namibya": "NA",
      "Nauru": "NR",
      "Nepal": "NP",
      "Nikaragua": "NI",
      "Nijer": "NE",
      "Nijerya": "NG",
      "Norveç": "NO",
      "Orta Afrika Cumhuriyeti": "CF",
      "Özbekistan": "UZ",
      "Pakistan": "PK",
      "Palau": "PW",
      "Panama": "PA",
      "Papua Yeni Gine": "PG",
      "Paraguay": "PY",
      "Peru": "PE",
      "Polonya": "PL",
      "Portekiz": "PT",
      "Romanya": "RO",
      "Ruanda": "RW",
      "Rusya": "RU",
      "Saint Kitts ve Nevis": "KN",
      "Saint Lucia": "LC",
      "Saint Vincent ve Grenadinler": "VC",
      "Samoa": "WS",
      "San Marino": "SM",
      "Sao Tome ve Principe": "ST",
      "Senegal": "SN",
      "Seyşeller": "SC",
      "Sırbistan": "RS",
      "Sierra Leone": "SL",
      "Singapur": "SG",
      "Slovakya": "SK",
      "Slovenya": "SI",
      "Solomon Adaları": "SB",
      "Somali": "SO",
      "Sri Lanka": "LK",
      "Sudan": "SD",
      "Surinam": "SR",
      "Suriye": "SY",
      "Suudi Arabistan": "SA",
      "Şili": "CL",
      "Tacikistan": "TJ",
      "Tanzanya": "TZ",
      "Tayland": "TH",
      "Togo": "TG",
      "Tonga": "TO",
      "Trinidad ve Tobago": "TT",
      "Tunus": "TN",
      "Tuvalu": "TV",
      "Türkiye": "TR",
      "Türkmenistan": "TM",
      "Uganda": "UG",
      "Ukrayna": "UA",
      "Umman": "OM",
      "Uruguay": "UY",
      "Ürdün": "JO",
      "Vanuatu": "VU",
      "Vatikan": "VA",
      "Venezuela": "VE",
      "Vietnam": "VN",
      "Yemen": "YE",
      "Yeni Zelanda": "NZ",
      "Yeşil Burun Adaları": "CV",
      "Yunanistan": "GR",
      "Zambiya": "ZM",
      "Zimbabve": "ZW",
    };
    return isoMap[country.trim()];
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
        final data = jsonDecode(response.body);
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
        print(
          "API Hatası (Kod ${response.statusCode}): ${widget.countryName} bulunamadı.",
        );
        hasError = true;
      }
    } catch (e) {
      // 🚨 3 saniyede cevap gelmezse buraya düşer ve sayfayı anında açar
      print("Bağlantı Hatası veya API Yavaş: $e");
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
      if (!mounted) return;
      setState(() => wikiLoading = false);
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        title: Text(
          widget.countryName,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Paylaş',
            onPressed: _copyShareText,
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildFlagCard(),
                const SizedBox(height: 14),
                _buildDetailCard(
                  Icons.location_city,
                  "BAŞKENT",
                  widget.capitalName,
                  AppColors.primaryBlueHover,
                ),
                _buildDetailCard(
                  Icons.public,
                  "BULUNDUĞU KITA",
                  widget.continent,
                  AppColors.successGreen,
                ),
                _buildDetailCard(
                  Icons.groups,
                  "GÜNCEL NÜFUS",
                  hasError ? "Veri çekilemedi" : population,
                  AppColors.brown,
                ),
                _buildDetailCard(
                  Icons.payments,
                  "PARA BİRİMİ",
                  hasError ? "Veri çekilemedi" : currency,
                  AppColors.yellow,
                ),
                const SizedBox(height: 10),
                _SectionCard(
                  title: 'Özet',
                  child: Text(
                    summary,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Tarihçe',
                  child: Text(
                    history,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Konum',
                  child: _buildLocationCard(),
                ),
              ],
            ),
    );
  }

  Widget _buildFlagCard() {
    final borderRadius = BorderRadius.circular(18);

    Widget content;
    if (flagUrl.isNotEmpty) {
      content = Image.network(
        flagUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: AppColors.textMuted, size: 40),
                SizedBox(height: 8),
                Text(
                  "Bayrak yüklenemedi",
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue),
          );
        },
      );
    } else {
      content = const Center(
        child: Icon(Icons.flag_rounded, size: 72, color: AppColors.textMuted),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.borderLight),
        color: AppColors.surface2.withOpacity(0.40),
      ),
      child: ClipRRect(borderRadius: borderRadius, child: content),
    );
  }

  Widget _buildLocationCard() {
    final latLng = countryLatLng;
    final label = '${widget.countryName}, ${widget.continent}'.trim();

    if (latLng == null) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderLight),
          color: AppColors.surface2.withOpacity(0.35),
        ),
        child: const Text(
          'Konum bilgisi bulunamadı.',
          style: TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final source = MapShapeSource.asset(
      'assets/maps/world_map_simplified.json',
      shapeDataField: 'name',
    );

    final zoomPanBehavior = MapZoomPanBehavior(
      focalLatLng: latLng,
      zoomLevel: 3,
      minZoomLevel: 1,
      maxZoomLevel: 10,
      enableDoubleTapZooming: false,
      enableMouseWheelZooming: false,
      showToolbar: false,
      enablePinching: false,
      enablePanning: false,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 240,
        child: Stack(
          children: [
            Positioned.fill(
              child: SfMaps(
                layers: [
                  MapShapeLayer(
                    source: source,
                    zoomPanBehavior: zoomPanBehavior,
                    strokeColor: AppColors.borderLight,
                    strokeWidth: 0.5,
                    color: AppColors.surface2.withOpacity(0.25),
                    initialMarkersCount: 1,
                    markerBuilder: (context, index) {
                      return MapMarker(
                        latitude: latLng.latitude,
                        longitude: latLng.longitude,
                        alignment: Alignment.bottomCenter,
                        offset: const Offset(0, -4),
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.primaryBlue,
                          size: 26,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: AppColors.surface.withOpacity(0.85),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Şık bilgi kartları oluşturan yardımcı widget (Açık temaya uyarlandı)
  Widget _buildDetailCard(
    IconData icon,
    String title,
    String value,
    Color iconColor,
  ) {
    final borderRadius = BorderRadius.circular(18);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: iconColor.withOpacity(0.15),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.9,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLight),
        color: AppColors.surface2.withOpacity(0.60),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
