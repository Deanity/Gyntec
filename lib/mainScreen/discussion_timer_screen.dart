import 'dart:async';
import 'package:flutter/material.dart';

/// Fullscreen timer untuk sesi diskusi kelompok:
/// - Start state (running): Menampilkan countdown (default 20:00) dan tombol putih "Selesai"
/// - End state (00:00): Menampilkan tombol "Selesai" dan "5+ Menit"
/// - Ketika waktu habis, otomatis berpindah ke Quiz Screen (dengan jeda singkat agar user bisa menambah waktu jika diinginkan).
class DiscussionTimerScreen extends StatefulWidget {
  final int initialMinutes;

  const DiscussionTimerScreen({
    super.key,
    this.initialMinutes = 20,
  });

  @override
  State<DiscussionTimerScreen> createState() => _DiscussionTimerScreenState();
}

class _DiscussionTimerScreenState extends State<DiscussionTimerScreen> {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isEnded = false;
  Timer? _autoProceedTimer;
  int _autoProceedCountdown = 5;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialMinutes * 60;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoProceedTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _autoProceedTimer?.cancel();
    setState(() {
      _isEnded = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _onTimeExpired();
      }
    });
  }

  void _onTimeExpired() {
    setState(() {
      _isEnded = true;
      _autoProceedCountdown = 5;
    });

    // Otomatis berpindah ke Quiz setelah hitungan mundur 5 detik jika user tidak menambah waktu
    _autoProceedTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_autoProceedCountdown > 1) {
        setState(() {
          _autoProceedCountdown--;
        });
      } else {
        _autoProceedTimer?.cancel();
        _finishAndProceed();
      }
    });
  }

  /// Tambah waktu 5 menit saat di end screen
  void _addFiveMinutes() {
    _autoProceedTimer?.cancel();
    setState(() {
      _remainingSeconds += 5 * 60;
      _isEnded = false;
    });
    _startTimer();
  }

  /// Selesai dan lanjut ke Quiz
  void _finishAndProceed() {
    _timer?.cancel();
    _autoProceedTimer?.cancel();
    Navigator.of(context).pop(true);
  }

  /// Fast-forward untuk kemudahan testing (lompat ke 5 detik terakhir)
  void _fastForwardForTesting() {
    if (_remainingSeconds > 5) {
      setState(() {
        _remainingSeconds = 5;
      });
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final minutesStr = minutes.toString().padLeft(2, '0');
    final secondsStr = seconds.toString().padLeft(2, '0');
    return '$minutesStr:$secondsStr';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // Konten Tengah: Timer dan Tombol Selesai / 5+ Menit
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Digital Clock
                      GestureDetector(
                        onDoubleTap: _fastForwardForTesting,
                        child: Text(
                          _formatTime(_remainingSeconds),
                          style: const TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 2,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Tombol aksi
                      if (!_isEnded)
                        // Mode Berjalan: Tombol Putih "Selesai"
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _finishAndProceed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF0F172A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Selesai',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        // Mode Waktu Habis (End Time): Tombol "Selesai" dan "5+ Menit"
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Tombol Selesai
                                Expanded(
                                  child: SizedBox(
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _finishAndProceed,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor:
                                            const Color(0xFF0F172A),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(28),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'Selesai',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Tombol 5+ Menit
                                Expanded(
                                  child: SizedBox(
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _addFiveMinutes,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF0066FF),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(28),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        '5+ Menit',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Menuju Quiz dalam $_autoProceedCountdown detik...',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              // Hint Fast-forward kecil di pojok bawah untuk testing
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _fastForwardForTesting,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Double tap angka untuk fast-forward',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
