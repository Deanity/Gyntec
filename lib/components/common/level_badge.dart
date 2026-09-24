import 'package:flutter/material.dart';

/// Badge level pendidikan (SMA, SMP, SMK, SD) — satu tema biru sesuai warna apps.
/// Digunakan di SessionCard dan ModuleListItem.
class LevelBadge extends StatelessWidget {
  final String level;

  const LevelBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        level.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0066FF),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
