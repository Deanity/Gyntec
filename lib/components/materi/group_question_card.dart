import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kartu pertanyaan kelompok dengan judul, petunjuk pengerjaan, dan indikator penilaian.
/// Reusable untuk berbagai modul yang memiliki aktivitas diskusi kelompok
class GroupQuestionCard extends StatelessWidget {
  final String title;
  final List<String> instructions;
  final List<String> indicators;

  const GroupQuestionCard({
    super.key,
    required this.title,
    required this.instructions,
    required this.indicators,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label "Pertanyaan Kelompok"
          Row(
            children: [
              const Icon(
                LucideIcons.users,
                size: 14,
                color: Color(0xFF0066FF),
              ),
              const SizedBox(width: 6),
              const Text(
                'Pertanyaan Kelompok',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0066FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Judul pertanyaan
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Petunjuk Pengerjaan
          _SectionLabel(label: 'Petunjuk Pengerjaan'),
          const SizedBox(height: 8),
          ...instructions.asMap().entries.map(
                (e) => _NumberedItem(
                  number: e.key + 1,
                  text: e.value,
                ),
              ),
          const SizedBox(height: 16),

          // Indikator Penilaian
          _SectionLabel(label: 'Indikator Penilaian'),
          const SizedBox(height: 8),
          ...indicators.asMap().entries.map(
                (e) => _NumberedItem(
                  number: e.key + 1,
                  text: e.value,
                ),
              ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    );
  }
}

class _NumberedItem extends StatelessWidget {
  final int number;
  final String text;
  const _NumberedItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
