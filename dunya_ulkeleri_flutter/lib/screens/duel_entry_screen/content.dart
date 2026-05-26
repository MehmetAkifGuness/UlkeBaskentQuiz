part of '../duel_entry_screen.dart';

class _DuelEntryContent extends StatelessWidget {
  final bool isBusy;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final List<_ModeOption> modes;
  final String selectedMode;
  final ValueChanged<String> onModeChanged;
  final List<_BotDifficultyOption> botDifficulties;
  final String selectedBotDifficulty;
  final ValueChanged<String> onBotDifficultyChanged;
  final TextEditingController roomCodeController;
  final Future<void> Function() onQuickMatch;
  final Future<void> Function() onBotMatch;
  final Future<void> Function() onCreateRoom;
  final Future<void> Function() onJoinRoom;
  final VoidCallback onHaptic;

  const _DuelEntryContent({
    required this.isBusy,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.modes,
    required this.selectedMode,
    required this.onModeChanged,
    required this.botDifficulties,
    required this.selectedBotDifficulty,
    required this.onBotDifficultyChanged,
    required this.roomCodeController,
    required this.onQuickMatch,
    required this.onBotMatch,
    required this.onCreateRoom,
    required this.onJoinRoom,
    required this.onHaptic,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom + 24.0;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 14, 16, bottomPad),
      physics: const BouncingScrollPhysics(),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(16),
          tint: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lig & Kupa Modu',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Rakibini bul, seçtiğin kategorideki ülke sayısı kadar tur oynayın. Her turda ilk doğru cevap veren 1 puan alır. Kazanan kupa kazanır, kaybeden kupa kaybeder.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),
              _DuelPickers(
                categories: categories,
                selectedCategory: selectedCategory,
                onCategoryChanged: onCategoryChanged,
                modes: modes,
                selectedMode: selectedMode,
                onModeChanged: onModeChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          tint: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bot Modu',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Seçtiğin kategorideki ülke sayısı kadar tur oynarsın. Her turda ilk doğru cevap veren kazanır.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in botDifficulties)
                    ChoiceChip(
                      label: Text(d.label),
                      selected: selectedBotDifficulty == d.value,
                      onSelected: isBusy
                          ? null
                          : (selected) {
                              if (!selected) return;
                              onBotDifficultyChanged(d.value);
                            },
                    ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isBusy ? null : onBotMatch,
                  icon: const Icon(Icons.smart_toy_outlined, size: 18),
                  label: const Text(
                    'Bota Karşı Oyna',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          tint: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hızlı Eşleşme',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kupanıza göre aynı ligden rakip bulunur.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isBusy ? null : onQuickMatch,
                  icon: const Icon(Icons.flash_on_rounded, size: 18),
                  label: const Text(
                    'Hızlı Başla',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          tint: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Oda ile Oyna',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: roomCodeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Oda Kodu',
                  prefixIcon: Icon(Icons.meeting_room_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isBusy ? null : onCreateRoom,
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text(
                        'Oda Kur',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isBusy ? null : onJoinRoom,
                      icon: const Icon(Icons.login_rounded, size: 18),
                      label: const Text(
                        'Katıl',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
