import 'package:flutter/material.dart';

/// Badge informasi modul untuk ParticipantScreen (contoh: SMA, IPA, 30 Soal, 1 Diskusi).
/// Desain: Background putih, border biru lembut, teks biru.
class ParticipantBadge extends StatelessWidget {
  final String label;

  const ParticipantBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF93C5FD), // blue-300
          width: 1.0,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0066FF),
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
