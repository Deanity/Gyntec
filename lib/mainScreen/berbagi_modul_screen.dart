import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../components/sharing/module_preview_card.dart';
import '../components/sharing/scanning_pulse_animation.dart';
import '../components/sharing/sharing_mode_tab.dart';
import '../utils/models.dart';
import 'pilih_modul_screen.dart';

/// Tahapan alur penerimaan modul pada BerbagiModulScreen
enum ReceiveStage {
  scanning,        // Mencari perangkat (scaning.png)
  requestReceived, // Menerima permintaan kiriman file (recive module.png)
  inProgress,      // Proses penerimaan file berlangsung (recive-on-progess.png)
  done,            // Penerimaan file selesai (recive-done.png)
}

/// Screen "Berbagi Module"
/// Mendukung mode Terima dan Kirim:
/// - Mode Terima: Otomatis mendeteksi kiriman masuk, menampilkan preview modul yang dibagikan,
///   dan memproses penerimaan file hingga selesai sesuai desain mockup.
/// - Mode Kirim: Menavigasi user ke PilihModulScreen.
class BerbagiModulScreen extends StatefulWidget {
  const BerbagiModulScreen({super.key});

  @override
  State<BerbagiModulScreen> createState() => _BerbagiModulScreenState();
}

class _BerbagiModulScreenState extends State<BerbagiModulScreen> {
  SharingMode _activeMode = SharingMode.terima;
  ReceiveStage _stage = ReceiveStage.scanning;

  // Data modul yang diterima dari pengirim
  List<ModuleModel> _incomingModules = [];

