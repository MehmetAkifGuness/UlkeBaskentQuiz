import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/conquest_multiplayer_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/page_trasitions.dart';
import '../widgets/geo_background.dart';
import '../widgets/glass_card.dart';
import 'conquest_online_lobby_screen.dart';


part 'conquest_online_entry_screen/content.dart';
part 'conquest_online_entry_screen/quick_game_card.dart';
part 'conquest_online_entry_screen/create_room_card.dart';
part 'conquest_online_entry_screen/join_room_card.dart';
part 'conquest_online_entry_screen/pickers.dart';
part 'conquest_online_entry_screen/actions.dart';

class ConquestOnlineEntryScreen extends StatefulWidget {
  const ConquestOnlineEntryScreen({super.key});

  @override
  State<ConquestOnlineEntryScreen> createState() =>
      _ConquestOnlineEntryScreenState();
}

class _ConquestOnlineEntryScreenState extends State<ConquestOnlineEntryScreen> {
  static const List<String> _continentFilters = <String>[
    'ALL',
    'Europe',
    'Asia',
    'Africa',
    'North America',
    'South America',
    'Oceania',
  ];

  static const List<_ColorOption> _playerColors = <_ColorOption>[
    _ColorOption('Kırmızı', Colors.red),
    _ColorOption('Mavi', Colors.blue),
    _ColorOption('Yeşil', Colors.green),
    _ColorOption('Mor', Colors.purple),
    _ColorOption('Turuncu', Colors.orange),
  ];

  final TextEditingController _createUsernameController =
      TextEditingController();
  final TextEditingController _joinUsernameController = TextEditingController();
  final TextEditingController _roomCodeController = TextEditingController();

  String _selectedContinent = 'ALL';
  Color _selectedCreateColor = Colors.blue;
  Color _selectedJoinColor = Colors.blue;

  String? _lastSnackMessage;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final username = context.read<AuthProvider>().username;
      if (username != null && username.trim().isNotEmpty) {
        _createUsernameController.text = username.trim();
        _joinUsernameController.text = username.trim();
      }
    });
  }

  @override
  void dispose() {
    _createUsernameController.dispose();
    _joinUsernameController.dispose();
    _roomCodeController.dispose();
    super.dispose();
  }

  void _triggerHaptic() {
    context.read<SettingsProvider>().triggerButtonVibration();
  }

  void _showSnackOnce(String message) {
    if (message.trim().isEmpty) return;
    if (_lastSnackMessage == message) return;
    _lastSnackMessage = message;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
          ),
        );
     });
  }

  Future<void> _createRoom() => _createRoomImpl(this);

  Future<void> _quickGame() => _quickGameImpl(this);

  Future<void> _joinRoom() => _joinRoomImpl(this);

  @override
  Widget build(BuildContext context) {
    final isBusy = context.select<ConquestMultiplayerProvider, bool>(
      (p) => p.isLoading,
    );
    final isUsernameLocked = (context.watch<AuthProvider>().username ?? '').trim().isNotEmpty;
    final errorMessage = context.select<ConquestMultiplayerProvider, String?>(
      (p) => p.errorMessage,
    );

    if (errorMessage != null) {
      _showSnackOnce(errorMessage);
      context.read<ConquestMultiplayerProvider>().clearError();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Online Dünya Fethi')),
      body: GeoBackground(
        safeArea: false,
        child: _ConquestOnlineEntryContent(
          isBusy: isBusy,
          isUsernameLocked: isUsernameLocked,
          continentFilters: _continentFilters,
          selectedContinent: _selectedContinent,
          onContinentChanged: (filter) =>
              setState(() => _selectedContinent = filter),
          playerColors: _playerColors,
          selectedCreateColor: _selectedCreateColor,
          onCreateColorChanged: (c) => setState(() => _selectedCreateColor = c),
          selectedJoinColor: _selectedJoinColor,
          onJoinColorChanged: (c) => setState(() => _selectedJoinColor = c),
          createUsernameController: _createUsernameController,
          joinUsernameController: _joinUsernameController,
          roomCodeController: _roomCodeController,
          onQuickGame: _quickGame,
          onCreateRoom: _createRoom,
          onJoinRoom: _joinRoom,
        ),
      ),
    );
  }
}

