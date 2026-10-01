import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Modal popup konfirmasi penyelesaian quiz berbentuk Floating Component
/// sesuai UI "Quiz Finish.png":
/// - Floating card melayang di atas batas bawah layar dengan border radius penuh (24)
/// - Icon User di bagian atas
/// - Judul: "Selesaikan Quiz?"
/// - Deskripsi: "Masih ada X soal yang belum terjawab. Sesi akan berakhir dan tercatat."
/// - Dua tombol aksi: "Selesai" (kiri, outline) dan "Batal" (kanan, warna biru)
class QuizFinishModal extends StatelessWidget {
  final int unansweredCount;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const QuizFinishModal({
    super.key,
    required this.unansweredCount,
    required this.onConfirm,
    required this.onCancel,
  });

  /// Helper statis untuk menampilkan modal popup floating
  static Future<bool?> show(
    BuildContext context, {
    required int unansweredCount,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x3D000000),
      elevation: 0,
      isScrollControlled: true,
      builder: (context) => QuizFinishModal(
        unansweredCount: unansweredCount,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Profil di bagian atas
              const Icon(
                LucideIcons.userRound,
                size: 38,
                color: Color(0xFF1E293B),
              ),
              const SizedBox(height: 14),

              // Judul Modal
              const Text(
                'Selesaikan Quiz?',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),

              // Deskripsi soal belum terjawab
              Text(
                unansweredCount > 0
                    ? 'Masih ada $unansweredCount soal yang belum terjawab. Sesi akan berakhir dan tercatat.'
                    : 'Semua soal telah terjawab. Sesi akan berakhir dan tercatat.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),

              // Row Tombol Selesai & Batal
              Row(
                children: [
                  // Tombol Selesai (Kiri - Outlined)
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: onConfirm,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFFCBD5E1),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          foregroundColor: const Color(0xFF0F172A),
                        ),
                        child: const Text(
                          'Selesai',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Tombol Batal (Kanan - Blue Fill)
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: onCancel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
