part of '../conquest_online_game_screen.dart';

class _ScoreChip extends StatelessWidget {
  final ConquestPlayerState player;

  const _ScoreChip({required this.player});

  @override
  Widget build(BuildContext context) {
    final String name = (player.username ?? 'Oyuncu').toString();
    final int conquered = player.conqueredCount;
    final int lives = player.remainingLives;
    final String colorHex = (player.colorHex ?? '').toString();

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: hexToColor(colorHex),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$conquered',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          for (int i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Icon(
                i < lives ? Icons.favorite : Icons.favorite_border,
                size: 14,
                color: AppColors.errorRed.withValues(
                  alpha: i < lives ? 0.95 : 0.32,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OnlineMapLoadResult {
  final Uint8List bytes;
  final String shapeDataField;
  final List<MapCountryModel> mapCountries;

  const _OnlineMapLoadResult({
    required this.bytes,
    required this.shapeDataField,
    required this.mapCountries,
  });
}

class _MapErrorCard extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _MapErrorCard({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ),
        ],
      ),
    );
  }
}

