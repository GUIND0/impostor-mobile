import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config.dart';
import '../theme.dart';

class Avatar extends StatelessWidget {
  final String name;
  final String? url;
  final String? localPath;
  final double size;
  final Color? ring;
  final bool dimmed;

  const Avatar({
    super.key,
    required this.name,
    this.url,
    this.localPath,
    this.size = 48,
    this.ring,
    this.dimmed = false,
  });

  Color get _color {
    const palette = [
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
      Color(0xFFF97316),
      Color(0xFF10B981),
      Color(0xFFEC4899),
      Color(0xFF3B82F6),
      Color(0xFFEAB308),
    ];
    return palette[name.codeUnits.fold<int>(0, (a, b) => a + b) % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0].toUpperCase()).join();
    final fallback = Container(
      color: _color,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: size * 0.38),
      ),
    );
    Widget image;
    final remote = AppConfig.media(url);
    if (localPath != null) {
      image = Image.file(File(localPath!), fit: BoxFit.cover);
    } else if (remote != null) {
      image = CachedNetworkImage(
        imageUrl: remote,
        fit: BoxFit.cover,
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      );
    } else {
      image = fallback;
    }
    return Opacity(
      opacity: dimmed ? 0.4 : 1,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(ring != null ? 2.5 : 0),
        decoration: BoxDecoration(shape: BoxShape.circle, color: ring ?? AppColors.surfaceHigh),
        child: ClipOval(child: SizedBox.expand(child: image)),
      ),
    );
  }
}
