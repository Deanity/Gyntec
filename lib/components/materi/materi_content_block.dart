import 'package:flutter/material.dart';

/// Blok konten materi: heading judul bagian + paragraf teks.
/// Reusable untuk setiap bagian materi dalam modul
class MateriContentBlock extends StatelessWidget {
  final String heading;
  final String body;

  const MateriContentBlock({
    super.key,
    required this.heading,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF475569),
            height: 1.7,
          ),
        ),
      ],
    );
  }
}
