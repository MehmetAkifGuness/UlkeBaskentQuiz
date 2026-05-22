part of '../profile_screen.dart';

class _ContinentInfo {
  final String name;
  final int questions;

  const _ContinentInfo(this.name, this.questions);
}

class _SpecialModeInfo {
  final String title;
  final String scoreKey;
  final int maxScore;

  const _SpecialModeInfo({
    required this.title,
    required this.scoreKey,
    required this.maxScore,
  });
}

class _MasteryGrid extends StatelessWidget {
  final List<Widget> items;

  const _MasteryGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }
}

class _MasteryCard extends StatelessWidget {
  final String title;
  final int score;
  final double percentage;
  final String label;
  final Color labelColor;

  const _MasteryCard({
    required this.title,
    required this.score,
    required this.percentage,
    required this.label,
    required this.labelColor,
  });

  factory _MasteryCard.fromScores({
    required _ContinentInfo continent,
    required Map<String, int> scores,
  }) {
    final c2c = scores['${continent.name}_COUNTRY_TO_CAPITAL'] ?? 0;
    final c2cRev = scores['${continent.name}_CAPITAL_TO_COUNTRY'] ?? 0;
    final mixed = scores['${continent.name}_MIXED'] ?? 0;

    final best = math.max(c2c, math.max(c2cRev, mixed));
    final maxScore = continent.questions * 2000;
    final percentage = maxScore <= 0 ? 0.0 : (best / maxScore).clamp(0.0, 1.0);

    final mastery = _MasteryLabel.fromPercentage(percentage);
    final label = best == 0 ? 'Oynanmadı' : mastery.text;
    final labelColor = best == 0 ? AppColors.textMuted : mastery.color;

    return _MasteryCard(
      title: continent.name,
      score: best,
      percentage: percentage,
      label: label,
      labelColor: labelColor,
    );
  }

  factory _MasteryCard.fromSingleScore({
    required String title,
    required String scoreKey,
    required int maxScore,
    required Map<String, int> scores,
  }) {
    final score = scores[scoreKey] ?? 0;
    final percentage = maxScore <= 0 ? 0.0 : (score / maxScore).clamp(0.0, 1.0);

    final mastery = _MasteryLabel.fromPercentage(percentage);
    final label = score == 0 ? 'Oynanmadı' : mastery.text;
    final labelColor = score == 0 ? AppColors.textMuted : mastery.color;

    return _MasteryCard(
      title: title,
      score: score,
      percentage: percentage,
      label: label,
      labelColor: labelColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      tint: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_formatNumber(score)} Puan',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: labelColor.withValues(alpha: 0.14),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const Spacer(),
          _MasteryRing(
            percentage: percentage,
            color: labelColor,
          ),
        ],
      ),
    );
  }
}

class _MasteryRing extends StatelessWidget {
  final double percentage;
  final Color color;

  const _MasteryRing({required this.percentage, required this.color});

  @override
  Widget build(BuildContext context) {
    final percentText = '${(percentage * 100).round()}%';

    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: CircularProgressIndicator(
              value: percentage,
              strokeWidth: 9,
              backgroundColor: AppColors.borderLight.withValues(alpha: 0.22),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Text(
            percentText,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _MasteryLabel {
  final String text;
  final Color color;

  const _MasteryLabel(this.text, this.color);

  static _MasteryLabel fromPercentage(double percentage) {
    if (percentage == 0) {
      return const _MasteryLabel('Oynanmadı', AppColors.textMuted);
    }
    if (percentage >= 0.8) {
      return const _MasteryLabel('Çok İyi', AppColors.successGreen);
    }
    if (percentage >= 0.6) {
      return const _MasteryLabel('İyi', AppColors.successGreen);
    }
    if (percentage >= 0.4) {
      return const _MasteryLabel('Ortalama', AppColors.brown);
    }
    if (percentage >= 0.2) {
      return const _MasteryLabel('Geliştir', AppColors.yellow);
    }
    return const _MasteryLabel('Kötü', AppColors.errorRed);
  }
}

