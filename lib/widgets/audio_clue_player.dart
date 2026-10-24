import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../config.dart';
import '../theme.dart';

class AudioCluePlayer extends StatefulWidget {
  final String url;
  final int durationMs;

  const AudioCluePlayer({super.key, required this.url, required this.durationMs});

  @override
  State<AudioCluePlayer> createState() => _AudioCluePlayerState();
}

class _AudioCluePlayerState extends State<AudioCluePlayer> {
  final _player = AudioPlayer();
  final _subs = <StreamSubscription>[];
  PlayerState _state = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration? _duration;

  @override
  void initState() {
    super.initState();
    _subs.add(
      _player.onPlayerStateChanged.listen((s) {
        if (mounted) setState(() => _state = s);
      }),
    );
    _subs.add(
      _player.onPositionChanged.listen((p) {
        if (mounted) setState(() => _position = p);
      }),
    );
    _subs.add(
      _player.onDurationChanged.listen((d) {
        if (mounted) setState(() => _duration = d);
      }),
    );
    _subs.add(
      _player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _position = Duration.zero);
      }),
    );
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    try {
      if (_state == PlayerState.playing) {
        await _player.pause();
      } else if (_state == PlayerState.paused) {
        await _player.resume();
      } else {
        await _player.play(UrlSource(AppConfig.media(widget.url)!));
      }
    } catch (_) {
      if (mounted) showError(context, 'Lecture du vocal impossible');
    }
  }

  String _fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final total = _duration ?? Duration(milliseconds: widget.durationMs);
    final progress = total.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    final playing = _state == PlayerState.playing;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filled(
          onPressed: _toggle,
          icon: Icon(playing ? Icons.pause : Icons.play_arrow),
          style: IconButton.styleFrom(backgroundColor: AppColors.primary),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 110,
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: AppColors.surfaceHigh,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _fmt(playing || _position > Duration.zero ? _position : total),
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}
