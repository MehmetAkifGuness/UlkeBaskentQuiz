part of '../dictionary_screen.dart';

extension _DictionaryScreenStateView on DictionaryScreenState {

  Widget _buildView(BuildContext context) {
    final hintText = _selectedContinent == null
        ? 'Ülke, Başkent veya Kıta ara...'
        : 'Ülke / Başkent ara (${_selectedContinent!})';
    final hasQuery = _searchController.text.trim().isNotEmpty;
    final scrollable = _buildDictionaryScrollable(context);

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
                        _clearSelectedContinent();
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
                onRefresh: _handlePullToRefresh,
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


