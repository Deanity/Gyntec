import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Banner yang tampil saat aplikasi berjalan dalam mode luring (offline).
/// Menampilkan ikon, judul, deskripsi, dan jumlah modul tersimpan.
class OfflineBannerCard extends StatelessWidget {
  final String title;
  final String description;
  final int savedModules;

  const OfflineBannerCard({
    super.key,
    required this.title,
    required this.description,
    required this.savedModules,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDCF), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF1DB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.wifiOff,
                  size: 20,
                  color: Color(0xFF6B7C2D),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3D4A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7C2D),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$savedModules Modul Tersimpan',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D4A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
