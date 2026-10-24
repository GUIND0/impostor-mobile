import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../theme.dart';
import '../../widgets/avatar.dart';
import 'clue_list.dart';

class VoteView extends StatefulWidget {
  const VoteView({super.key});

  @override
  State<VoteView> createState() => _VoteViewState();
}

class _VoteViewState extends State<VoteView> {
  String? _pending;

  Future<void> _vote(String targetId) async {
    if (_pending != null) return;
    setState(() => _pending = targetId);
    try {
      await context.read<AppState>().vote(targetId);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _pending = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final room = state.room!;
    final round = room.round!;
    final me = state.player!.id;
    final candidates = room.members.where((m) => m.id != me).toList();
    final voters = room.members.where((m) => m.connected).toList();
    final myChoice = _pending ?? round.myVote;
    final myChoiceName = room.member(myChoice)?.name;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            children: [
              const Text(
                'Qui est l’imposteur ?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                myChoiceName == null
                    ? 'Touchez le joueur que vous soupçonnez'
                    : 'Votre vote : $myChoiceName · vous pouvez changer tant que tout le monde n’a pas voté',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: myChoiceName == null ? AppColors.muted : AppColors.imposter,
                  fontSize: 13,
                  fontWeight: myChoiceName == null ? FontWeight.normal : FontWeight.w600,
                ),
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
              childAspectRatio: 0.72,
            ),
            itemCount: candidates.length,
            itemBuilder: (context, i) {
              final m = candidates[i];
              final selected = myChoice == m.id;
              return InkWell(
                key: ValueKey(m.id),
                borderRadius: BorderRadius.circular(18),
                onTap: _pending != null || round.myVote == m.id ? null : () => _vote(m.id),
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
                      Avatar(
                        name: m.name,
                        url: m.avatarUrl,
                        size: 56,
                        dimmed: !m.connected,
                        colorIndex: room.colorOf(m.id),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        m.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (selected)
                        const Text(
                          'Votre vote',
                          style: TextStyle(
                            color: AppColors.imposter,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ont déjà voté : ${round.votedIds.length}/${voters.length}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final m in voters)
                    Avatar(
                      key: ValueKey('voted-${m.id}'),
                      name: m.name,
                      url: m.avatarUrl,
                      size: 30,
                      colorIndex: room.colorOf(m.id),
                      ring: round.votedIds.contains(m.id) ? AppColors.success : null,
                      dimmed: !round.votedIds.contains(m.id),
                    ),
                ],
              ),
            ],
          ),
        ),
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
