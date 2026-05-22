part of '../conquest_online_entry_screen.dart';

class _CreateRoomCard extends StatelessWidget {
  final bool isBusy;
  final bool isUsernameLocked;
  final TextEditingController usernameController;
  final List<_ColorOption> playerColors;
  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;
  final List<String> continentFilters;
  final String selectedContinent;
  final ValueChanged<String> onContinentChanged;
  final VoidCallback onCreateRoom;

  const _CreateRoomCard({
    required this.isBusy,
    required this.isUsernameLocked,
    required this.usernameController,
    required this.playerColors,
    required this.selectedColor,
    required this.onColorChanged,
    required this.continentFilters,
    required this.selectedContinent,
    required this.onContinentChanged,
    required this.onCreateRoom,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Oda Oluştur',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: usernameController,
            enabled: !isBusy,
            readOnly: isUsernameLocked,
            decoration: InputDecoration(
              labelText: isUsernameLocked ? 'Kullanıcı adı (hesabın)' : 'Kullanıcı adı',
              labelStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surface2.withValues(alpha: 0.55),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Oyuncu rengi',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _ColorPicker(
            options: playerColors,
            selected: selectedColor,
            enabled: !isBusy,
            onChanged: onColorChanged,
          ),
          const SizedBox(height: 12),
          const Text(
            'Kıta',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _ContinentPicker(
            filters: continentFilters,
            selected: selectedContinent,
            enabled: !isBusy,
            onChanged: onContinentChanged,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isBusy ? null : onCreateRoom,
              child: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Oda Oluştur'),
            ),
          ),
        ],
      ),
    );
  }
}


