import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'models/room.dart';
import 'screens/game/game_screen.dart';
import 'screens/home_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'services/app_state.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(ChangeNotifierProvider(create: (_) => AppState()..init(), child: const ImpostorApp()));
}

class ImpostorApp extends StatelessWidget {
  const ImpostorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Imposteur',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const RootGate(),
    );
  }
}

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    Widget child;
    if (!state.ready) {
      child = const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (state.player == null && state.startupError != null) {
      child = _StartupError(message: state.startupError!);
    } else if (state.player == null) {
      child = const ProfileSetupScreen();
    } else if (state.room == null) {
      child = const HomeScreen();
    } else if (state.room!.phase == Phase.lobby) {
      child = const LobbyScreen();
    } else {
      child = const GameScreen();
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: KeyedSubtree(key: ValueKey(child.runtimeType), child: child),
    );
  }
}

class _StartupError extends StatelessWidget {
  final String message;

  const _StartupError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 56, color: AppColors.muted),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(onPressed: () => context.read<AppState>().init(), child: const Text('Réessayer')),
            ],
          ),
        ),
      ),
    );
  }
}
