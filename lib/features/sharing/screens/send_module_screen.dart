import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/sharing_widgets.dart';
import '../../../utils/models.dart';

/// Screen alur pemilihan perangkat dan pengiriman modul (SendModuleScreen).
///
/// Memiliki 3 tahapan visual:
/// 1. [no_device] : Mencari perangkat (radar scanner) + Preview modul.
/// 2. [device_found] : Perangkat ditemukan (Rama, iPad Olivia) + Pilihan perangkat + Tombol Kirim.
/// 3. [sending_in_progress] : Animasi panah upload + Progress bar + List modul + Tombol Batal.
class SendModuleScreen extends StatefulWidget {
  final List<ModuleModel> selectedModules;

  const SendModuleScreen({super.key, required this.selectedModules});

  @override
  State<SendModuleScreen> createState() => _SendModuleScreenState();
}

class _SendModuleScreenState extends State<SendModuleScreen> {
  // Daftar perangkat yang terdeteksi
  final List<TargetDeviceModel> _discoveredDevices = [];
  final Set<String> _selectedDeviceIds = {};

  // Status proses pengiriman
  bool _isSending = false;
  bool _isSuccess = false;
  double _sendProgress = 0.0;
  Timer? _progressTimer;
  Timer? _discoveryTimer;

  @override
  void initState() {
    super.initState();
    _startSimulatedDeviceDiscovery();
  }

