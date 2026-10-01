import 'package:flutter/material.dart';
import '../../utils/models.dart';

/// Card preview modul yang sedang / akan dikirim.
/// Ditampilkan di bagian "Module yang Dikirim" pada screen pemilihan perangkat
/// dan screen progress pengiriman.
///
/// Parameters:
/// - [module] : data modul yang ditampilkan
/// - [subtitle] : label di bagian atas (default "Dokumen pilihan Anda")
class ModulePreviewCard extends StatelessWidget {
  final ModuleModel module;
  final String subtitle;
  final bool showDiscussionBadge;

  const ModulePreviewCard({
    super.key,
    required this.module,
    this.subtitle = 'Dokumen pilihan Anda',
    this.showDiscussionBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle atas ("Dokumen pilihan Anda" atau "Dibagikan oleh...")
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),

          // Judul Modul
          Text(
            module.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),

          // Deskripsi singkat (truncate 1 baris)
          Text(
            module.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),

          // Badge row: Level, Subject, Soal, (+ Diskusi jika showDiscussionBadge)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _PreviewBadge(label: module.level),
              _PreviewBadge(label: module.subject),
              _PreviewBadge(label: '${module.totalQuestions} Soal'),
              if (showDiscussionBadge)
                _PreviewBadge(label: '${module.discussionCount} Diskusi'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewBadge extends StatelessWidget {
  final String label;
  const _PreviewBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF93C5FD), width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0066FF),
        ),
      ),
    );
  }
}
