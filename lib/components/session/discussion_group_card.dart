import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../utils/models.dart';

/// Card untuk menampilkan satu kelompok hasil pembagian otomatis
/// beserta daftar anggota kelompok dengan icon profil.
class DiscussionGroupCard extends StatelessWidget {
  final int groupNumber;
  final String groupName;
  final List<StudentModel> members;

  const DiscussionGroupCard({
    super.key,
    required this.groupNumber,
    required this.groupName,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label nomor kelompok
          Text(
            'Kelompok $groupNumber',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),

          // Nama kelompok (e.g. Kelompok Rajawali)
          Text(
            groupName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          // Daftar anggota kelompok
          ...members.map(
            (student) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.userRound,
                    size: 17,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
