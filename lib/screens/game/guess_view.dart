import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../theme.dart';
import '../../widgets/avatar.dart';
import 'vote_summary.dart';

class GuessView extends StatefulWidget {
  const GuessView({super.key});

  @override
  State<GuessView> createState() => _GuessViewState();
}

class _GuessViewState extends State<GuessView> {
  final _guess = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _guess.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _guess.text.trim();
    if (value.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await context.read<AppState>().guess(value);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final room = state.room!;
    final round = room.round!;
    final accused = room.member(round.accusedId);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (accused != null) ...[
                  Avatar(name: accused.name, url: accused.avatarUrl, size: 84, ring: AppColors.imposter),
                  const SizedBox(height: 12),
                  Text(
                    '${accused.name} est accusé${accused.id == state.player!.id ? " (vous)" : ""}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ] else
                  const Text(
                    'Égalité : personne n’est accusé',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 16),
                VoteSummary(room: room, highlightId: round.accusedId),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (round.isImposter) ...[
          const Text(
            'Dernière chance : quel est le mot secret ?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.imposter),
          ),
          if (round.category != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Catégorie : ${round.category}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
          const SizedBox(height: 14),
          TextField(
            controller: _guess,
            autofocus: true,
            maxLength: 60,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(hintText: 'Votre proposition', counterText: ''),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.imposter),
            onPressed: _sending ? null : _submit,
            child: const Text('Valider'),
          ),
        ] else
          const Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 14),
              Text(
                'L’imposteur tente de deviner le mot...',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
            ],
          ),
      ],
    );
  }
}
