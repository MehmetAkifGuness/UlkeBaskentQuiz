part of '../home_screen.dart';
class _FreeModeButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _FreeModeButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onPressed,
      padding: const EdgeInsets.all(16),
      tint: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlue.withValues(alpha: 0.16),
                  AppColors.surface2.withValues(alpha: 0.35),
                ],
              ),
            ),
            child: const Icon(
              Icons.public_rounded,
              color: AppColors.primaryBlue,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Serbest Mod',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Kendi hızında ilerle, istediğin kategoride pratik yap!',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _FreeModeSheet extends StatefulWidget {
  final List<_GeoCategory> categories;
  final void Function(String mode, String category) onStart;
  final VoidCallback onHaptic;

  const _FreeModeSheet({
    required this.categories,
    required this.onStart,
    required this.onHaptic,
  });

  @override
  State<_FreeModeSheet> createState() => _FreeModeSheetState();
}

class _FreeModeSheetState extends State<_FreeModeSheet> {
  String _selectedMode = 'COUNTRY_TO_CAPITAL';
  _GeoCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    if (widget.categories.isNotEmpty) {
      _selectedCategory = widget.categories.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final height = size.height * 0.88;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SizedBox(
        height: height,
        child: GlassCard(
          padding: EdgeInsets.zero,
          blurSigma: 22,
          tint: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: AppColors.borderLight.withValues(alpha: 0.7),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Oyun Modunu Seç',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ModeChip(
                      label: 'Ülke -> Başkent',
                      selected: _selectedMode == 'COUNTRY_TO_CAPITAL',
                      onTap: () {
                        widget.onHaptic();
                        setState(() => _selectedMode = 'COUNTRY_TO_CAPITAL');
                      },
                    ),
                    _ModeChip(
                      label: 'Başkent -> Ülke',
                      selected: _selectedMode == 'CAPITAL_TO_COUNTRY',
                      onTap: () {
                        widget.onHaptic();
                        setState(() => _selectedMode = 'CAPITAL_TO_COUNTRY');
                      },
                    ),
                    _ModeChip(
                      label: 'Karışık',
                      selected: _selectedMode == 'MIXED',
                      accent: const Color(0xFFF97316),
                      onTap: () {
                        widget.onHaptic();
                        setState(() => _selectedMode = 'MIXED');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Nerede oynamak istersin?',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final category = widget.categories[index];
                    final selected = category.title == _selectedCategory?.title;
                    return _CategoryTile(
                      title: category.title,
                      icon: category.icon,
                      selected: selected,
                      onTap: () {
                        widget.onHaptic();
                        setState(() => _selectedCategory = category);
                      },
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemCount: widget.categories.length,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedCategory == null
                        ? null
                        : () {
                            widget.onHaptic();
                            widget.onStart(
                              _selectedMode,
                              _selectedCategory!.title,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'OYUNU BAŞLAT',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? accent;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final active = accent ?? AppColors.primaryBlue;
    final bg = selected ? active.withValues(alpha: 0.28) : AppColors.surface2;
    final fg = selected ? AppColors.textDark : AppColors.textMuted;
    final border = selected ? active.withValues(alpha: 0.45) : AppColors.borderLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: bg.withValues(alpha: 0.9),
            border: Border.all(color: border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}


