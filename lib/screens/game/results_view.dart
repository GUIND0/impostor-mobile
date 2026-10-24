import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/room.dart';
import '../../services/app_state.dart';
import '../../theme.dart';
import '../../widgets/avatar.dart';
import 'vote_summary.dart';

class ResultsView extends StatelessWidget {
  const ResultsView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final room = state.room!;
    final round = room.round!;
    final result = round.result!;
    final imposter = room.member(result.imposterId);
    final finished = room.phase == Phase.finished;
    final me = state.player!.id;

    final headline = result.caught
        ? (result.guessCorrect ? 'Démasqué, mais il a trouvé le mot !' : "L'imposteur est démasqué !")
        : "L'imposteur s'en sort !";
    final headlineColor = result.caught && !result.guessCorrect ? AppColors.success : AppColors.imposter;

    final standings = [...room.members]..sort((a, b) => b.score.compareTo(a.score));

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        headline,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: headlineColor),
                      ),
                      const SizedBox(height: 18),
                      Avatar(
                        name: imposter?.name ?? '?',
                        url: imposter?.avatarUrl,
                        size: 90,
                        ring: AppColors.imposter,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "${imposter?.name ?? '?'} était l'imposteur",
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      Text('Le mot était', style: const TextStyle(color: AppColors.muted)),
                      Text(result.word, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text(
                        result.guess == null
                            ? "L'imposteur n'a rien proposé"
                            : 'Proposition : « ${result.guess} » ${result.guessCorrect ? "(correct)" : "(faux)"}',
                        style: TextStyle(color: result.guessCorrect ? AppColors.warning : AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('Détail des votes'),
                collapsedBackgroundColor: AppColors.surface,
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [VoteSummary(room: room, highlightId: result.imposterId)],
              ),
              const SizedBox(height: 16),
              Text(
                finished ? 'Classement final' : 'Scores',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < standings.length; i++)
                _ScoreRow(
                  position: standings.indexWhere((m) => m.score == standings[i].score) + 1,
                  member: standings[i],
                  gained: result.points[standings[i].id] ?? 0,
                  isMe: standings[i].id == me,
                  highlightWinner: finished,
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: _Actions(finished: finished, isHost: state.isHost, hostName: room.member(room.hostId)?.name),
        ),
      ],
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final int position;
  final RoomMember member;
  final int gained;
  final bool isMe;
  final bool highlightWinner;

  const _ScoreRow({
    required this.position,
    required this.member,
    required this.gained,
    required this.isMe,
    required this.highlightWinner,
  });

  @override
  Widget build(BuildContext context) {
    final winner = highlightWinner && position == 1;
    return Card(
      color: isMe ? AppColors.surfaceHigh : null,
      child: ListTile(
        leading: Avatar(name: member.name, url: member.avatarUrl, ring: winner ? AppColors.warning : null),
        title: Text('$position. ${member.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: winner ? const Text('Vainqueur', style: TextStyle(color: AppColors.warning)) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (gained > 0)
              Text(
                '+$gained  ',
                style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
              ),
            Text('${member.score} pts', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final bool finished;
  final bool isHost;
  final String? hostName;

  const _Actions({required this.finished, required this.isHost, this.hostName});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    if (finished) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => state.leaveRoom().catchError((e) {
                if (context.mounted) showError(context, e);
              }),
              child: const Text('Quitter'),
            ),
          ),
          if (isHost) ...[
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => state.restart().catchError((e) {
                  if (context.mounted) showError(context, e);
                }),
                child: const Text('Rejouer'),
              ),
            ),
          ],
        ],
      );
    }
    if (isHost) {
      return FilledButton.icon(
        onPressed: () => state.nextRound().catchError((e) {
          if (context.mounted) showError(context, e);
        }),
        icon: const Icon(Icons.skip_next),
        label: const Text('Manche suivante'),
      );
    }
    return SizedBox(
      height: 54,
      child: Center(
        child: Text(
          'En attente de ${hostName ?? "l'hôte"} pour la manche suivante...',
          style: const TextStyle(color: AppColors.muted),
        ),
      ),
    );
  }
}
