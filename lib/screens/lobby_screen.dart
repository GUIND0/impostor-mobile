import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/room.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import '../widgets/leave_button.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final room = state.room!;
    final isHost = state.isHost;
    final online = room.members.where((m) => m.connected).length;
    return Scaffold(
      appBar: AppBar(title: const Text("Salle d'attente"), leading: const LeaveButton()),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _CodeCard(code: room.code, inviter: state.player!.name),
                  const SizedBox(height: 24),
                  Text(
                    'Joueurs ($online/12)',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  for (final m in room.members) _MemberTile(member: m, room: room, canKick: isHost),
                  const SizedBox(height: 24),
                  _SettingsCard(settings: room.settings, categoryLabel: room.categoryLabel, editable: isHost),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: isHost
                  ? FilledButton.icon(
                      onPressed: online >= 3
                          ? () => state.startGame().catchError((e) {
                              if (context.mounted) showError(context, e);
                            })
                          : null,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(online >= 3 ? 'Lancer la partie' : 'Il faut au moins 3 joueurs'),
                    )
                  : Container(
                      height: 54,
                      alignment: Alignment.center,
                      child: Text(
                        "En attente de ${room.member(room.hostId)?.name ?? "l'hôte"}...",
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  final String code;
  final String inviter;

  const _CodeCard({required this.code, required this.inviter});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Code de la partie', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 6),
            SelectableText(
              code,
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 10),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copié')));
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copier'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(
                        text:
                            '$inviter t’invite à une partie d’Imposteur. '
                            'Ouvre l’application, touche « Rejoindre une partie » et entre le code $code',
                      ),
                    ),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Inviter'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final RoomMember member;
  final RoomState room;
  final bool canKick;

  const _MemberTile({required this.member, required this.room, required this.canKick});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final isMe = member.id == state.player?.id;
    final isHost = member.id == room.hostId;
    return Card(
      child: ListTile(
        leading: Avatar(name: member.name, url: member.avatarUrl, dimmed: !member.connected),
        title: Text(isMe ? '${member.name} (vous)' : member.name),
        subtitle: !member.connected ? const Text('Déconnecté') : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isHost)
              const Chip(
                label: Text('Hôte'),
                avatar: Icon(Icons.star, size: 16, color: AppColors.warning),
                visualDensity: VisualDensity.compact,
              ),
            if (canKick && !isMe)
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.muted),
                tooltip: 'Retirer',
                onPressed: () => state.kick(member.id).catchError((e) {
                  if (context.mounted) showError(context, e);
                }),
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final RoomSettings settings;
  final String categoryLabel;
  final bool editable;

  const _SettingsCard({required this.settings, required this.categoryLabel, required this.editable});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    void update(Map<String, dynamic> patch) {
      state.updateSettings(patch).catchError((e) {
        if (context.mounted) showError(context, e);
      });
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('Paramètres', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
            _Stepper(
              label: 'Manches',
              value: settings.rounds,
              min: 1,
              max: 10,
              enabled: editable,
              onChanged: (v) => update({'rounds': v}),
            ),
            _Stepper(
              label: 'Temps pour lire son mot',
              value: settings.revealSeconds,
              min: 10,
              max: 120,
              step: 5,
              suffix: ' s',
              enabled: editable,
              onChanged: (v) => update({'revealSeconds': v}),
            ),
            _Stepper(
              label: "Tours d'indices",
              value: settings.clueTurns,
              min: 1,
              max: 3,
              enabled: editable,
              onChanged: (v) => update({'clueTurns': v}),
            ),
            _Stepper(
              label: 'Temps par indice',
              value: settings.turnSeconds,
              min: 20,
              max: 180,
              step: 10,
              suffix: ' s',
              enabled: editable,
              onChanged: (v) => update({'turnSeconds': v}),
            ),
            _Stepper(
              label: 'Temps de vote',
              value: settings.voteSeconds,
              min: 20,
              max: 180,
              step: 10,
              suffix: ' s',
              enabled: editable,
              onChanged: (v) => update({'voteSeconds': v}),
            ),
            ListTile(
              title: const Text('Catégorie'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(categoryLabel, style: const TextStyle(color: AppColors.muted)),
                  if (editable) const Icon(Icons.chevron_right, color: AppColors.muted),
                ],
              ),
              onTap: !editable
                  ? null
                  : () async {
                      final picked = await showModalBottomSheet<String>(
                        context: context,
                        showDragHandle: true,
                        builder: (context) => SafeArea(
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              ListTile(
                                title: const Text('Aléatoire'),
                                onTap: () => Navigator.pop(context, 'random'),
                              ),
                              for (final c in state.categories)
                                ListTile(title: Text(c.label), onTap: () => Navigator.pop(context, c.id)),
                            ],
                          ),
                        ),
                      );
                      if (picked != null) update({'category': picked});
                    },
            ),
            SwitchListTile(
              title: const Text("Mot similaire pour l'imposteur"),
              subtitle: Text(
                settings.similarMode
                    ? "L'imposteur reçoit un mot proche et ne sait pas qu'il est l'imposteur"
                    : "L'imposteur ne reçoit aucun mot et sait qu'il est l'imposteur",
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              value: settings.similarMode,
              onChanged: editable ? (v) => update({'imposterMode': v ? 'similar' : 'none'}) : null,
            ),
            if (!settings.similarMode)
              SwitchListTile(
                title: const Text("L'imposteur voit la catégorie"),
                value: settings.imposterSeesCategory,
                onChanged: editable ? (v) => update({'imposterSeesCategory': v}) : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final String suffix;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    this.suffix = '',
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (enabled)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: value - step >= min ? () => onChanged(value - step) : null,
            ),
          SizedBox(
            width: 48,
            child: Text(
              '$value$suffix',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (enabled)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: value + step <= max ? () => onChanged(value + step) : null,
            ),
        ],
      ),
    );
  }
}
