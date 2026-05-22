part of '../country_detail_screen.dart';

extension _CountryDetailScreenStateView on CountryDetailScreenState {

  Widget _buildView(BuildContext context) {
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
}

