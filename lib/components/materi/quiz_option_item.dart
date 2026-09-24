import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Satu item pilihan jawaban quiz.
/// [isSelected] = dipilih user, [isCorrect] = jawaban benar (untuk review mode).
class QuizOptionItem extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback? onTap;

  const QuizOptionItem({
    super.key,
    required this.text,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0066FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0066FF)
                : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                LucideIcons.circleCheck,
                size: 18,
                color: Colors.white,
              ),
          ],
        ),
      ),
    );
  }
}
