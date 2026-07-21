part of '../profile_screen.dart';

class _StatsGrid extends StatelessWidget {
  final List<_StatItem> items;

  const _StatsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _StatCard(item: items[index]),
    );
  }
}

class _StatItem {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItem item;

  const _StatCard({required this.item});

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
            item.title.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          Icon(item.icon, color: item.iconColor, size: 26),
          const Spacer(),
          Text(
            item.value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _TierInfo {
  final String name;
  final int minScore;
  final String rangeLabel;
  final Color color;
  final IconData icon;

  const _TierInfo({
    required this.name,
    required this.minScore,
    required this.rangeLabel,
    required this.color,
    required this.icon,
  });

  static const tiers = <_TierInfo>[
    _TierInfo(
      name: 'Çırak',
      minScore: 0,
      rangeLabel: '0 - 99.999',
      color: Color(0xFF94A3B8),
      icon: Icons.flight_takeoff,
    ),
    _TierInfo(
      name: 'Gezgin',
      minScore: 100000,
      rangeLabel: '100.000 - 249.999',
      color: Colors.green,
      icon: Icons.explore,
    ),
    _TierInfo(
      name: 'Kaşif',
      minScore: 250000,
      rangeLabel: '250.000 - 499.999',
      color: Colors.teal,
      icon: Icons.travel_explore,
    ),
    _TierInfo(
      name: 'Seyyah',
      minScore: 500000,
      rangeLabel: '500.000 - 999.999',
      color: AppColors.primaryBlue,
      icon: Icons.public,
    ),
    _TierInfo(
      name: 'Kıta Ustası',
      minScore: 1000000,
      rangeLabel: '1.000.000 - 4.999.999',
      color: Color(0xFF3B82F6),
      icon: Icons.map,
    ),
    _TierInfo(
      name: 'Dünya Rehberi',
      minScore: 5000000,
      rangeLabel: '5.000.000 - 9.999.999',
      color: Color(0xFF6366F1),
      icon: Icons.emoji_events,
    ),
    _TierInfo(
      name: 'Küresel Usta',
      minScore: 10000000,
      rangeLabel: '10.000.000 - 19.999.999',
      color: Color(0xFF8B5CF6),
      icon: Icons.military_tech,
    ),
    _TierInfo(
      name: 'Efsane Kaşif',
      minScore: 20000000,
      rangeLabel: '20.000.000 - 49.999.999',
      color: Color(0xFFA855F7),
      icon: Icons.workspace_premium,
    ),
    _TierInfo(
      name: 'Dünya Fatihi',
      minScore: 50000000,
      rangeLabel: '50.000.000 - 99.999.999',
      color: Color(0xFFEC4899),
      icon: Icons.star,
    ),
    _TierInfo(
      name: 'Gezegen Fatihi',
      minScore: 100000000,
      rangeLabel: '100.000.000 - 199.999.999',
      color: Color(0xFFF43F5E),
      icon: Icons.auto_awesome,
    ),
    _TierInfo(
      name: 'Yıldız Kaşifi',
      minScore: 200000000,
      rangeLabel: '200.000.000 - 499.999.999',
      color: Color(0xFFF97316),
      icon: Icons.rocket_launch,
    ),
    _TierInfo(
      name: 'Galaksi Ustası',
      minScore: 500000000,
      rangeLabel: '500.000.000 - 999.999.999',
      color: AppColors.brown,
      icon: Icons.language,
    ),
    _TierInfo(
      name: 'Kozmik Zihin',
      minScore: 1000000000,
      rangeLabel: '1.000.000.000 - 4.999.999.999',
      color: AppColors.yellow,
      icon: Icons.psychology,
    ),
    _TierInfo(
      name: 'Evrensel Usta',
      minScore: 5000000000,
      rangeLabel: '5.000.000.000 - 19.999.999.999',
      color: Color(0xFFEAB308),
      icon: Icons.school,
    ),
    _TierInfo(
      name: 'Sonsuz Usta',
      minScore: 20000000000,
      rangeLabel: '20.000.000.000 - 99.999.999.999',
      color: Color(0xFF93C5FD),
      icon: Icons.shield_rounded,
    ),
    _TierInfo(
      name: 'Mutlak Hükümdar',
      minScore: 100000000000,
      rangeLabel: '100.000.000.000+',
      color: Color(0xFFF8FAFC),
      icon: Icons.emoji_events_rounded,
    ),
  ];

  static _TierInfo fromScore(int totalScore) {
    var selected = tiers.first;
    for (final tier in tiers) {
      if (totalScore >= tier.minScore) selected = tier;
    }
    return selected;
  }
}
