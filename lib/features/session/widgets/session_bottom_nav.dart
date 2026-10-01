import 'package:flutter/material.dart';
import '../../../core/core.dart';

/// Bottom bar navigasi untuk alur Sesi Pembelajaran:
/// - Pill segment tab switcher (Materi, Diskusi, Quiz) di tengah
/// - Tombol aksi utama (e.g., "Sesi Selanjutnya", "Mulai diskusi kelompok", "Selesaikan quiz")
class SessionBottomNav extends StatelessWidget {
  final int currentStep; // 1 = Materi, 2 = Diskusi, 3 = Quiz
  final ValueChanged<int> onStepChanged;
  final VoidCallback onActionPressed;
  final String actionLabel;
  final bool isLoading;

  const SessionBottomNav({
    super.key,
    required this.currentStep,
    required this.onStepChanged,
    required this.onActionPressed,
    required this.actionLabel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pill capsule tab switcher — floating, no background container
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTab(1, 'Materi'),
                    _buildTab(2, 'Diskusi'),
                    _buildTab(3, 'Quiz'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tombol Aksi Utama — floating dengan blue glow shadow
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x330066FF),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: AppButton(
                label: actionLabel,
                onPressed: onActionPressed,
                isLoading: isLoading,
                backgroundColor: const Color(0xFF0066FF),
                borderRadius: 28,
                height: 52,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int step, String label) {
    final isActive = currentStep == step;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onStepChanged(step),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0066FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
