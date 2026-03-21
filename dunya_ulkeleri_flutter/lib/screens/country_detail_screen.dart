import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart'; // 👈 Açık temamızı dahil ettik

class CountryDetailScreen extends StatefulWidget {
  final String countryName;
  final String capitalName;
  final String continent;

  const CountryDetailScreen({
    Key? key,
    required this.countryName,
    required this.capitalName,
    required this.continent,
  }) : super(key: key);

  @override
  _CountryDetailScreenState createState() => _CountryDetailScreenState();
}

class _CountryDetailScreenState extends State<CountryDetailScreen> {
  bool isLoading = true;
  String population = "Aranıyor...";
  String currency = "Aranıyor...";
  String flagUrl = "";
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchLiveCountryData();
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
  // İnternetten anlık ülke verisi çeken sihirli fonksiyon
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

      final response = await http.get(url);

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

          // 🚨 DEĞİŞİM BURADA: Bayrağı API'nin bozuk linkinden değil, sağlam FlagCDN'den çekiyoruz!
          if (isoCode != null) {
            // ISO kodunu küçük harfe çevirip flagcdn linkini oluşturuyoruz (Örn: AF -> af)
            flagUrl = 'https://flagcdn.com/w320/${isoCode.toLowerCase()}.png';
          } else if (countryData['flags'] != null) {
            // Eğer ülkemizin ISO kodu sözlükte yoksa, API'nin verdiği linki denemeye devam et
            flagUrl = countryData['flags']['png'] ?? "";
          }
        }
      } else {
        print(
          "API Hatası (Kod ${response.statusCode}): ${widget.countryName} bulunamadı.",
        );
        hasError = true;
      }
    } catch (e) {
      print("Bağlantı Hatası: $e");
      hasError = true;
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // 👈 Açık arka plan
      appBar: AppBar(
        title: Text(
          widget.countryName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryBlue, // 👈 Mavi AppBar
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // BAYRAK BÖLÜMÜ
                  if (flagUrl.isNotEmpty)
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              0.1,
                            ), // 👈 Hafif modern gölge
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      // 🚨 YENİ: Bayrak yüklenemezse çökmeyi engelleyen Error Builder
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          flagUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.borderLight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.broken_image,
                                    color: AppColors.textDark,
                                    size: 40,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Bayrak Yüklenemedi",
                                    style: TextStyle(color: AppColors.textDark),
                                  ),
                                ],
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: AppColors.borderLight,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.flag,
                        size: 80,
                        color: AppColors.textDark,
                      ),
                    ),

                  const SizedBox(height: 30),

                  // BİLGİ KARTLARI (Açık Tema Renkleri Uyarlanmış Hali)
                  _buildDetailCard(
                    Icons.location_city,
                    "Başkent",
                    widget.capitalName,
                    AppColors.primaryBlueHover,
                  ),
                  _buildDetailCard(
                    Icons.public,
                    "Bulunduğu Kıta",
                    widget.continent,
                    AppColors.successGreen,
                  ),

                  // CANLI ÇEKİLEN VERİLER
                  _buildDetailCard(
                    Icons.groups,
                    "Güncel Nüfus",
                    hasError ? "Veri Çekilemedi" : population,
                    AppColors.brown,
                  ),
                  _buildDetailCard(
                    Icons.payments,
                    "Para Birimi",
                    hasError ? "Veri Çekilemedi" : currency,
                    AppColors.yellow,
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
    return Card(
      color: AppColors.white, // 👈 Kartlar artık beyaz
      elevation: 0, // Gölgeyi kutu kenarlığı (border) ile değiştirdik
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: AppColors.borderLight,
          width: 1.5,
        ), // 👈 Hafif gri çerçeve
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.15),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.textDark.withOpacity(
              0.6,
            ), // 👈 Üst başlık daha silik
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            color: AppColors.textDark, // 👈 Ana değer koyu lacivert/siyah
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
