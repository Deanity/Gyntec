import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Widget animasi lingkaran radar/pulse yang memancar keluar dari tengah.
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
      duration: const Duration(milliseconds: 2000),
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
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _PulsePainter(
              progress: _controller.value,
              color: widget.color,
              ringCount: widget.ringCount,
              centerSize: widget.centerSize,
            ),
            child: Center(
              child: Container(
                width: widget.centerSize,
                height: widget.centerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(child: widget.child),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  final double progress;
  final Color color;
  final int ringCount;
  final double centerSize;

  _PulsePainter({
    required this.progress,
    required this.color,
    required this.ringCount,
    required this.centerSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    final minRadius = centerSize / 2;

    for (int i = 0; i < ringCount; i++) {
      final ringProgress = (progress + (i / ringCount)) % 1.0;
      final radius = minRadius + (maxRadius - minRadius) * ringProgress;
      final opacity = math.sin(ringProgress * math.pi) * 0.50;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Menampilkan status scanning radar: animasi icon + judul + sub-teks (ScanningRadarView / ScanningStatusView).
class ScanningRadarView extends StatelessWidget {
  final Widget animationWidget;
  final String title;
  final String subtitle;

  const ScanningRadarView({
    super.key,
    required this.animationWidget,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        animationWidget,
        const SizedBox(height: 32),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF94A3B8),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// Backward compatibility alias
typedef ScanningStatusView = ScanningRadarView;
