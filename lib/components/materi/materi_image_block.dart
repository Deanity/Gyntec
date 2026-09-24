import 'package:flutter/material.dart';

/// Blok gambar materi full-width dengan border radius dan shadow tipis.
/// Menerima path asset lokal.
class MateriImageBlock extends StatelessWidget {
  final String assetPath;

  const MateriImageBlock({super.key, required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.asset(
        assetPath,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading asset image "$assetPath": $error');
          return Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.broken_image_outlined,
                  color: Color(0xFF94A3B8),
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  'Gagal memuat: $assetPath',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
