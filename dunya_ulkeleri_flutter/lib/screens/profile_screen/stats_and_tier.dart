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
      name: 'Turist',
      minScore: 0,
      rangeLabel: '0 - 99.999',
      color: Colors.green,
      icon: Icons.flight_takeoff,
    ),
    _TierInfo(
      name: 'Gezgin',
      minScore: 100000,
      rangeLabel: '100.000 - 249.999',
      color: Colors.blue,
      icon: Icons.explore,
    ),
    _TierInfo(
      name: 'Yol Kaşifi',
      minScore: 250000,
      rangeLabel: '250.000 - 499.999',
      color: Colors.yellow,
      icon: Icons.explore,
    ),
    _TierInfo(
      name: 'Dünya Yolcusu',
      minScore: 500000,
      rangeLabel: '500.000 - 999.999',
      color: Colors.brown,
      icon: Icons.public,
    ),
    _TierInfo(
      name: 'Kıta Fatihi',
      minScore: 1000000,
      rangeLabel: '1.000.000 - 4.999.999',
      color: Colors.cyanAccent,
      icon: Icons.emoji_events,
    ),
    _TierInfo(
      name: 'Harita Ustası',
      minScore: 5000000,
      rangeLabel: '5.000.000 - 9.999.999',
      color: Colors.teal,
      icon: Icons.map,
    ),
    _TierInfo(
      name: 'Küresel Zihin',
      minScore: 10000000,
      rangeLabel: '10.000.000 - 19.999.999',
      color: Color.fromARGB(255, 1, 90, 90),
      icon: Icons.psychology,
    ),
    _TierInfo(
      name: 'Evrensel Bilge',
      minScore: 20000000,
      rangeLabel: '20.000.000+',
      color: Colors.amber,
      icon: Icons.school,
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
