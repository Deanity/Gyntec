import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../session/models/student_model.dart';

/// Card item untuk satu murid dalam list Murid / Peserta Sesi.
/// Menampilkan: icon user, nama murid, dan jumlah sesi yang telah diikuti.
class StudentListItem extends StatelessWidget {
  final StudentModel student;
  final VoidCallback? onTap;

  const StudentListItem({
    super.key,
    required this.student,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(48),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            // Icon user
            Icon(
              LucideIcons.user,
              size: 20,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 12),

            // Nama murid
            Expanded(
              child: Text(
                student.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Jumlah sesi
            Text(
              '${student.sessionCount} Sesi',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
