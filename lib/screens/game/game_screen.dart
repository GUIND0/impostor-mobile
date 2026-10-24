import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/room.dart';
import '../../services/app_state.dart';
import '../../theme.dart';
import '../../widgets/countdown.dart';
import '../../widgets/leave_button.dart';
import 'clues_view.dart';
import 'guess_view.dart';
import 'results_view.dart';
import 'reveal_view.dart';
import 'vote_view.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  int _phaseSeconds(RoomState room) => switch (room.phase) {
    Phase.reveal => 90,
    Phase.clues => room.settings.turnSeconds,
    Phase.voting => room.settings.voteSeconds,
    Phase.guess => 30,
    _ => 0,
  };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final room = state.room!;
    final round = room.round;
    final title = room.phase == Phase.finished
        ? 'Fin de la partie'
        : round == null
        ? 'Imposteur'
        : 'Manche ${round.number}/${round.totalRounds}';
    final body = switch (room.phase) {
      Phase.reveal => const RevealView(),
      Phase.clues => const CluesView(),
      Phase.voting => const VoteView(),
      Phase.guess => const GuessView(),
      Phase.results || Phase.finished => const ResultsView(),
      Phase.lobby => const SizedBox.shrink(),
    };
    return Scaffold(
      appBar: AppBar(
        leading: const LeaveButton(),
        title: Text(title),
        actions: [
          if ((room.phase == Phase.clues || room.phase == Phase.voting) && round != null)
            WordPeekButton(round: round),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Countdown(
              key: ValueKey('${room.phase}-${round?.turn}-${round?.currentSpeakerId}'),
              deadline: room.deadline,
              totalSeconds: _phaseSeconds(room),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!state.connected)
              Container(
                width: double.infinity,
                color: AppColors.warning.withValues(alpha: 0.2),
                padding: const EdgeInsets.all(8),
                child: const Text('Reconnexion...', textAlign: TextAlign.center),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: KeyedSubtree(key: ValueKey(room.phase), child: body),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WordPeekButton extends StatelessWidget {
  final RoundState round;

  const WordPeekButton({super.key, required this.round});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Revoir mon mot',
      icon: const Icon(Icons.visibility_outlined),
      onPressed: () => showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  round.isImposter ? 'Vous êtes' : 'Votre mot',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                Text(
                  round.isImposter ? "L'IMPOSTEUR" : round.word ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: round.isImposter ? AppColors.imposter : Colors.white,
                  ),
                ),
                if (round.category != null) ...[
                  const SizedBox(height: 8),
                  Text('Catégorie : ${round.category}', style: const TextStyle(color: AppColors.muted)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
