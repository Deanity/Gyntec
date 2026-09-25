import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../utils/models.dart';

/// Card pertanyaan interaktif untuk Quiz:
/// - Label nomor soal (e.g. Pertanyaan 1/30)
/// - Judul pertanyaan
/// - Pilihan ganda dengan seleksi interaktif (opsi terpilih berwarna biru dengan checkmark)
/// - Divider dan tombol navigasi "Sebelumnya" & "Selanjutnya" di dalam card
class QuizInteractiveCard extends StatelessWidget {
  final QuizQuestionModel question;
  final int currentIndex;
  final int totalQuestions;
  final int? selectedOptionIndex;
  final ValueChanged<int> onSelectOption;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const QuizInteractiveCard({
    super.key,
    required this.question,
    required this.currentIndex,
    required this.totalQuestions,
    required this.selectedOptionIndex,
    required this.onSelectOption,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nomor pertanyaan (e.g. Pertanyaan 1/30)
          Text(
            'Pertanyaan ${currentIndex + 1}/$totalQuestions',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),

          // Teks pertanyaan
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Daftar opsi jawaban
          ...question.options.asMap().entries.map((entry) {
            final idx = entry.key;
            final text = entry.value;
            final isSelected = selectedOptionIndex == idx;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => onSelectOption(idx),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0066FF)
                        : const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF0066FF)
                          : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (isSelected) ...[
                        const Icon(
                          LucideIcons.circleCheck,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 8),
          const Divider(color: Color(0xFFE2E8F0), height: 1),
          const SizedBox(height: 16),

          // Tombol Navigasi: Sebelumnya & Selanjutnya
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: onPrevious,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      foregroundColor: const Color(0xFF0F172A),
                    ),
                    child: const Text(
                      'Sebelumnya',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: onNext,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      foregroundColor: const Color(0xFF0F172A),
                    ),
                    child: const Text(
                      'Selanjutnya',
                      style: TextStyle(
                        fontSize: 14,
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
    );
  }
}
