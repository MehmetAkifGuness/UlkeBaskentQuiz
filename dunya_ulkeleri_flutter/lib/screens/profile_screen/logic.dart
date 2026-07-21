part of '../profile_screen.dart';

Future<_ProfileData?> _fetchProfileDataImpl(UserService userService, String token) async {
  final profileFuture = userService.getUserProfile(token);
  final scoresFuture = userService.getMyCategoryScores(token).catchError(
    (_) => <String, int>{},
  );

  final profile = await profileFuture;
  if (profile == null) return null;

  final scores = await scoresFuture;

  Uint8List? avatarBytes;
  if (profile.hasCustomAvatar) {
    avatarBytes = await userService.getCustomAvatarBytes(token, profile.username);
  }

  final updatedProfile = profile.copyWith(customAvatarBytes: avatarBytes);
  return _ProfileData(profile: updatedProfile, scores: scores);
}

Future<void> _pickAndUploadAvatarImpl(_ProfileScreenState state, String token) async {
  try {
    final file = await state._imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 768,
      maxHeight: 768,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final name = file.name;
    final contentType = state._guessImageContentType(name);

    final ok = await state._userService.uploadCustomAvatar(
      token,
      bytes,
      filename: name,
      contentType: contentType,
    );
    if (!ok) return;
    if (!state.mounted) return;
    state._updateLocalProfile(
      (current) => current.copyWith(
        hasCustomAvatar: true,
        customAvatarBytes: bytes,
      ),
    );
  } catch (e) {
    if (!state.mounted) return;
    ScaffoldMessenger.of(state.context).showSnackBar(
      SnackBar(
        content: Text('Profil fotoğrafı yüklenemedi: $e'),
        backgroundColor: AppColors.errorRed,
      ),
    );
  }
}

Future<void> _editUsernameImpl(
  _ProfileScreenState state,
  String token,
  String currentUsername,
) async {
  final usernameController = TextEditingController(text: currentUsername);

  final result = await showDialog<String>(
    context: state.context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Kullanıcı adını güncelle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              maxLength: 20,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                hintText: 'Kullanıcı adı',
                helperText:
                    'Kullanıcı adını değiştirince eskisi başkaları tarafından alınabilir.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(usernameController.text),
            child: const Text('Kaydet'),
          ),
        ],
      );
    },
  );

  if (result == null) return;

  final username = result.trim();
  if (username.isEmpty || username == currentUsername) return;

  try {
    final auth = await state._userService.updateUsername(token, username);
    final newToken = auth.token;
    final newUsername = auth.username;

    if (newToken == null || newUsername == null) {
      throw Exception('Kullanıcı adı güncellenemedi (eksik yanıt).');
    }

    if (!state.mounted) return;

    await Provider.of<AuthProvider>(state.context, listen: false).updateSession(
      token: newToken,
      username: newUsername,
    );

    state._updateLocalProfile((current) => current.copyWith(username: newUsername));
  } catch (e) {
    if (!state.mounted) return;
    ScaffoldMessenger.of(state.context).showSnackBar(
      SnackBar(
        content: Text(errorMessageFrom(e)),
        backgroundColor: AppColors.errorRed,
      ),
    );
  }
}

List<Widget> _buildMasteryCards(Map<String, int> scores) {
  const specialModes = [
    _SpecialModeInfo(
      title: 'Günün Görevi',
      scoreKey: 'DailyChallenge_MIXED',
      maxScore: 20000,
    ),
    _SpecialModeInfo(
      title: 'Sonsuz Mod',
      scoreKey: 'Dünya_ENDLESS',
      maxScore: 40000,
    ),
  ];

  const continents = [
    _ContinentInfo('Avrupa', 44),
    _ContinentInfo('Asya', 48),
    _ContinentInfo('Afrika', 54),
    _ContinentInfo('Kuzey Amerika', 23),
    _ContinentInfo('Güney Amerika', 12),
    _ContinentInfo('Okyanusya', 14),
  ];
  const world = _ContinentInfo('Dünya', 195);

  return [
    for (final item in specialModes)
      _MasteryCard.fromSingleScore(
        title: item.title,
        scoreKey: item.scoreKey,
        maxScore: item.maxScore,
        scores: scores,
      ),
    _MasteryCard.fromScores(continent: world, scores: scores),
    for (final continent in continents)
      _MasteryCard.fromScores(continent: continent, scores: scores),
  ];
}

String _generateAnalysisText(Map<String, int> scores) {
  const categories = [
    _ContinentInfo('Avrupa', 44),
    _ContinentInfo('Asya', 48),
    _ContinentInfo('Afrika', 54),
    _ContinentInfo('Kuzey Amerika', 23),
    _ContinentInfo('Güney Amerika', 12),
    _ContinentInfo('Okyanusya', 14),
  ];

  final unplayed = <String>[];
  final weak = <String>[];

  for (final item in categories) {
    final c2c = scores['${item.name}_COUNTRY_TO_CAPITAL'] ?? 0;
    final c2cRev = scores['${item.name}_CAPITAL_TO_COUNTRY'] ?? 0;
    final mixed = scores['${item.name}_MIXED'] ?? 0;

    final maxScoreMode = math.max(c2c, math.max(c2cRev, mixed));
    final maxPossible = item.questions * 2000;
    final percentage = maxPossible > 0 ? (maxScoreMode / maxPossible) : 0;

    if (maxScoreMode == 0) {
      unplayed.add(item.name);
    } else if (percentage < 0.4) {
      weak.add(item.name);
    }
  }

  if (unplayed.length == categories.length) {
    return 'Henüz hiçbir kıtada oynamamışsın! Hemen bir oyuna girerek dünyayı keşfetmeye başla.';
  }

  final buffer = StringBuffer();
  if (weak.isNotEmpty) {
    buffer.writeln(
      'İstatistiklerine göre ${weak.join(', ')} bölgelerinde zorlandığın görünüyor. '
      'Farklı oyun modlarında pratik yaparak doğruluğunu artırabilirsin.',
    );
    buffer.writeln();
  }
  if (unplayed.isNotEmpty) {
    buffer.write(
      'Ayrıca ${unplayed.join(', ')} bölgelerinde henüz hiç oynamamışsın. '
      'Şansını oralarda da denemeni öneririm.',
    );
  }

  return buffer.toString().trim();
}

double _progressToNextTier(int totalScore) {
  final tiers = _TierInfo.tiers;
  for (var i = 0; i < tiers.length; i++) {
    final current = tiers[i];
    final next = i + 1 < tiers.length ? tiers[i + 1] : null;
    if (next == null) return 1.0;
    if (totalScore < next.minScore) {
      final span = math.max(1, next.minScore - current.minScore).toDouble();
      return ((totalScore - current.minScore) / span).clamp(0.0, 1.0);
    }
  }
  return 1.0;
}

String _formatNumber(int value) {
  final s = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final idxFromEnd = s.length - i;
    buffer.write(s[i]);
    if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buffer.write('.');
  }
  return buffer.toString();
}

String _formatCompact(int value) {
  if (value >= 1_000_000_000) {
    final v = value / 1_000_000_000;
    return '${v.toStringAsFixed(v < 10 ? 1 : 0)}B';
  }
  if (value >= 1_000_000) {
    final v = value / 1_000_000;
    return '${v.toStringAsFixed(v < 10 ? 1 : 0)}M';
  }
  if (value >= 1_000) {
    final v = value / 1_000;
    return '${v.toStringAsFixed(v < 10 ? 1 : 0)}K';
  }
  return value.toString();
}
