import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../theme.dart';
import '../../widgets/avatar.dart';
import '../../widgets/clue_composer.dart';
import 'clue_list.dart';

class CluesView extends StatefulWidget {
  const CluesView({super.key});

  @override
  State<CluesView> createState() => _CluesViewState();
}

class _CluesViewState extends State<CluesView> {
  final _scroll = ScrollController();
  int _lastCount = 0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final room = state.room!;
    final round = room.round!;
    final me = state.player!.id;
    final speaker = room.member(round.currentSpeakerId);
    final myTurn = round.currentSpeakerId == me;
    if (round.clues.length != _lastCount) {
      _lastCount = round.clues.length;
      _scrollToEnd();
    }
    return Column(
      children: [
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: round.order.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final m = room.member(round.order[i]);
              final current = round.order[i] == round.currentSpeakerId;
              return Column(
                children: [
                  Avatar(
                    name: m?.name ?? '?',
                    url: m?.avatarUrl,
                    size: current ? 48 : 40,
                    ring: current ? AppColors.primary : null,
                    dimmed: m?.connected == false,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${i + 1}. ${m?.name ?? ''}',
                    style: TextStyle(
                      fontSize: 11,
                      color: current ? Colors.white : AppColors.muted,
                      fontWeight: current ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          child: Text(
            'Tour ${round.turn}/${round.clueTurns}  ·  '
            '${myTurn ? "À vous de donner un indice" : "Au tour de ${speaker?.name ?? "..."}"}',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600, color: myTurn ? AppColors.primary : null),
          ),
        ),
        Expanded(
          child: ClueList(room: room, myId: me, controller: _scroll),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: myTurn
              ? const ClueComposer()
              : Container(
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${speaker?.name ?? "Un joueur"} réfléchit...',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
        ),
      ],
    );
  }
}
