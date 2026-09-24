import 'package:flutter/material.dart';
import '../../utils/models.dart';
import 'quiz_option_item.dart';

/// Kartu satu pertanyaan quiz dengan nomor, pertanyaan, dan daftar pilihan.
/// Mengelola state jawaban yang dipilih secara internal.
class QuizQuestionCard extends StatefulWidget {
  final QuizQuestionModel question;

  const QuizQuestionCard({super.key, required this.question});

  @override
  State<QuizQuestionCard> createState() => _QuizQuestionCardState();
}

class _QuizQuestionCardState extends State<QuizQuestionCard> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nomor pertanyaan
        Text(
          'Pertanyaan ${q.number}/${q.totalQuestions}',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),

        // Teks pertanyaan
        Text(
          q.question,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),

        // Pilihan jawaban
        ...q.options.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: QuizOptionItem(
                  text: e.value,
                  isSelected: _selectedIndex == e.key,
                  onTap: () => setState(() => _selectedIndex = e.key),
                ),
              ),
            ),
      ],
    );
  }
}
