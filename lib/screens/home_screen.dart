import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import 'rules_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final code = await showDialog<String>(context: context, builder: (_) => const _JoinDialog());
    if (code == null || !mounted) return;
    await _run(() => context.read<AppState>().joinRoom(code));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final player = state.player!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('IMPOSTEUR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4)),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Règles',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RulesScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (!state.connected)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.sync, color: AppColors.warning, size: 18),
                    SizedBox(width: 10),
                    Expanded(child: Text('Connexion au serveur...')),
                  ],
                ),
              ),
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Avatar(name: player.name, url: player.avatarUrl, size: 64, ring: AppColors.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player.name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${player.totalPoints} pts  ·  ${player.gamesPlayed} parties  ·  ${player.wins} victoires',
                              style: const TextStyle(color: AppColors.muted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.muted),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _ActionTile(
              icon: Icons.add_circle_outline,
              color: AppColors.primary,
              title: 'Créer une partie',
              subtitle: 'Invitez vos amis avec un code',
              onTap: _busy || !state.connected ? null : () => _run(() => state.createRoom()),
            ),
            const SizedBox(height: 14),
            _ActionTile(
              icon: Icons.login,
              color: const Color(0xFF06B6D4),
              title: 'Rejoindre une partie',
              subtitle: 'Entrez le code reçu',
              onTap: _busy || !state.connected ? null : _join,
            ),
            const SizedBox(height: 14),
            _ActionTile(
              icon: Icons.emoji_events_outlined,
              color: AppColors.warning,
              title: 'Classement',
              subtitle: 'Les meilleurs joueurs',
              onTap: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JoinDialog extends StatefulWidget {
  const _JoinDialog();

  @override
  State<_JoinDialog> createState() => _JoinDialogState();
}

class _JoinDialogState extends State<_JoinDialog> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _code.text.trim().toUpperCase();
    if (code.length < 4) return;
    Navigator.pop(context, code);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rejoindre une partie'),
      content: TextField(
        controller: _code,
        autofocus: true,
        maxLength: 8,
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]'))],
        style: const TextStyle(fontSize: 26, letterSpacing: 8, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(hintText: 'CODE', counterText: ''),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        TextButton(onPressed: _submit, child: const Text('Rejoindre')),
      ],
    );
  }
}
