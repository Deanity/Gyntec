import 'package:flutter/material.dart';

/// Menampilkan status scanning: animasi icon + judul + sub-teks.
/// Reusable — bisa digunakan untuk state "mencari", "menghubungkan", dll.
///
/// Parameters:
/// - [animationWidget] : widget animasi di atas (biasanya ScanningPulseAnimation)
/// - [title] : teks judul status (e.g. "Mencari perangkat terdekat...")
/// - [subtitle] : teks petunjuk di bawah judul
class ScanningStatusView extends StatelessWidget {
  final Widget animationWidget;
  final String title;
  final String subtitle;

  const ScanningStatusView({
    super.key,
    required this.animationWidget,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animasi
        animationWidget,
        const SizedBox(height: 32),

        // Judul status
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),

        // Sub-teks petunjuk
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF94A3B8),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
