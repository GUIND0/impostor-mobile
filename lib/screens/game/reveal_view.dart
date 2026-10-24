import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../theme.dart';
import '../../widgets/avatar.dart';

class RevealView extends StatefulWidget {
  const RevealView({super.key});

  @override
  State<RevealView> createState() => _RevealViewState();
}

class _RevealViewState extends State<RevealView> with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  bool _sending = false;

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_flip.isCompleted || _flip.velocity > 0) {
      _flip.reverse();
    } else {
      _flip.forward();
    }
  }

  Future<void> _confirm() async {
    setState(() => _sending = true);
    try {
      await context.read<AppState>().markSeen();
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            round.seen ? 'En attente des autres joueurs' : 'Touchez la carte pour découvrir votre mot',
            style: const TextStyle(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GestureDetector(
              onTap: _toggle,
              child: AnimatedBuilder(
                animation: _flip,
                builder: (context, _) {
                  final angle = _flip.value * pi;
                  final showFront = angle > pi / 2;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    child: showFront
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationY(pi),
                            child: _WordFace(
                              imposter: round.isImposter,
                              word: round.word,
                              category: round.category,
                            ),
                          )
                        : const _BackFace(),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final m in room.members)
                Avatar(
                  name: m.name,
                  url: m.avatarUrl,
                  size: 38,
                  colorIndex: room.colorOf(m.id),
                  ring: round.seenIds.contains(m.id) ? AppColors.success : null,
                  dimmed: !m.connected,
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (!round.seen)
            AnimatedBuilder(
              animation: _flip,
              builder: (context, _) => FilledButton(
                onPressed: _flip.value > 0.5 && !_sending ? _confirm : null,
                child: const Text("J'ai vu mon mot"),
              ),
            )
          else
            Text(
              '${round.seenIds.length}/${room.members.where((m) => m.connected).length} joueurs prêts',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}

class _BackFace extends StatelessWidget {
  const _BackFace();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF6D28D9), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.help_outline, size: 96, color: Colors.white70),
          SizedBox(height: 16),
          Text('Mot secret', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text('Cachez votre écran', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _WordFace extends StatelessWidget {
  final bool imposter;
  final String? word;
  final String? category;

  const _WordFace({required this.imposter, this.word, this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: imposter ? const Color(0xFF450A0A) : AppColors.surfaceHigh,
        border: Border.all(color: imposter ? AppColors.imposter : AppColors.primary, width: 2),
      ),
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imposter) ...[
            const Icon(Icons.theater_comedy, size: 80, color: AppColors.imposter),
            const SizedBox(height: 16),
            const Text(
              "Vous êtes l'imposteur",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.imposter),
            ),
            const SizedBox(height: 12),
            const Text(
              'Faites comme si vous connaissiez le mot et essayez de le deviner.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ] else ...[
            const Text('Votre mot', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            FittedBox(
              child: Text(word ?? '', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900)),
            ),
          ],
          if (category != null) ...[const SizedBox(height: 20), Chip(label: Text('Catégorie : $category'))],
        ],
      ),
    );
  }
}
