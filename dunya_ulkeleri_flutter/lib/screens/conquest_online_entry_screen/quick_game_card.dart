part of '../conquest_online_entry_screen.dart';

class _QuickGameCard extends StatelessWidget {
  final bool isBusy;
  final VoidCallback onPressed;

  const _QuickGameCard({
    required this.isBusy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hızlı Oyun',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sırada bekleyen oyuncularla otomatik 1’e 1 eşleş. Rakip bulununca maç başlar.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isBusy ? null : onPressed,
              icon: const Icon(Icons.flash_on_rounded),
              label: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Hızlı Oyun Bul'),
            ),
          ),
        ],
      ),
    );
  }
}

