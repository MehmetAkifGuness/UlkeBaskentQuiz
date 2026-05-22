part of '../conquest_online_entry_screen.dart';

class _ConquestOnlineEntryContent extends StatelessWidget {
  final bool isBusy;
  final bool isUsernameLocked;
  final List<String> continentFilters;
  final String selectedContinent;
  final ValueChanged<String> onContinentChanged;
  final List<_ColorOption> playerColors;
  final Color selectedCreateColor;
  final ValueChanged<Color> onCreateColorChanged;
  final Color selectedJoinColor;
  final ValueChanged<Color> onJoinColorChanged;
  final TextEditingController createUsernameController;
  final TextEditingController joinUsernameController;
  final TextEditingController roomCodeController;
  final VoidCallback onQuickGame;
  final VoidCallback onCreateRoom;
  final VoidCallback onJoinRoom;

  const _ConquestOnlineEntryContent({
    required this.isBusy,
    required this.isUsernameLocked,
    required this.continentFilters,
    required this.selectedContinent,
    required this.onContinentChanged,
    required this.playerColors,
    required this.selectedCreateColor,
    required this.onCreateColorChanged,
    required this.selectedJoinColor,
    required this.onJoinColorChanged,
    required this.createUsernameController,
    required this.joinUsernameController,
    required this.roomCodeController,
    required this.onQuickGame,
    required this.onCreateRoom,
    required this.onJoinRoom,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      physics: const BouncingScrollPhysics(),
      children: [
        _QuickGameCard(isBusy: isBusy, onPressed: onQuickGame),
        const SizedBox(height: 14),
        _CreateRoomCard(
          isBusy: isBusy,
          isUsernameLocked: isUsernameLocked,
          usernameController: createUsernameController,
          playerColors: playerColors,
          selectedColor: selectedCreateColor,
          onColorChanged: onCreateColorChanged,
          continentFilters: continentFilters,
          selectedContinent: selectedContinent,
          onContinentChanged: onContinentChanged,
          onCreateRoom: onCreateRoom,
        ),
        const SizedBox(height: 14),
        _JoinRoomCard(
          isBusy: isBusy,
          isUsernameLocked: isUsernameLocked,
          usernameController: joinUsernameController,
          roomCodeController: roomCodeController,
          playerColors: playerColors,
          selectedColor: selectedJoinColor,
          onColorChanged: onJoinColorChanged,
          onJoinRoom: onJoinRoom,
        ),
      ],
    );
  }
}