  // Timer simulasi incoming request & transfer progress
  Timer? _incomingSimTimer;
  Timer? _progressTimer;
  double _receiveProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadIncomingModules();
    _startSimulatedIncomingRequest();
  }

  @override
  void dispose() {
    _incomingSimTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadIncomingModules() async {
    try {
      final raw = await rootBundle.loadString('lib/utils/data.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final modules = (json['modules'] as List)
          .map((e) => ModuleModel.fromJson(e as Map<String, dynamic>))
          .take(3)
          .toList();

      if (mounted) {
        setState(() {
          _incomingModules = modules;
        });
      }
    } catch (_) {
      // Fallback 3 module items
      if (mounted) {
        setState(() {
          _incomingModules = List.generate(
            3,
            (i) => const ModuleModel(
              id: 'm_demo',
              level: 'SMA',
              subject: 'IPA',
              title: 'Anggota Tubuh Manusia',
              description:
                  'Pelajari anggota tubuh manusia dan fungsinya melalui m...',
              totalQuestions: 30,
              discussionCount: 1,
            ),
          );
        });
      }
    }
  }

  /// Simulasi setelah 2.2 detik ada perangkat "Rama (SM-2BXX)" yang mengirim modul
  void _startSimulatedIncomingRequest() {
    _incomingSimTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted && _stage == ReceiveStage.scanning) {
        setState(() {
          _stage = ReceiveStage.requestReceived;
        });
      }
    });
  }

  /// Memulai proses penerimaan file
  void _startReceiving() {
    setState(() {
      _stage = ReceiveStage.inProgress;
      _receiveProgress = 0.0;
    });

    const tickInterval = Duration(milliseconds: 60);
    _progressTimer = Timer.periodic(tickInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _receiveProgress += 0.015;
        if (_receiveProgress >= 1.0) {
          _receiveProgress = 1.0;
          timer.cancel();
          _stage = ReceiveStage.done;
        }
      });
    });
  }

  void _cancelReceiving() {
    _progressTimer?.cancel();
    setState(() {
      _stage = ReceiveStage.scanning;
      _receiveProgress = 0.0;
    });
    // Restart pencarian simulasi
    _startSimulatedIncomingRequest();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // ── Background soft blue gradient di atas ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 250,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE8F1FF),
                    Color(0x00E8F1FF),
                  ],
                ),
              ),
            ),
          ),

          // ── Konten Scrollable ──
          SafeArea(
            child: Column(
              children: [
                // Top Bar ("< Berbagi Module")
                _TopBar(
                  onBack: () {
                    if (_stage == ReceiveStage.inProgress) {
                      _cancelReceiving();
                    }
                    if (_stage == ReceiveStage.done) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    } else {
                      Navigator.of(context).maybePop();
                    }
                  },
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 10,
                      bottom: 160, // ruang floating tabs & button
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Bagian Radar & Status ──
                        Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            child: _buildHeaderForStage(),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Section: Module yang dibagikan ──
                        if (_stage != ReceiveStage.scanning &&
                            _incomingModules.isNotEmpty) ...[
                          const Text(
                            'Module yang dibagikan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._incomingModules.map((modul) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ModulePreviewCard(
                                module: modul,
                                subtitle: _stage == ReceiveStage.requestReceived
                                    ? 'Dibagikan oleh Rama (SM-1980)'
                                    : 'Dokumen pilihan Anda',
                                showDiscussionBadge:
                                    _stage == ReceiveStage.requestReceived,
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Floating Bottom Controls ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomControls(),
          ),
        ],
      ),
    );
  }

  // ── Header status dinamis sesuai stage ──
  Widget _buildHeaderForStage() {
    switch (_stage) {
      case ReceiveStage.scanning:
        return Column(
          key: const ValueKey('scanning_state'),
          children: [
            ScanningPulseAnimation(
              color: const Color(0xFF0066FF),
              ringCount: 3,
              size: 210,
              centerSize: 68,
              child: const Icon(
                LucideIcons.search,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mencari perangkat terdekat...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pastikan Wi-Fi & Bluetooth aktif pada perangkat tujuan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        );

      case ReceiveStage.requestReceived:
        return Column(
          key: const ValueKey('request_received_state'),
          children: [
            ScanningPulseAnimation(
              color: const Color(0xFF0066FF),
              ringCount: 3,
              size: 210,
              centerSize: 68,
              child: const Icon(
                LucideIcons.tabletSmartphone,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Rama (SM-2BXX)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Perangkat ini ingin mengirimkan 3 module pembelajaran',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        );

      case ReceiveStage.inProgress:
        return Column(
          key: const ValueKey('in_progress_state'),
          children: [
            ScanningPulseAnimation(
              color: const Color(0xFF0066FF),
              ringCount: 3,
              size: 210,
              centerSize: 68,
              child: const Icon(
                LucideIcons.arrowDown,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Menerima 3 Module dari Rama (SM-1980)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pastikan Wi-Fi & Bluetooth tetap aktif selama pengiriman',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),

            // Progress Bar
            Container(
              width: 250,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(50),
              ),
              clipBehavior: Clip.antiAlias,
              child: LinearProgressIndicator(
                value: _receiveProgress,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF0066FF)),
              ),
            ),
          ],
        );

      case ReceiveStage.done:
        return Column(
          key: const ValueKey('done_state'),
          children: [
            ScanningPulseAnimation(
              color: const Color(0xFF0066FF),
              ringCount: 3,
              size: 210,
              centerSize: 68,
              child: const Icon(
                Icons.check,
                size: 34,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Menerima 3 module',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Module pembelajaran berhasil diterima',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        );
    }
  }

  // ── Floating Bottom Controls ──
  Widget _buildBottomControls() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tab Terima / Kirim hanya muncul pada stage scanning & requestReceived
            if (_stage == ReceiveStage.scanning ||
                _stage == ReceiveStage.requestReceived) ...[
              SharingModeTab(
                activeMode: _activeMode,
                onModeChanged: (mode) {
                  if (mode == SharingMode.kirim) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PilihModulScreen(),
                      ),
                    );
                  } else {
                    setState(() => _activeMode = mode);
                  }
                },
              ),
            ],

            // Tombol "Terima File" saat ada request masuk (recive module.png)
            if (_stage == ReceiveStage.requestReceived)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _FullButton(
                  label: 'Terima File',
                  onPressed: _startReceiving,
                ),
              ),

            // Tombol "Batal" saat proses penerimaan berlangsung (recive-on-progess.png)
            if (_stage == ReceiveStage.inProgress)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _FullButton(
                  label: 'Batal',
                  onPressed: _cancelReceiving,
                ),
              ),

            // Tombol "Kembali" saat penerimaan selesai (recive-done.png)
            if (_stage == ReceiveStage.done)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _FullButton(
                  label: 'Kembali',
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-width Rounded Button Reusable
// ─────────────────────────────────────────────────────────────────────────────

class _FullButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _FullButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF0066FF),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330066FF),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Bar — "< Berbagi Module"
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              LucideIcons.chevronLeft,
              size: 22,
              color: Color(0xFF0F172A),
            ),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          const Text(
            'Berbagi Module',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}
