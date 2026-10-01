import 'package:flutter/material.dart';

/// Menampilkan judul section dan link "Lihat semua" di sebelah kanan.
/// Digunakan berulang di Home Screen (Sesi Belajar Terakhir, Modul Pembelajaran, dll.)
class SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback? onActionTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel = 'Lihat semua',
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        if (onActionTap != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0066FF),
              ),
            ),
          ),
      ],
    );
  }
}
