import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';

class Countdown extends StatefulWidget {
  final DateTime? deadline;
  final int totalSeconds;

  const Countdown({super.key, required this.deadline, required this.totalSeconds});

  @override
  State<Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deadline = widget.deadline;
    if (deadline == null) return const SizedBox.shrink();
    final remaining = deadline.difference(DateTime.now());
    final seconds = remaining.isNegative ? 0 : (remaining.inMilliseconds / 1000).ceil();
    final ratio = widget.totalSeconds <= 0
        ? 0.0
        : (remaining.inMilliseconds / (widget.totalSeconds * 1000)).clamp(0.0, 1.0);
    final color = seconds <= 10 ? AppColors.imposter : AppColors.primary;
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: ratio,
            strokeWidth: 4,
            color: color,
            backgroundColor: AppColors.surfaceHigh,
          ),
          Text(
            '$seconds',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