  @override
  void dispose() {
    _discoveryTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  /// Simulasi penemuan perangkat setelah 1.8 detik
  void _startSimulatedDeviceDiscovery() {
    _discoveryTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _discoveredDevices.addAll([
            const TargetDeviceModel(id: 'dev_1', name: 'Rama (SM-1980)'),
            const TargetDeviceModel(id: 'dev_2', name: 'iPad Olivia'),
          ]);
          // Default pilih perangkat pertama sesuai mockup
          _selectedDeviceIds.add('dev_1');
        });
      }
    });
  }

  void _toggleDevice(String id) {
    setState(() {
      if (_selectedDeviceIds.contains(id)) {
        _selectedDeviceIds.remove(id);
      } else {
        _selectedDeviceIds.add(id);
      }
    });
  }

  /// Memulai pengiriman modul ke perangkat terpilih
  void _startSending() {
    if (_selectedDeviceIds.isEmpty) return;

    setState(() {
      _isSending = true;
      _isSuccess = false;
      _sendProgress = 0.0;
    });

    // Simulasi progress pengiriman dari 0% ke 100%
    const tickInterval = Duration(milliseconds: 60);
    _progressTimer = Timer.periodic(tickInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _sendProgress += 0.015;
        if (_sendProgress >= 1.0) {
          _sendProgress = 1.0;
          timer.cancel();
          _onSendingComplete();
        }
      });
    });
  }

  void _cancelSending() {
    _progressTimer?.cancel();
    setState(() {
      _isSending = false;
      _isSuccess = false;
      _sendProgress = 0.0;
    });
  }

  void _onSendingComplete() {
    setState(() {
      _isSending = false;
      _isSuccess = true;
    });
  }

  String _getSendingTargetTitle() {
    final count = widget.selectedModules.length;
    final selectedDevices = _discoveredDevices
        .where((d) => _selectedDeviceIds.contains(d.id))
        .map((d) => d.name)
        .toList();

    final targetName = selectedDevices.isNotEmpty
        ? selectedDevices.first
        : 'Perangkat';

    return 'Mengirim $count Module ke $targetName';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          //  Background soft blue gradient di atas
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
                  colors: [Color(0xFFE8F1FF), Color(0x00E8F1FF)],
                ),
              ),
            ),
          ),

          //  Konten Scrollable
          SafeArea(
            child: Column(
              children: [
                // Top Bar ("< Berbagi Module")
                _TopBar(
                  onBack: () {
                    if (_isSending) {
                      _cancelSending();
                      Navigator.of(context).maybePop();
                    } else if (_isSuccess) {
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
                      bottom: 110, // ruang floating action button
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //  Bagian Atas: Animasi Radar & Status
                        Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            child: _isSuccess
                                ? _buildSuccessHeader()
                                : _isSending
                                ? _buildSendingHeader()
                                : _buildScanningHeader(),
                          ),
                        ),
                        const SizedBox(height: 28),

                        //  Pilihan Perangkat Penerima (hanya saat mode pemilihan & ada device)
                        if (!_isSending &&
                            !_isSuccess &&
                            _discoveredDevices.isNotEmpty) ...[
                          const Text(
                            'Pilih Perangkat Penerima',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._discoveredDevices.map(
                            (device) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: DeviceSelectCard(
                                device: device,
                                isSelected: _selectedDeviceIds.contains(
                                  device.id,
                                ),
                                onTap: () => _toggleDevice(device.id),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        //  Bagian: Module yang Dikirim
                        const Text(
                          'Module yang Dikirim',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // List Preview Card Modul
                        ...widget.selectedModules.map(
                          (modul) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ModulePreviewCard(module: modul),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          //  Floating Action Button di bawah
          Positioned(
            left: 20,
            right: 20,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildBottomButton(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //  Header saat mencari perangkat
  Widget _buildScanningHeader() {
    return Column(
      key: const ValueKey('scanning_header'),
      children: [
        ScanningPulseAnimation(
          color: const Color(0xFF0066FF),
          ringCount: 3,
          size: 210,
          centerSize: 68,
          child: const Icon(LucideIcons.search, size: 28, color: Colors.white),
        ),
        const SizedBox(height: 24),
        const Text(
          'Mencari penerima terdekat...',
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
          'Pilih satu atau beberapa perangkat tujuan di bawah',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  //  Header saat proses pengiriman berlangsung
  Widget _buildSendingHeader() {
    return Column(
      key: const ValueKey('sending_header'),
      children: [
        ScanningPulseAnimation(
          color: const Color(0xFF0066FF),
          ringCount: 3,
          size: 210,
          centerSize: 68,
          child: const Icon(LucideIcons.arrowUp, size: 30, color: Colors.white),
        ),
        const SizedBox(height: 24),
        Text(
          _getSendingTargetTitle(),
          textAlign: TextAlign.center,
          style: const TextStyle(
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
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 18),

        // Progress Bar (full width matching design)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(50),
            ),
            clipBehavior: Clip.antiAlias,
            child: LinearProgressIndicator(
              value: _sendProgress,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF0066FF),
              ),
            ),
          ),
        ),
      ],
    );
  }

  //  Header saat pengiriman berhasil (sending-done.png)
  Widget _buildSuccessHeader() {
    return Column(
      key: const ValueKey('success_header'),
      children: [
        ScanningPulseAnimation(
          color: const Color(0xFF0066FF),
          ringCount: 3,
          size: 210,
          centerSize: 68,
          child: const Icon(Icons.check, size: 36, color: Colors.white),
        ),
        const SizedBox(height: 24),
        const Text(
          'Pengiriman Module Sukses',
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
          'Module pembelajaran berhasil terkirim ke perangkat tujuan',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  //  Bottom Action Button
  Widget _buildBottomButton() {
    if (_isSuccess) {
      // Tombol "Kembali" sesuai sending-done.png
      return _ActionButton(
        label: 'Kembali',
        backgroundColor: const Color(0xFF0066FF),
        textColor: Colors.white,
        onPressed: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      );
    }

    if (_isSending) {
      // Tombol "Batal"
      return _ActionButton(
        label: 'Batal',
        backgroundColor: const Color(0xFF0066FF),
        textColor: Colors.white,
        onPressed: _cancelSending,
      );
    }

    if (_discoveredDevices.isNotEmpty) {
      // Tombol "Kirim"
      final hasSelection = _selectedDeviceIds.isNotEmpty;
      return _ActionButton(
        label: 'Kirim',
        backgroundColor: hasSelection
            ? const Color(0xFF0066FF)
            : const Color(0xFFD4D4D8),
        textColor: hasSelection ? Colors.white : const Color(0xFF9CA3AF),
        onPressed: hasSelection ? _startSending : null,
      );
    }

    // Saat masih mencari dan belum ada device: tidak ada tombol
    return const SizedBox.shrink();
  }
}

// ─
// Komponen Tombol Aksi Reusable
// ─

class _ActionButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: isEnabled && backgroundColor == const Color(0xFF0066FF)
            ? const [
                BoxShadow(
                  color: Color(0x330066FF),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─
// Top Bar — "< Berbagi Module"
// ─

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

/// Backward compatibility alias
typedef KirimModulScreen = SendModuleScreen;
