import 'package:flutter/material.dart';

/// Badge level pendidikan (SMA, SMP, SMK, SD) dengan warna berbeda per level.
/// Digunakan di SessionCard dan ModuleListItem.
class LevelBadge extends StatelessWidget {
  final String level;

  const LevelBadge({super.key, required this.level});

  /// Warna latar & teks berdasarkan level
  (Color bg, Color text) get _colors => switch (level.toUpperCase()) {
        'SMA' => (const Color(0xFFEFF6FF), const Color(0xFF0066FF)),
        'SMP' => (const Color(0xFFF0FDF4), const Color(0xFF16A34A)),
        'SMK' => (const Color(0xFFFFF7ED), const Color(0xFFEA580C)),
        'SD'  => (const Color(0xFFFDF4FF), const Color(0xFF9333EA)),
        _     => (const Color(0xFFF1F5F9), const Color(0xFF475569)),
      };

  @override
  Widget build(BuildContext context) {
    final (bg, text) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        level.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: text,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
