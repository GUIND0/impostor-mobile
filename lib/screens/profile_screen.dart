import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/player.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import '../widgets/photo_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _name;
  late Future<List<GameSummary>> _games;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _name = TextEditingController(text: state.player?.name ?? '');
    _games = state.api.myGames();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _guard(Future<void> Function() action, String success) async {
    setState(() => _saving = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePhoto() async {
    final path = await pickProfilePhoto(context);
    if (path == null || !mounted) return;
    await _guard(() => context.read<AppState>().changeAvatar(path), 'Photo mise à jour');
  }

  Future<void> _saveName() async {
    final name = _name.text.trim();
    if (name.length < 2) {
      showError(context, 'Le nom doit contenir au moins 2 caractères');
      return;
    }
    FocusScope.of(context).unfocus();
    await _guard(() => context.read<AppState>().rename(name), 'Nom mis à jour');
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AppState>().player!;
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: GestureDetector(
              onTap: _saving ? null : _changePhoto,
              child: Stack(
                children: [
                  Avatar(name: player.name, url: player.avatarUrl, size: 120, ring: AppColors.primary),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.edit, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _name,
                  maxLength: 20,
                  decoration: const InputDecoration(labelText: 'Nom', counterText: ''),
                  onSubmitted: (_) => _saveName(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _saving ? null : _saveName, icon: const Icon(Icons.check)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _Stat(label: 'Points', value: '${player.totalPoints}'),
              const SizedBox(width: 10),
              _Stat(label: 'Parties', value: '${player.gamesPlayed}'),
              const SizedBox(width: 10),
              _Stat(label: 'Victoires', value: '${player.wins}'),
            ],
          ),
          const SizedBox(height: 28),
          const Text('Dernières parties', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          FutureBuilder<List<GameSummary>>(
            future: _games,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return snapshot.hasError
                    ? Text(snapshot.error.toString(), style: const TextStyle(color: AppColors.muted))
                    : const Center(child: CircularProgressIndicator());
              }
              final games = snapshot.data!;
              if (games.isEmpty) {
                return const Text('Aucune partie jouée', style: TextStyle(color: AppColors.muted));
              }
              return Column(
                children: [
                  for (final g in games)
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: g.rank == 1 ? AppColors.warning : AppColors.surfaceHigh,
                          child: Text('${g.rank}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        title: Text('${g.score} points'),
                        subtitle: Text('${_date(g.finishedAt)} · ${g.players} joueurs · ${g.rounds} manches'),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
