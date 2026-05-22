part of '../profile_screen.dart';

class _AvatarOptionsSheet extends StatelessWidget {
  final VoidCallback onPickFromGallery;
  final VoidCallback onReadyAvatars;

  const _AvatarOptionsSheet({
    required this.onPickFromGallery,
    required this.onReadyAvatars,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.32,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Profil Fotoğrafı',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
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
            const SizedBox(height: 6),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onPickFromGallery();
              },
              icon: const Icon(Icons.photo_library),
              label: const Text('Galeriden Seç'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onReadyAvatars();
              },
              icon: const Icon(Icons.grid_view_rounded),
              label: const Text('Hazır Avatarlar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textDark,
                side: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.9)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierInfoSheet extends StatelessWidget {
  final _TierInfo currentTier;

  const _TierInfoSheet({required this.currentTier});

  @override
  Widget build(BuildContext context) {
    final tiers = _TierInfo.tiers;
    final height = MediaQuery.of(context).size.height * 0.72;
    return SizedBox(
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
                color: AppColors.borderLight.withValues(alpha: 0.8),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Rütbe Sistemi',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
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
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                physics: const BouncingScrollPhysics(),
                itemCount: tiers.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final tier = tiers[index];
                  final selected = tier.name == currentTier.name;
                  final border = selected
                      ? tier.color.withValues(alpha: 0.55)
                      : AppColors.borderLight;
                  return GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    tint: AppColors.surface2,
                    borderRadius: BorderRadius.circular(18),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: border),
                            color: tier.color.withValues(alpha: 0.14),
                          ),
                          child: Icon(tier.icon, color: tier.color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tier.name,
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tier.rangeLabel,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.successGreen,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarSelectionSheet extends StatelessWidget {
  final Future<void> Function(int avatarId) onAvatarSelected;

  const _AvatarSelectionSheet({required this.onAvatarSelected});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.72;
    return SizedBox(
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
                color: AppColors.borderLight.withValues(alpha: 0.8),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Profil Fotoğrafı Seç',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
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
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: 15,
                itemBuilder: (context, index) {
                  final currentId = index + 1;
                  return GestureDetector(
                    onTap: () {
                      Provider.of<SettingsProvider>(context, listen: false)
                          .triggerButtonVibration();
                      Navigator.of(context).pop();
                      onAvatarSelected(currentId);
                    },
                    child: Center(
                      child: AppAvatar(avatarId: currentId, size: 56),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

