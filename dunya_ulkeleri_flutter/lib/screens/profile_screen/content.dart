part of '../profile_screen.dart';

class _ProfileContentList extends StatelessWidget {
  final UserProfileModel profile;
  final Map<String, int> scores;
  final int totalScore;
  final _TierInfo tier;
  final double progress;
  final String analysisText;
  final String creationDateText;
  final VoidCallback onBack;
  final VoidCallback onSettings;
  final VoidCallback onAvatarTap;
  final VoidCallback onEditDisplayName;
  final VoidCallback onShowTierInfo;
  final VoidCallback onDictionary;
  final VoidCallback onMistakes;
  final VoidCallback onLogout;

  const _ProfileContentList({
    required this.profile,
    required this.scores,
    required this.totalScore,
    required this.tier,
    required this.progress,
    required this.analysisText,
    required this.creationDateText,
    required this.onBack,
    required this.onSettings,
    required this.onAvatarTap,
    required this.onEditDisplayName,
    required this.onShowTierInfo,
    required this.onDictionary,
    required this.onMistakes,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        _TopRow(onBack: onBack, onSettings: onSettings),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: onAvatarTap,
            child: _AvatarRing(
              avatarId: profile.avatarId,
              avatarBytes: profile.customAvatarBytes,
              ringColor: tier.color,
              progress: progress,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                profile.displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: onEditDisplayName,
                icon: const Icon(Icons.edit, size: 18),
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
        Text(
          '@${profile.username}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        _TierPill(
          title: '${tier.name.toUpperCase()} SEVİYESİ',
          color: tier.color,
          icon: tier.icon,
          onInfo: onShowTierInfo,
        ),
        const SizedBox(height: 14),
        _AnalysisCard(
          text: analysisText,
          onDictionary: onDictionary,
          onMistakes: onMistakes,
        ),
        const SizedBox(height: 18),
        _SectionHeader(
          title: 'Ustalık Seviyeleri',
          trailing: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.bar_chart),
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        _MasteryGrid(items: _buildMasteryCards(scores)),
        const SizedBox(height: 18),
        const _SectionHeader(title: 'Genel İstatistikler'),
        const SizedBox(height: 10),
        _StatsGrid(
          items: [
            _StatItem(
              title: 'Kayıt Tarihi',
              value: creationDateText,
              icon: Icons.calendar_month,
              iconColor: AppColors.successGreen,
            ),
            _StatItem(
              title: 'Lig',
              value: (profile.league.isEmpty ? '-' : profile.league),
              icon: Icons.shield_rounded,
              iconColor: AppColors.primaryBlue,
            ),
            _StatItem(
              title: 'En Yüksek Skor',
              value: _formatNumber(profile.maxWinStreak),
              icon: Icons.emoji_events,
              iconColor: AppColors.brown,
            ),
            _StatItem(
              title: 'Kupa',
              value: _formatNumber(profile.trophies),
              icon: Icons.emoji_events_rounded,
              iconColor: AppColors.yellow,
            ),
            _StatItem(
              title: 'Oynanan Oyun',
              value: _formatNumber(profile.totalGamesPlayed),
              icon: Icons.extension_rounded,
              iconColor: AppColors.errorRed,
            ),
            _StatItem(
              title: 'Toplam Ustalık',
              value: _formatCompact(totalScore),
              icon: Icons.military_tech,
              iconColor: AppColors.successGreen,
            ),
          ],
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: onLogout,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.errorRed,
            side: BorderSide(color: AppColors.errorRed.withValues(alpha: 0.6)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          icon: const Icon(Icons.logout),
          label: const Text(
            'Çıkış Yap',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _ProfileData {
  final UserProfileModel profile;
  final Map<String, int> scores;

  const _ProfileData({required this.profile, required this.scores});
}

class _TopRow extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSettings;

  const _TopRow({this.onBack, this.onSettings});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          _IconGlassButton(icon: Icons.arrow_back, onTap: onBack),
          const Spacer(),
          _IconGlassButton(icon: Icons.settings, onTap: onSettings),
        ],
      ),
    );
  }
}

class _IconGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _IconGlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      tint: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: Icon(icon, color: AppColors.textDark),
    );
  }
}

class _AvatarRing extends StatelessWidget {
  final int avatarId;
  final Uint8List? avatarBytes;
  final Color ringColor;
  final double progress;

  const _AvatarRing({
    required this.avatarId,
    this.avatarBytes,
    required this.ringColor,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final ringSize = 132.0;
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: ringSize,
          height: ringSize,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            backgroundColor: AppColors.borderLight.withValues(alpha: 0.6),
            valueColor: AlwaysStoppedAnimation(ringColor),
          ),
        ),
        AppAvatar(avatarId: avatarId, size: 112, imageBytes: avatarBytes),
        Positioned(
          right: 10,
          bottom: 10,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Icon(
              Icons.edit,
              size: 18,
              color: AppColors.successGreen,
            ),
          ),
        ),
      ],
    );
  }
}

