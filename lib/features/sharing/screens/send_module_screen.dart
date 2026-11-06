import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/core.dart';
import '../widgets/sharing_widgets.dart';
import '../../../utils/models.dart';

/// Screen alur pemilihan perangkat dan pengiriman modul (SendModuleScreen).
///
/// Memiliki 3 tahapan visual:
/// 1. [no_device] : Mencari perangkat (radar scanner) + Preview modul.
/// 2. [device_found] : Perangkat ditemukan + Pilihan perangkat + Tombol Kirim.
/// 3. [sending_in_progress] : Animasi panah upload + Progress bar + List modul + Tombol Batal.
class SendModuleScreen extends StatefulWidget {
  final List<ModuleModel> selectedModules;

  const SendModuleScreen({super.key, required this.selectedModules});

  @override
  State<SendModuleScreen> createState() => _SendModuleScreenState();
}

class _SendModuleScreenState extends State<SendModuleScreen> {
  final List<TargetDeviceModel> _discoveredDevices = [];
  String? _selectedDeviceId;

  bool _isSending = false;
  bool _isSuccess = false;
  double _sendProgress = 0.0;

  StreamSubscription<List<TargetDeviceModel>>? _devicesSub;
  StreamSubscription<double>? _progressSub;

  @override
  void initState() {
    super.initState();
    _initNearbyDiscovery();
  }

  @override
  void dispose() {
    _devicesSub?.cancel();
    _progressSub?.cancel();
    NearbySharingService.instance.stop();
    super.dispose();
  }

  Future<void> _initNearbyDiscovery() async {
    final service = NearbySharingService.instance;
    await service.startDiscovery();

    _devicesSub = service.devices.listen((devices) {
      if (mounted) {
        setState(() {
          _discoveredDevices.clear();
          _discoveredDevices.addAll(devices);
          if (_selectedDeviceId == null && devices.isNotEmpty) {
            _selectedDeviceId = devices.first.id;
          }
        });
      }
    });

    _progressSub = service.progress.listen((prog) {
      if (mounted) {
        setState(() {
          _sendProgress = prog;
        });
      }
    });
  }

  void _selectDevice(String id) {
    setState(() {
      _selectedDeviceId = id;
    });
  }

  Future<void> _startSending() async {
    if (_selectedDeviceId == null) return;
    final target = _discoveredDevices.firstWhere(
      (d) => d.id == _selectedDeviceId,
      orElse: () => TargetDeviceModel(id: _selectedDeviceId!, name: 'Perangkat'),
    );

    setState(() {
      _isSending = true;
      _isSuccess = false;
      _sendProgress = 0.0;
    });

    final result = await NearbySharingService.instance.send(
      target,
      widget.selectedModules,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _isSending = false;
        _isSuccess = true;
        _sendProgress = 1.0;
      });
    } else {
      setState(() {
        _isSending = false;
        _isSuccess = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Gagal mengirim module'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      // Restart discovery
      NearbySharingService.instance.startDiscovery();
    }
  }

  void _cancelSending() {
    NearbySharingService.instance.stop();
    setState(() {
      _isSending = false;
      _isSuccess = false;
      _sendProgress = 0.0;
    });
    _initNearbyDiscovery();
  }

  String _getSendingTargetTitle() {
    final count = widget.selectedModules.length;
    final selectedDevice = _discoveredDevices.cast<TargetDeviceModel?>().firstWhere(
          (d) => d?.id == _selectedDeviceId,
          orElse: () => null,
        );
    final targetName = selectedDevice?.name ?? 'Perangkat';
    return 'Mengirim $count Module ke $targetName';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
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
          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  onBack: () {
                    if (_isSending) {
                      _cancelSending();
                      Navigator.of(context).maybePop();
                    } else if (_isSuccess) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    } else {
                      NearbySharingService.instance.stop();
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
                      bottom: 110,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppOfflineBanner(
                          padding: EdgeInsets.only(bottom: 16),
                        ),
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
                                isSelected: _selectedDeviceId == device.id,
                                onTap: () => _selectDevice(device.id),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
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

  Widget _buildScanningHeader() {
    return Column(
      key: const ValueKey('scanning_header'),
      children: const [
        ScanningPulseAnimation(
          color: Color(0xFF0066FF),
          ringCount: 3,
          size: 210,
          centerSize: 68,
          child: Icon(LucideIcons.search, size: 28, color: Colors.white),
        ),
        SizedBox(height: 24),
        Text(
          'Mencari penerima terdekat...',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Pastikan perangkat penerima membuka menu Terima di Berbagi Module',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildSendingHeader() {
    return Column(
      key: const ValueKey('sending_header'),
      children: [
        const ScanningPulseAnimation(
          color: Color(0xFF0066FF),
          ringCount: 3,
          size: 210,
          centerSize: 68,
          child: Icon(LucideIcons.arrowUp, size: 30, color: Colors.white),
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

  Widget _buildSuccessHeader() {
    return Column(
      key: const ValueKey('success_header'),
      children: const [
        ScanningPulseAnimation(
          color: Color(0xFF0066FF),
          ringCount: 3,
          size: 210,
          centerSize: 68,
          child: Icon(LucideIcons.check, size: 36, color: Colors.white),
        ),
        SizedBox(height: 24),
        Text(
          'Pengiriman Module Sukses',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Module pembelajaran berhasil terkirim ke perangkat tujuan',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    if (_isSuccess) {
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
      return _ActionButton(
        label: 'Batal',
        backgroundColor: const Color(0xFFEF4444),
        textColor: Colors.white,
        onPressed: _cancelSending,
      );
    }

    if (_discoveredDevices.isNotEmpty) {
      final hasSelection = _selectedDeviceId != null;
      return _ActionButton(
        label: 'Kirim',
        backgroundColor: hasSelection
            ? const Color(0xFF0066FF)
            : const Color(0xFFD4D4D8),
        textColor: hasSelection ? Colors.white : const Color(0xFF9CA3AF),
        onPressed: hasSelection ? _startSending : null,
      );
    }

    return const SizedBox.shrink();
  }
}

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
            ? [
                BoxShadow(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onBack,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  LucideIcons.arrowLeft,
                  size: 22,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
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
