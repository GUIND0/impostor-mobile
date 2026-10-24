import 'package:flutter/material.dart';

import '../../models/room.dart';
import '../../theme.dart';
import '../../widgets/audio_clue_player.dart';
import '../../widgets/avatar.dart';

class ClueBubble extends StatelessWidget {
  final Clue clue;
  final RoomMember? author;
  final bool mine;

  const ClueBubble({super.key, required this.clue, this.author, this.mine = false});

  @override
  Widget build(BuildContext context) {
    final name = author?.name ?? 'Joueur';
    Widget content;
    if (clue.isSkip) {
      content = const Text(
        'A passé son tour',
        style: TextStyle(color: AppColors.muted, fontStyle: FontStyle.italic),
      );
    } else if (clue.isAudio && clue.audioUrl != null) {
      content = AudioCluePlayer(url: clue.audioUrl!, durationMs: clue.durationMs);
    } else {
      content = Text(clue.text ?? '', style: const TextStyle(fontSize: 16));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Avatar(name: name, url: author?.avatarUrl, size: 36),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: mine ? AppColors.primary.withValues(alpha: 0.25) : AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.muted),
                  ),
                  const SizedBox(height: 4),
                  content,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ClueList extends StatelessWidget {
  final RoomState room;
  final String? myId;
  final ScrollController? controller;

  const ClueList({super.key, required this.room, this.myId, this.controller});

  @override
  Widget build(BuildContext context) {
    final round = room.round!;
    final items = <Widget>[];
    for (var turn = 1; turn <= round.clueTurns; turn++) {
      final clues = round.clues.where((c) => c.turn == turn).toList();
      if (clues.isEmpty) continue;
      items.add(
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('Tour $turn', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ),
              const Expanded(child: Divider()),
            ],
          ),
        ),
      );
      for (final c in clues) {
        items.add(ClueBubble(clue: c, author: room.member(c.playerId), mine: c.playerId == myId));
      }
    }
    if (items.isEmpty) {
      return const Center(
        child: Text('Aucun indice pour le moment', style: TextStyle(color: AppColors.muted)),
      );
    }
    return ListView(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: items,
    );
  }
}
