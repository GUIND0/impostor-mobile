import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../services/app_state.dart';
import '../theme.dart';

class ClueComposer extends StatefulWidget {
  const ClueComposer({super.key});

  @override
  State<ClueComposer> createState() => _ClueComposerState();
}

class _ClueComposerState extends State<ClueComposer> {
  static const maxRecording = Duration(seconds: 30);

  final _controller = TextEditingController();
  final _recorder = AudioRecorder();
  bool _recording = false;
  bool _sending = false;
  DateTime? _startedAt;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await context.read<AppState>().sendTextClue(text);
      _controller.clear();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _startRecording() async {
    if (_sending) return;
    if (!await _recorder.hasPermission()) {
      if (mounted) showError(context, "Autorisez l'accès au micro pour envoyer un vocal");
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/clue_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000, sampleRate: 44100, numChannels: 1),
      path: path,
    );
    _startedAt = DateTime.now();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      if (DateTime.now().difference(_startedAt!) >= maxRecording) {
        _stopAndSend();
      } else {
        setState(() {});
      }
    });
    setState(() => _recording = true);
  }

  Future<void> _cancelRecording() async {
    _ticker?.cancel();
    await _recorder.cancel();
    if (mounted) setState(() => _recording = false);
  }

  Future<void> _stopAndSend() async {
    if (!_recording) return;
    _ticker?.cancel();
    final duration = DateTime.now().difference(_startedAt!);
    final path = await _recorder.stop();
    setState(() {
      _recording = false;
      _sending = true;
    });
    try {
      if (path == null) throw "L'enregistrement a échoué";
      if (duration.inMilliseconds < 700) throw 'Vocal trop court';
      if (!mounted) return;
      await context.read<AppState>().sendAudioClue(path, duration.inMilliseconds);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_recording) {
      final elapsed = DateTime.now().difference(_startedAt!);
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            IconButton(
              onPressed: _cancelRecording,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Annuler',
            ),
            const Icon(Icons.fiber_manual_record, color: AppColors.imposter, size: 14),
            const SizedBox(width: 8),
            Text(
              '0:${elapsed.inSeconds.toString().padLeft(2, '0')} / 0:${maxRecording.inSeconds}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            IconButton.filled(
              onPressed: _stopAndSend,
              icon: const Icon(Icons.send),
              tooltip: 'Envoyer le vocal',
            ),
          ],
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            enabled: !_sending,
            maxLength: 120,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendText(),
            decoration: const InputDecoration(hintText: 'Votre indice...', counterText: ''),
          ),
        ),
        const SizedBox(width: 8),
        if (_sending)
          const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, value, _) => value.text.trim().isEmpty
                ? IconButton.filled(
                    onPressed: _startRecording,
                    icon: const Icon(Icons.mic),
                    tooltip: 'Enregistrer un vocal',
                  )
                : IconButton.filled(
                    onPressed: _sendText,
                    icon: const Icon(Icons.send),
                    tooltip: "Envoyer l'indice",
                  ),
          ),
      ],
    );
  }
}
