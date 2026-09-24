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
      ),
    );
  }
}
