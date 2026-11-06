import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/core.dart';
import '../widgets/sharing_widgets.dart';
import '../../../utils/models.dart';
import 'select_module_to_send_screen.dart';

enum ReceiveStage {
  scanning,
  requestReceived,
  inProgress,
  done,
}

class SharingHubScreen extends StatefulWidget {
  const SharingHubScreen({super.key});

  @override
  State<SharingHubScreen> createState() => _SharingHubScreenState();
}

class _SharingHubScreenState extends State<SharingHubScreen> {
  final SharingMode _activeMode = SharingMode.terima;
  ReceiveStage _stage = ReceiveStage.scanning;

  List<ModuleModel> _incomingModules = [];
  String _senderName = 'Perangkat Lain';
  String? _authPin;
  double _receiveProgress = 0.0;
  int _receivedCount = 0;

  StreamSubscription<IncomingOffer>? _offersSub;
  StreamSubscription<double>? _progressSub;
  StreamSubscription<List<String>>? _receivedSub;

  IncomingOffer? _activeOffer;

  @override
  void initState() {
    super.initState();
    _initNearbyReceiving();
  }

  @override
  void dispose() {
    _offersSub?.cancel();
    _progressSub?.cancel();
    _receivedSub?.cancel();
    NearbySharingService.instance.stop();
    super.dispose();
  }

  Future<void> _initNearbyReceiving() async {
    final service = NearbySharingService.instance;
    await service.startReceiving();

    _offersSub = service.offers.listen((offer) {
      if (mounted) {
        setState(() {
          _activeOffer = offer;
          _senderName = offer.senderName;
          _incomingModules = offer.modules;
          _authPin = offer.authPin;
          _stage = ReceiveStage.requestReceived;
        });
      }
    });

    _progressSub = service.progress.listen((prog) {
      if (mounted) {
        setState(() {
          _receiveProgress = prog;
          if (_stage != ReceiveStage.inProgress && prog < 1.0) {
            _stage = ReceiveStage.inProgress;
          }
        });
      }
    });

    _receivedSub = service.received.listen((savedIds) {
      if (mounted) {
        setState(() {
          _receivedCount = savedIds.length;
          _stage = ReceiveStage.done;
          _receiveProgress = 1.0;
        });
      }
    });
  }

  Future<void> _startReceiving() async {
    if (_activeOffer != null) {
      setState(() {
        _stage = ReceiveStage.inProgress;
        _receiveProgress = 0.0;
      });
      await NearbySharingService.instance.acceptOffer(_activeOffer!);
    }
  }

  Future<void> _cancelReceiving() async {
    if (_activeOffer != null) {
      await NearbySharingService.instance.rejectOffer(_activeOffer!);
    }
    await NearbySharingService.instance.stop();
    setState(() {
      _stage = ReceiveStage.scanning;
      _receiveProgress = 0.0;
      _incomingModules.clear();
      _activeOffer = null;
    });
    await NearbySharingService.instance.startReceiving();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                AppTopBar(
                  title: 'Berbagi Module',
                  onBack: () {
                    NearbySharingService.instance.stop();
                    Navigator.of(context).maybePop();
                  },
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _buildHeaderForStage(),
                        ),
                        const SizedBox(height: 24),
                        if (_incomingModules.isNotEmpty &&
                            (_stage == ReceiveStage.requestReceived ||
                                _stage == ReceiveStage.inProgress)) ...[
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Module yang Dikirim',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._incomingModules.map((modul) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ModulePreviewCard(
                                module: modul,
                                subtitle: _stage == ReceiveStage.requestReceived
                                    ? 'Dibagikan oleh $_senderName'
                                    : 'Dokumen pilihan Anda',
                                showDiscussionBadge: _stage == ReceiveStage.requestReceived,
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

  Widget _buildHeaderForStage() {
    switch (_stage) {
      case ReceiveStage.scanning:
        return Column(
          key: const ValueKey('scanning_state'),
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
              'Mencari perangkat terdekat...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Pastikan Bluetooth & Lokasi aktif di kedua perangkat',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        );

      case ReceiveStage.requestReceived:
        return Column(
          key: const ValueKey('request_received_state'),
          children: [
            const ScanningPulseAnimation(
              color: Color(0xFF0066FF),
              ringCount: 3,
              size: 210,
              centerSize: 68,
              child: Icon(
                LucideIcons.tabletSmartphone,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _senderName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Perangkat ini ingin mengirimkan ${_incomingModules.length} module pembelajaran',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            if (_authPin != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Kode Verifikasi: $_authPin',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0066FF),
                  ),
                ),
              ),
            ],
          ],
        );

      case ReceiveStage.inProgress:
        return Column(
          key: const ValueKey('in_progress_state'),
          children: [
            const ScanningPulseAnimation(
              color: Color(0xFF0066FF),
              ringCount: 3,
              size: 210,
              centerSize: 68,
              child: Icon(
                LucideIcons.arrowDown,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Menerima ${_incomingModules.length} Module dari $_senderName',
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
              'Jangan tutup aplikasi selama pengiriman file',
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
                  value: _receiveProgress,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF0066FF),
                  ),
                ),
              ),
            ),
          ],
        );

      case ReceiveStage.done:
        return Column(
          key: const ValueKey('done_state'),
          children: [
            const ScanningPulseAnimation(
              color: Color(0xFF0066FF),
              ringCount: 3,
              size: 210,
              centerSize: 68,
              child: Icon(LucideIcons.check, size: 34, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              'Menerima ${_receivedCount > 0 ? _receivedCount : _incomingModules.length} module',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Module pembelajaran berhasil diterima dan disimpan',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        );
    }
  }

  Widget _buildBottomControls() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_stage == ReceiveStage.scanning) ...[
              SharingModeTab(
                activeMode: _activeMode,
                onModeChanged: (mode) {
                  if (mode == SharingMode.kirim) {
                    NearbySharingService.instance.stop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const SelectModuleToSendScreen(),
                      ),
                    );
                  }
                },
              ),
            ],
            if (_stage == ReceiveStage.requestReceived) ...[
              SharingModeTab(
                activeMode: _activeMode,
                onModeChanged: (mode) {
                  if (mode == SharingMode.kirim) {
                    _cancelReceiving();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const SelectModuleToSendScreen(),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppButton(
                  label: 'Terima File',
                  onPressed: _startReceiving,
                ),
              ),
            ],
            if (_stage == ReceiveStage.inProgress) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _cancelReceiving,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      foregroundColor: const Color(0xFFEF4444),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (_stage == ReceiveStage.done) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppButton(
                  label: 'Kembali',
                  onPressed: () {
                    NearbySharingService.instance.stop();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
