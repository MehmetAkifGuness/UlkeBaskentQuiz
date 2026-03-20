import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  // 🚨 %100 KESİN SONUÇ İÇİN ÜLKE PLAKA (ISO) KODLARI SÖZLÜĞÜ
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

  // İnternetten anlık ülke verisi çeken sihirli fonksiyon
  Future<void> _fetchLiveCountryData() async {
    try {
      String? isoCode = _getIsoCode(widget.countryName);
      Uri url;

      // 🚨 EĞER İSO KODUNU BİLİYORSAK (Kİ BİLİYORUZ) KESİN ARAMA YAPARIZ:
      if (isoCode != null) {
        url = Uri.parse('https://restcountries.com/v3.1/alpha/$isoCode');
      } else {
        // Güvenlik ağı: Eğer sözlükte olmayan bir ülke gelirse eski sisteme döner
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

          // 1. Nüfusu çek ve okunaklı formata çevir (Örn: 85000000 -> 85.000.000)
          int pop = countryData['population'] ?? 0;
          population = _formatPopulation(pop);

          // 2. Para Birimini çek
          if (countryData['currencies'] != null) {
            Map<String, dynamic> currencies = countryData['currencies'];
            currency =
                "${currencies.values.first['name']} (${currencies.values.first['symbol']})";
          }

          // 3. Ülke Bayrağını çek (Önce SVG dener, yoksa PNG)
          if (countryData['flags'] != null) {
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

  // Sayıları noktalı yazmak için yardımcı fonksiyon
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
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(widget.countryName),
        centerTitle: true,
        backgroundColor: Colors.black87,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.amber))
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // BAYRAK BÖLÜMÜ
                  if (flagUrl.isNotEmpty)
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                        image: DecorationImage(
                          image: NetworkImage(flagUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.flag,
                        size: 80,
                        color: Colors.grey[600],
                      ),
                    ),

                  SizedBox(height: 30),

                  // BİLGİ KARTLARI
                  _buildDetailCard(
                    Icons.location_city,
                    "Başkent",
                    widget.capitalName,
                    Colors.blueAccent,
                  ),
                  _buildDetailCard(
                    Icons.public,
                    "Bulunduğu Kıta",
                    widget.continent,
                    Colors.green,
                  ),

                  // CANLI ÇEKİLEN VERİLER
                  _buildDetailCard(
                    Icons.groups,
                    "Güncel Nüfus",
                    hasError ? "Veri Çekilemedi" : population,
                    Colors.orange,
                  ),
                  _buildDetailCard(
                    Icons.payments,
                    "Para Birimi",
                    hasError ? "Veri Çekilemedi" : currency,
                    Colors.amber,
                  ),
                ],
              ),
            ),
    );
  }

  // Şık bilgi kartları oluşturan yardımcı widget
  Widget _buildDetailCard(
    IconData icon,
    String title,
    String value,
    Color iconColor,
  ) {
    return Card(
      color: Colors.grey[850],
      margin: EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: EdgeInsets.all(15),
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.2),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
