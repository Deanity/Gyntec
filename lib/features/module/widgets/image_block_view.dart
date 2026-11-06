import 'dart:io';
import 'package:flutter/material.dart';

/// Blok gambar materi full-width dengan border radius dan shadow tipis (ImageBlockView).
/// Mendukung path assets lokal maupun path file sistem di storage perangkat.
class ImageBlockView extends StatelessWidget {
  final String assetPath;

  const ImageBlockView({super.key, required this.assetPath});

  @override
  Widget build(BuildContext context) {
    final bool isAsset = assetPath.startsWith('assets/');

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: isAsset
          ? Image.asset(
              assetPath,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
            )
          : Image.file(
              File(assetPath),
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
            ),
    );
  }

  Widget _buildErrorWidget() {
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
  }
}

/// Backward compatibility alias
typedef MateriImageBlock = ImageBlockView;
