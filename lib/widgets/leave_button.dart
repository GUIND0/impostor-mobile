import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/room.dart';
import '../services/app_state.dart';
import '../theme.dart';

class LeaveButton extends StatelessWidget {
  const LeaveButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.close),
      tooltip: 'Quitter la partie',
      onPressed: () async {
        final state = context.read<AppState>();
        final inGame = state.room?.phase != Phase.lobby && state.room?.phase != Phase.finished;
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Quitter la partie ?'),
            content: Text(
              inGame
                  ? 'La partie est en cours. Vos tours seront passés automatiquement.'
                  : 'Vous pourrez rejoindre à nouveau avec le code.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Rester')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Quitter', style: TextStyle(color: AppColors.imposter)),
              ),
            ],
          ),
        );
        if (ok == true) {
          try {
            await state.leaveRoom();
          } catch (e) {
            if (context.mounted) showError(context, e);
          }
        }
      },
    );
  }
}
