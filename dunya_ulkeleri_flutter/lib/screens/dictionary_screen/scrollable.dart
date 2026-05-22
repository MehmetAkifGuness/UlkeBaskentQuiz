part of '../dictionary_screen.dart';

extension _DictionaryScreenStateScrollable on DictionaryScreenState {
  Widget _buildDictionaryScrollable(BuildContext context) {
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
                          _retryFetchDictionary();
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
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = _filteredData[index];
            final countryName = item.countryName;
            final capitalName = item.capitalName;
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
  
    return scrollable;
  }
}

