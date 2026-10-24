import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../theme.dart';
import '../../widgets/avatar.dart';
import 'clue_list.dart';

class VoteView extends StatelessWidget {
  const VoteView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final room = state.room!;
    final round = room.round!;
    final me = state.player!.id;
    final candidates = room.members.where((m) => m.id != me).toList();
    final online = room.members.where((m) => m.connected).length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Column(
            children: [
              const Text(
                'Qui est l’imposteur ?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${round.votedIds.length}/$online votes · vous pouvez changer d’avis tant que tout le monde n’a pas voté',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 130,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: candidates.length,
            itemBuilder: (context, i) {
              final m = candidates[i];
              final selected = round.myVote == m.id;
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => state.vote(m.id).catchError((e) {
                  if (context.mounted) showError(context, e);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.imposter.withValues(alpha: 0.2) : AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: selected ? AppColors.imposter : Colors.transparent, width: 2),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Avatar(name: m.name, url: m.avatarUrl, size: 60, dimmed: !m.connected),
                          if (round.votedIds.contains(m.id))
                            const Positioned(
                              right: -4,
                              bottom: -4,
                              child: CircleAvatar(
                                radius: 10,
                                backgroundColor: AppColors.success,
                                child: Icon(Icons.how_to_vote, size: 12, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        m.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Rappel des indices',
            style: TextStyle(color: AppColors.muted.withValues(alpha: 0.9), fontSize: 13),
          ),
        ),
        Expanded(
          flex: 2,
          child: ClueList(room: room, myId: me),
        ),
      ],
    );
  }
}
