part of '../conquest_online_lobby_screen.dart';

class _LobbyRoomCard extends StatelessWidget {
  final String roomCode;
  final String status;
  final bool isConnected;
  final bool showWaiting;
  final String waitingText;
  final VoidCallback? onCopyRoomCode;

  const _LobbyRoomCard({
    required this.roomCode,
    required this.status,
    required this.isConnected,
    required this.showWaiting,
    required this.waitingText,
    required this.onCopyRoomCode,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Oda Kodu',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  roomCode.isEmpty ? '-' : roomCode,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: onCopyRoomCode,
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Kopyala'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Durum: ',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                status,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                isConnected ? 'Bağlandı' : 'Bağlanıyor...',
                style: TextStyle(
                  color: isConnected ? Colors.greenAccent : AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (showWaiting) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  waitingText,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LobbyPlayersCard extends StatelessWidget {
  final List<ConquestPlayerState> players;
  final bool canToggleReady;
  final bool amIReady;
  final VoidCallback onToggleReady;

  const _LobbyPlayersCard({
    required this.players,
    required this.canToggleReady,
    required this.amIReady,
    required this.onToggleReady,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Oyuncular',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          if (players.isEmpty)
            const Text(
              'Oyuncu listesi bekleniyor...',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Column(
              children: [
                for (final p in players)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PlayerRow(player: p),
                  ),
              ],
            ),
          if (canToggleReady) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onToggleReady,
                icon: Icon(
                  amIReady ? Icons.check_circle : Icons.hourglass_bottom,
                  size: 18,
                ),
                label: Text(amIReady ? 'Hazırım' : 'Bekliyorum'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final ConquestPlayerState player;

  const _PlayerRow({required this.player});

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(player.colorHex ?? '');
    final ready = player.ready;
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            (player.username ?? 'Oyuncu').toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Skor: ${player.score}',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          ready ? Icons.check_circle : Icons.hourglass_bottom,
          size: 18,
          color: ready ? Colors.greenAccent : AppColors.textMuted,
        ),
        const SizedBox(width: 8),
        Icon(
          player.connected ? Icons.wifi : Icons.wifi_off,
          size: 18,
          color: player.connected ? Colors.greenAccent : Colors.redAccent,
        ),
      ],
    );
  }
}

