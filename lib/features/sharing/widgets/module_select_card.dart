import 'package:flutter/material.dart';
import '../../../utils/models.dart';

/// Card modul yang bisa dipilih (selectable) untuk flow pengiriman modul.
/// Reusable — bisa digunakan di screen mana saja yang butuh multi-select modul.
///
/// Parameters:
/// - [module] : data modul yang ditampilkan
/// - [isSelected] : apakah card ini dalam state terpilih
/// - [onTap] : callback saat card ditekan
class ModuleSelectCard extends StatelessWidget {
  final ModuleModel module;
  final bool isSelected;
  final VoidCallback onTap;

  const ModuleSelectCard({
    super.key,
    required this.module,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0066FF)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Info modul (kiri, mengisi sisa ruang) ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul
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

                  // Deskripsi singkat
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

                  // Badge row
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Badge(label: module.level, isCardSelected: isSelected),
                      _Badge(label: module.subject, isCardSelected: isSelected),
                      _Badge(
                        label: '${module.totalQuestions} Soal',
                        isCardSelected: isSelected,
                      ),
                      _Badge(
                        label: '${module.discussionCount} Diskusi',
                        isCardSelected: isSelected,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // ── Checkbox (kanan, center vertikal) ──
            _Checkbox(isSelected: isSelected),
          ],
        ),
      ),
    );
  }
}

// ── Badge pill kecil ──
class _Badge extends StatelessWidget {
  final String label;
  final bool isCardSelected;
  const _Badge({required this.label, this.isCardSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isCardSelected ? Colors.white : const Color(0xFFF0F7FF),
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

// ── Animated checkbox ──
class _Checkbox extends StatelessWidget {
  final bool isSelected;
  const _Checkbox({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF0066FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF0066FF)
              : const Color(0xFF334155),
          width: 2.0,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }
}
