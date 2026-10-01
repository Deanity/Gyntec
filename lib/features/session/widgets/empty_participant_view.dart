import 'package:flutter/material.dart';

/// Widget tampilan status kosong ketika belum ada peserta didik yang ditambahkan.
/// Menampilkan ikon person blocked khusus, judul, dan pesan instruksi sesuai desain.
class EmptyParticipantView extends StatelessWidget {
  const EmptyParticipantView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Ikon person blocked khusus ──
            const EmptyParticipantIcon(
              size: 68,
              color: Color(0xFF1E293B),
            ),
            const SizedBox(height: 18),

            // ── Headline ──
            const Text(
              'Belum ada Peserta',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // ── Subtitle / Deskripsi ──
            const SizedBox(
              width: 270,
              child: Text(
                'Silahkan tambah peserta didik untuk memulai sesi pembelajaran',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF64748B),
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter untuk menggambar ikon person dengan ban/slash circle di kanan bawah
/// secara presisi sesuai gambar referensi Add Participant.png.
class EmptyParticipantIcon extends StatelessWidget {
  final double size;
  final Color color;

  const EmptyParticipantIcon({
    super.key,
    this.size = 64,
    this.color = const Color(0xFF1E293B),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _EmptyParticipantPainter(color: color),
    );
  }
}

class _EmptyParticipantPainter extends CustomPainter {
  final Color color;

  _EmptyParticipantPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 64.0;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 1. Kepala (Lingkaran di bagian atas)
    canvas.drawCircle(
      Offset(26 * scale, 17 * scale),
      9.5 * scale,
      strokePaint,
    );

    // 2. Bahu (Lengkungan tubuh dari kiri ke kanan yang berhenti sebelum tanda larangan)
    final shoulderPath = Path();
    shoulderPath.moveTo(8 * scale, 48 * scale);
    shoulderPath.cubicTo(
      8 * scale,
      35 * scale,
      18 * scale,
      33 * scale,
      26 * scale,
      33 * scale,
    );
    shoulderPath.cubicTo(
      32 * scale,
      33 * scale,
      37 * scale,
      35.5 * scale,
      39.5 * scale,
      39 * scale,
    );
    canvas.drawPath(shoulderPath, strokePaint);

    // 3. Lingkaran larangan (Ban circle) di kanan bawah
    final banCenter = Offset(45 * scale, 43 * scale);
    final banRadius = 9.5 * scale;
    canvas.drawCircle(banCenter, banRadius, strokePaint);

    // 4. Garis diagonal tanda larangan (dari kanan atas ke kiri bawah)
    final d = banRadius * 0.7071;
    canvas.drawLine(
      Offset(banCenter.dx + d, banCenter.dy - d),
      Offset(banCenter.dx - d, banCenter.dy + d),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _EmptyParticipantPainter oldDelegate) =>
      oldDelegate.color != color;
}
