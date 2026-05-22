part of '../conquest_online_entry_screen.dart';

class _JoinRoomCard extends StatelessWidget {
  final bool isBusy;
  final bool isUsernameLocked;
  final TextEditingController usernameController;
  final TextEditingController roomCodeController;
  final List<_ColorOption> playerColors;
  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onJoinRoom;

  const _JoinRoomCard({
    required this.isBusy,
    required this.isUsernameLocked,
    required this.usernameController,
    required this.roomCodeController,
    required this.playerColors,
    required this.selectedColor,
    required this.onColorChanged,
    required this.onJoinRoom,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Odaya Katıl',
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
          TextField(
            controller: roomCodeController,
            enabled: !isBusy,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Oda kodu',
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
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isBusy ? null : onJoinRoom,
              child: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Katıl'),
            ),
          ),
        ],
      ),
    );
  }
}


