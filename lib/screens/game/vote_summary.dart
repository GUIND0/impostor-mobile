import 'package:flutter/material.dart';

import '../../models/room.dart';
import '../../theme.dart';
import '../../widgets/avatar.dart';

class VoteSummary extends StatelessWidget {
  final RoomState room;
  final String? highlightId;

  const VoteSummary({super.key, required this.room, this.highlightId});

  @override
  Widget build(BuildContext context) {
    final votes = room.round?.votes ?? const <String, String>{};
    final tally = <String, List<String>>{};
    votes.forEach((voter, target) => tally.putIfAbsent(target, () => []).add(voter));
    final entries = tally.entries.toList()..sort((a, b) => b.value.length.compareTo(a.value.length));
    if (entries.isEmpty) {
      return const Text('Aucun vote', style: TextStyle(color: AppColors.muted));
    }
    return Column(
      children: [
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Avatar(
                  name: room.member(e.key)?.name ?? '?',
                  url: room.member(e.key)?.avatarUrl,
                  size: 40,
                  ring: e.key == highlightId ? AppColors.imposter : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.member(e.key)?.name ?? '?',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Voté par : ${e.value.map((id) => room.member(id)?.name ?? '?').join(', ')}',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${e.value.length} vote${e.value.length > 1 ? 's' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
