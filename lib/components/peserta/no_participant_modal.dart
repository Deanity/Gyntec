import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Floating modal popup yang tampil ketika user mencoba memulai sesi
/// tanpa menambahkan peserta terlebih dahulu.
/// Desain sesuai gaya QuizFinishModal: floating card melayang dengan shadow,
/// border radius penuh, icon, judul, deskripsi, dan satu tombol aksi.
class NoParticipantModal extends StatelessWidget {
  final VoidCallback onClose;

  const NoParticipantModal({
    super.key,
    required this.onClose,
  });

  /// Helper statis untuk menampilkan modal
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x3D000000),
      elevation: 0,
      isScrollControlled: true,
      builder: (context) => NoParticipantModal(
        onClose: () => Navigator.of(context).pop(),
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
              // Icon container dengan background merah lembut
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFECACA),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.userRoundX,
                    size: 26,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Judul
              const Text(
                'Belum Ada Peserta',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),

              // Deskripsi
              const Text(
                'Tambahkan minimal 1 peserta sebelum memulai sesi pembelajaran.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),

              // Tombol Tambah Peserta
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onClose,
                  icon: const Icon(LucideIcons.userRoundPlus, size: 18),
                  label: const Text(
                    'Tambah Peserta',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
