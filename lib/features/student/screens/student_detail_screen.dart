import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/level_badge.dart';
import '../../session/models/student_model.dart';
import '../../session/models/session_model.dart';

/// Halaman detail murid — menampilkan profil singkat dan riwayat sesi belajar
/// yang pernah diikuti oleh murid tersebut.
class StudentDetailScreen extends StatelessWidget {
  final StudentModel student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar custom dengan back button & judul
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        LucideIcons.chevronLeft,
                        size: 22,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(
                      'Detail Murid',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Avatar + nama + subtitle "Mengikuti X Sesi"
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Column(
                children: [
                  // Avatar circle
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: const Icon(
                      LucideIcons.user,
                      size: 32,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Nama murid
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Subtitle jumlah sesi
                  Text(
                    'Mengikuti ${student.sessionCount} Sesi',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),

          // Header "Sesi belajar yang diikuti"
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Sesi belajar yang diikuti',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // List sesi atau empty state
          student.sessions.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 40),
                        Icon(
                          LucideIcons.calendarX,
                          size: 40,
                          color: AppColors.textPlaceholder,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum mengikuti sesi apapun',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textPlaceholder,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: student.sessions.length,
                    separatorBuilder: (_, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _SessionHistoryCard(session: student.sessions[index]),
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widget
// ---------------------------------------------------------------------------

/// Card riwayat sesi belajar dalam halaman detail murid.
/// Menampilkan: tanggal + badge level, judul sesi, dan 3 stat chip (siswa/mapel/menit).
class _SessionHistoryCard extends StatelessWidget {
  final SessionModel session;

  const _SessionHistoryCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris atas: tanggal + badge level
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                session.date,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textPlaceholder,
                  fontWeight: FontWeight.w500,
                ),
              ),
              LevelBadge(level: session.level),
            ],
          ),
          const SizedBox(height: 6),

          // Judul sesi
          Text(
            session.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),

          // Stat row: siswa | mapel | menit
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  value: '${session.studentCount}',
                  label: 'Siswa hadir',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(value: session.subject, label: 'Mapel'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  value: '${session.durationMinutes}',
                  label: 'Menit',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chip statistik kecil — value tebal di atas, label abu-abu di bawah.
class _StatChip extends StatelessWidget {
  final String value;
  final String label;

  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textPlaceholder,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
