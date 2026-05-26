import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/duel_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/page_trasitions.dart';
import '../widgets/geo_background.dart';
import '../widgets/glass_card.dart';
import 'duel_game_screen.dart';

part 'duel_entry_screen/actions.dart';
part 'duel_entry_screen/content.dart';
part 'duel_entry_screen/pickers.dart';

class DuelEntryScreen extends StatefulWidget {
  const DuelEntryScreen({super.key});

  @override
  State<DuelEntryScreen> createState() => _DuelEntryScreenState();
}

class _DuelEntryScreenState extends State<DuelEntryScreen> {
  static const List<String> _categories = <String>[
    'Dünya',
    'Avrupa',
    'Asya',
    'Afrika',
    'Kuzey Amerika',
    'Güney Amerika',
    'Okyanusya',
  ];

  static const List<_ModeOption> _modes = <_ModeOption>[
    _ModeOption('Karışık', 'MIXED'),
    _ModeOption('Ülke → Başkent', 'COUNTRY_TO_CAPITAL'),
    _ModeOption('Başkent → Ülke', 'CAPITAL_TO_COUNTRY'),
  ];

  static const List<_BotDifficultyOption> _botDifficulties = <_BotDifficultyOption>[
    _BotDifficultyOption('Kolay', 'EASY'),
    _BotDifficultyOption('Orta', 'MEDIUM'),
    _BotDifficultyOption('Zor', 'HARD'),
  ];

  final TextEditingController _roomCodeController = TextEditingController();

  String _selectedCategory = 'Dünya';
  String _selectedMode = 'MIXED';
  String _selectedBotDifficulty = 'MEDIUM';

  String? _lastSnackMessage;

  @override
  void dispose() {
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
  Future<void> _botMatch() => _botMatchImpl(this);
  Future<void> _quickMatch() => _quickMatchImpl(this);
  Future<void> _joinRoom() => _joinRoomImpl(this);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DuelProvider>();
    final token = context.watch<AuthProvider>().token;

    if (provider.errorMessage != null) {
      _showSnackOnce(provider.errorMessage!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<DuelProvider>().clearError();
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Online Düello')),
      body: GeoBackground(
        safeArea: false,
        child: _DuelEntryContent(
          isBusy: provider.isLoading || token == null,
          categories: _categories,
          selectedCategory: _selectedCategory,
          onCategoryChanged: (c) => setState(() => _selectedCategory = c),
          modes: _modes,
          selectedMode: _selectedMode,
          onModeChanged: (m) => setState(() => _selectedMode = m),
          botDifficulties: _botDifficulties,
          selectedBotDifficulty: _selectedBotDifficulty,
          onBotDifficultyChanged: (d) => setState(() => _selectedBotDifficulty = d),
          roomCodeController: _roomCodeController,
          onQuickMatch: _quickMatch,
          onBotMatch: _botMatch,
          onCreateRoom: _createRoom,
          onJoinRoom: _joinRoom,
          onHaptic: _triggerHaptic,
        ),
      ),
    );
  }
}

class _ModeOption {
  final String label;
  final String value;
  const _ModeOption(this.label, this.value);
}

class _BotDifficultyOption {
  final String label;
  final String value;
  const _BotDifficultyOption(this.label, this.value);
}
