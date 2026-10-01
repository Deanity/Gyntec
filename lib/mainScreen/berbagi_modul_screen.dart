import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../components/sharing/scanning_pulse_animation.dart';
import '../components/sharing/scanning_status_view.dart';
import '../components/sharing/sharing_mode_tab.dart';

/// Screen "Berbagi Module" — tampil setelah user menekan FAB (+) di ModulScreen.
///
/// Flow:
/// 1. User memilih mode: Terima atau Kirim
/// 2. Screen menampilkan animasi scanning + status
/// 3. (TODO) Integrasi Bluetooth/Wi-Fi Direct untuk transfer modul
class BerbagiModulScreen extends StatefulWidget {
  const BerbagiModulScreen({super.key});

  @override
  State<BerbagiModulScreen> createState() => _BerbagiModulScreenState();
}

class _BerbagiModulScreenState extends State<BerbagiModulScreen> {
  SharingMode _activeMode = SharingMode.terima;

  // Status teks berdasarkan mode aktif
  String get _statusTitle => switch (_activeMode) {
        SharingMode.terima => 'Mencari perangkat terdekat...',
        SharingMode.kirim => 'Menunggu perangkat penerima...',
      };

  String get _statusSubtitle => switch (_activeMode) {
        SharingMode.terima =>
          'Pastikan Wi-Fi & Bluetooth aktif pada perangkat tujuan',
        SharingMode.kirim =>
          'Pastikan Wi-Fi & Bluetooth aktif pada perangkat ini',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          // ── Top Bar ──
          _TopBar(onBack: () => Navigator.of(context).maybePop()),

          // ── Konten tengah (scanning animation + status) ──
          Expanded(
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: ScanningStatusView(
                  key: ValueKey(_activeMode),
                  title: _statusTitle,
                  subtitle: _statusSubtitle,
                  animationWidget: ScanningPulseAnimation(
                    color: const Color(0xFF0066FF),
                    ringCount: 3,
                    size: 220,
                    centerSize: 72,
                    child: const Icon(
                      LucideIcons.search,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom Tab (Terima / Kirim) ──
          SharingModeTab(
            activeMode: _activeMode,
            onModeChanged: (mode) => setState(() => _activeMode = mode),
          ),
        ],
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            // Tombol back
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
      ),
    );
  }
}
