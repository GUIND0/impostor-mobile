import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import '../widgets/photo_picker.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _name = TextEditingController();
  String? _photo;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final path = await pickProfilePhoto(context);
    if (path != null) setState(() => _photo = path);
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.length < 2) {
      showError(context, 'Choisissez un nom d’au moins 2 caractères');
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AppState>().createProfile(name, _photo);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Text(
                  'IMPOSTEUR',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 6),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Qui parmi vous ne connaît pas le mot ?',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: _saving ? null : _pick,
                  child: Stack(
                    children: [
                      ValueListenableBuilder(
                        valueListenable: _name,
                        builder: (context, value, _) => Avatar(
                          name: value.text.isEmpty ? '?' : value.text,
                          localPath: _photo,
                          size: 120,
                          ring: AppColors.primary,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.photo_camera, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Ajoutez une photo', style: TextStyle(color: AppColors.muted)),
                const SizedBox(height: 32),
                TextField(
                  controller: _name,
                  maxLength: 20,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Votre nom',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Créer mon profil'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
