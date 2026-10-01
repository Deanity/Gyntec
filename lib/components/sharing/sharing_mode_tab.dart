import 'package:flutter/material.dart';

/// Enum mode berbagi modul.
enum SharingMode { terima, kirim }

/// Bottom tab switcher "Terima / Kirim" untuk sharing flow.
/// Reusable — bisa digunakan di screen mana saja yang membutuhkan
/// toggle mode dengan dua opsi pill.
///
/// Parameters:
/// - [activeMode] : mode yang sedang aktif
/// - [onModeChanged] : callback saat mode berubah
/// - [labels] : optional override teks label [terima, kirim]
class SharingModeTab extends StatelessWidget {
  final SharingMode activeMode;
  final ValueChanged<SharingMode> onModeChanged;
  final List<String> labels;

  const SharingModeTab({
    super.key,
    required this.activeMode,
    required this.onModeChanged,
    this.labels = const ['Terima', 'Kirim'],
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _TabItem(
                label: labels[0],
                isActive: activeMode == SharingMode.terima,
                onTap: () => onModeChanged(SharingMode.terima),
              ),
              _TabItem(
                label: labels[1],
                isActive: activeMode == SharingMode.kirim,
                onTap: () => onModeChanged(SharingMode.kirim),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Item individual tiap tab ──
class _TabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0066FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            boxShadow: isActive
                ? [
                    const BoxShadow(
                      color: Color(0x330066FF),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              fontSize: 14,
              fontWeight:
                  isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? Colors.white : const Color(0xFF64748B),
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
