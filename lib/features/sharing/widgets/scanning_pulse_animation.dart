import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Widget animasi lingkaran pulse yang memancar keluar dari tengah.
/// Reusable — bisa digunakan di berbagai scanning/searching screen.
///
/// Parameters:
/// - [child] : widget yang ditampilkan di pusat animasi (biasanya icon)
/// - [color] : warna ring pulse (default biru)
/// - [ringCount] : jumlah ring yang bergerak (default 3)
/// - [size] : ukuran area keseluruhan animasi (default 220)
/// - [centerSize] : ukuran lingkaran pusat tempat [child] berada (default 72)
class ScanningPulseAnimation extends StatefulWidget {
  final Widget child;
  final Color color;
  final int ringCount;
  final double size;
  final double centerSize;

  const ScanningPulseAnimation({
    super.key,
    required this.child,
    this.color = const Color(0xFF0066FF),
    this.ringCount = 3,
    this.size = 220,
    this.centerSize = 72,
  });

  @override
  State<ScanningPulseAnimation> createState() =>
      _ScanningPulseAnimationState();
}

class _ScanningPulseAnimationState extends State<ScanningPulseAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Pulse rings (dibalik agar ring luar render dulu) ──
          ...List.generate(widget.ringCount, (i) {
            // Setiap ring punya delay berbeda agar efek merambat
            final delay = i / widget.ringCount;
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Offset animasi sesuai delay tiap ring
                final raw = (_controller.value + delay) % 1.0;
                // Easing: mulai lambat, habis cepat
                final progress = Curves.easeOut.transform(raw);

                final maxRadius = widget.size / 2;
                final minRadius = widget.centerSize / 2 + 4;
                final radius = minRadius + (maxRadius - minRadius) * progress;

                // Opacity: muncul di awal lalu fade out di akhir
                final opacity = math.sin(progress * math.pi).clamp(0.0, 1.0);

                return Container(
                  width: radius * 2,
                  height: radius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color.withValues(alpha: opacity * 0.25),
                      width: 1.5,
                    ),
                  ),
                );
              },
            );
          }),

          // ── Lingkaran pusat ──
          Container(
            width: widget.centerSize,
            height: widget.centerSize,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
