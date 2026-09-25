import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Top App Bar dengan tombol back, judul bagian (step),
/// dan 3-step circular progress stepper indicator.
class SessionStepperHeader extends StatelessWidget {
  final int currentStep; // 1, 2, or 3
  final String title;
  final VoidCallback? onBack;

  const SessionStepperHeader({
    super.key,
    required this.currentStep,
    required this.title,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row navigasi back dan judul
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onBack ?? () => Navigator.of(context).maybePop(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        LucideIcons.chevronLeft,
                        size: 22,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Stepper Indicator (1 - 2 - 3)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              child: Row(
                children: [
                  _buildStepNode(1),
                  _buildConnector(1),
                  _buildStepNode(2),
                  _buildConnector(2),
                  _buildStepNode(3),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildStepNode(int step) {
    final isCompleted = currentStep > step;
    final isCurrent = currentStep == step;

    if (isCompleted) {
      // Completed: solid blue circle with white check
      return Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: Color(0xFF0066FF),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            LucideIcons.check,
            size: 13,
            color: Colors.white,
            weight: 3,
          ),
        ),
      );
    } else if (isCurrent) {
      // Current: step 1 in design is solid blue circle with '1', step 2 & 3 have blue ring with number
      if (step == 1) {
        return Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Color(0xFF0066FF),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              '1',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
        );
      } else {
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF0066FF),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '$step',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0066FF),
                height: 1,
              ),
            ),
          ),
        );
      }
    } else {
      // Upcoming: grey outline circle with grey number
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFCBD5E1),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            '$step',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
              height: 1,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildConnector(int step) {
    // If currentStep is beyond this step, the connector line is blue, else grey
    final isDone = currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        color: isDone ? const Color(0xFF0066FF) : const Color(0xFFE2E8F0),
      ),
    );
  }
}
