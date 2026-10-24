import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/player.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<List<Player>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AppState>().api.leaderboard();
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<AppState>().player?.id;
    return Scaffold(
      appBar: AppBar(title: const Text('Classement')),
      body: FutureBuilder<List<Player>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final players = snapshot.data!;
          if (players.isEmpty) {
            return const Center(
              child: Text('Aucune partie terminée pour le moment', style: TextStyle(color: AppColors.muted)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              final next = context.read<AppState>().api.leaderboard();
              setState(() => _future = next);
              await next;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: players.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = players[i];
                final medal = switch (i) {
                  0 => const Color(0xFFFACC15),
                  1 => const Color(0xFFCBD5E1),
                  2 => const Color(0xFFD97706),
                  _ => null,
                };
                return Card(
                  color: p.id == me ? AppColors.surfaceHigh : null,
                  child: ListTile(
                    leading: SizedBox(
                      width: 84,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: medal ?? AppColors.muted),
                            ),
                          ),
                          Avatar(name: p.name, url: p.avatarUrl, size: 44, ring: medal),
                        ],
                      ),
                    ),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${p.gamesPlayed} parties · ${p.wins} victoires'),
                    trailing: Text(
                      '${p.totalPoints} pts',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
