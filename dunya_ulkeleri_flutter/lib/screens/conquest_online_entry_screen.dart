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

  Future<void> _createRoom() async {
    _triggerHaptic();
    final username = _createUsernameController.text.trim();
    if (username.isEmpty) {
      _showSnackOnce('Kullanıcı adı boş olamaz.');
      return;
    }

    final provider = context.read<ConquestMultiplayerProvider>();
    final ok = await provider.createOnlineSession(
      username: username,
      color: _selectedCreateColor,
      continentFilter: _selectedContinent,
    );
    if (!ok) {
      _showSnackOnce(provider.errorMessage ?? 'Oda oluşturulamadı.');
      provider.clearError();
      return;
    }

    await provider.connectToCurrentSession();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      FadePageRoute(page: const ConquestOnlineLobbyScreen()),
    );
  }

  Future<void> _joinRoom() async {
    _triggerHaptic();
    final username = _joinUsernameController.text.trim();
    final roomCode = _roomCodeController.text.trim().toUpperCase();

    if (username.isEmpty) {
      _showSnackOnce('Kullanıcı adı boş olamaz.');
      return;
    }
    if (roomCode.isEmpty) {
      _showSnackOnce('Oda kodu boş olamaz.');
      return;
    }

    final provider = context.read<ConquestMultiplayerProvider>();
    final ok = await provider.joinOnlineSession(
      username: username,
      roomCode: roomCode,
      color: _selectedJoinColor,
    );
    if (!ok) {
      _showSnackOnce(provider.errorMessage ?? 'Odaya katılınamadı.');
      provider.clearError();
      return;
    }

    await provider.connectToCurrentSession();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      FadePageRoute(page: const ConquestOnlineLobbyScreen()),
    );
  }

  Widget _continentPicker({required bool enabled}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final filter in _continentFilters)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                label: Text(filter),
                selected: _selectedContinent == filter,
                onSelected:
                    enabled ? (_) => setState(() => _selectedContinent = filter) : null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _colorPicker({
    required List<_ColorOption> options,
    required Color selected,
    required ValueChanged<Color> onChanged,
    required bool enabled,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final opt in options)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: opt.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(opt.label),
                  ],
                ),
                selected: selected.toARGB32() == opt.color.toARGB32(),
                onSelected: enabled ? (_) => onChanged(opt.color) : null,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConquestMultiplayerProvider>();
    final isBusy = provider.isLoading;

    if (provider.errorMessage != null) {
      _showSnackOnce(provider.errorMessage!);
      provider.clearError();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Online Dünya Fethi')),
      body: GeoBackground(
        safeArea: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          physics: const BouncingScrollPhysics(),
          children: [
            GlassCard(
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
                    controller: _createUsernameController,
                    enabled: !isBusy,
                    decoration: InputDecoration(
                      labelText: 'Kullanıcı adı',
                      labelStyle: const TextStyle(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.surface2.withOpacity(0.55),
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
                  _colorPicker(
                    options: _playerColors,
                    selected: _selectedCreateColor,
                    enabled: !isBusy,
                    onChanged: (c) => setState(() => _selectedCreateColor = c),
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
                  _continentPicker(enabled: !isBusy),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isBusy ? null : _createRoom,
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
            ),
            const SizedBox(height: 14),
            GlassCard(
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
                    controller: _joinUsernameController,
                    enabled: !isBusy,
                    decoration: InputDecoration(
                      labelText: 'Kullanıcı adı',
                      labelStyle: const TextStyle(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.surface2.withOpacity(0.55),
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
                    controller: _roomCodeController,
                    enabled: !isBusy,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Oda kodu',
                      labelStyle: const TextStyle(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.surface2.withOpacity(0.55),
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
                  _colorPicker(
                    options: _playerColors,
                    selected: _selectedJoinColor,
                    enabled: !isBusy,
                    onChanged: (c) => setState(() => _selectedJoinColor = c),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isBusy ? null : _joinRoom,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorOption {
  final String label;
  final Color color;

  const _ColorOption(this.label, this.color);
}

