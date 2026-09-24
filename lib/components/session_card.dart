import 'package:flutter/material.dart';
import '../utils/models.dart';
import 'level_badge.dart';

/// Kartu sesi belajar untuk horizontal scroll list di Home Screen.
/// Menampilkan tanggal, level, judul, jumlah siswa, mapel, dan durasi.
class SessionCard extends StatelessWidget {
  final SessionModel session;
  final VoidCallback? onTap;

  const SessionCard({
    super.key,
    required this.session,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 230,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris tanggal + badge level
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  session.date,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                LevelBadge(level: session.level),
              ],
            ),
            const SizedBox(height: 8),

            // Judul sesi
            Text(
              session.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),

            // Stat row: siswa | mapel | menit
            Row(
              children: [
                _StatChip(value: '${session.studentCount}', label: 'Siswa hadir'),
                const SizedBox(width: 8),
                _StatChip(value: session.subject, label: 'Mapel'),
                const SizedBox(width: 8),
                _StatChip(value: '${session.durationMinutes}', label: 'Menit'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip statistik kecil di dalam SessionCard.
class _StatChip extends StatelessWidget {
  final String value;
  final String label;

  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
