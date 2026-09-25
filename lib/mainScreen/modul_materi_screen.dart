import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/components.dart';
import '../utils/models.dart';
import '../utils/connectivity_service.dart';
import 'participant_screen.dart';

class ModulMateriScreen extends StatefulWidget {
  const ModulMateriScreen({super.key});

  @override
  State<ModulMateriScreen> createState() => _ModulMateriScreenState();
}

class _ModulMateriScreenState extends State<ModulMateriScreen> {
  MateriTab _activeTab = MateriTab.materi;
  ModulDetailModel? _modul;
  OfflineBannerModel? _banner;
  bool _isLoading = true;

  // Konektivitas jaringan
  bool _isOffline = false;
  StreamSubscription<bool>? _connectivitySub;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initConnectivity();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Cek status awal, subscribe stream, dan mulai polling fallback tiap 4 detik.
  Future<void> _initConnectivity() async {
    final online = await ConnectivityService.instance.isOnline();
    if (mounted) setState(() => _isOffline = !online);

    _connectivitySub = ConnectivityService.instance.onStatusChanged.listen(
      (isOnline) {
        if (mounted) setState(() => _isOffline = !isOnline);
      },
    );

    // Polling fallback setiap 4 detik
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      final online = await ConnectivityService.instance.isOnline();
      if (mounted) setState(() => _isOffline = !online);
    });
  }

  /// Dipanggil saat user pull-to-refresh.
  Future<void> _refreshConnectivity() async {
    final online = await ConnectivityService.instance.isOnline();
    if (mounted) setState(() => _isOffline = !online);
  }

  Future<void> _loadData() async {
    final raw = await rootBundle.loadString('lib/utils/data.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    setState(() {
      _banner = OfflineBannerModel.fromJson(
          json['offlineBanner'] as Map<String, dynamic>);
      _modul = ModulDetailModel.fromJson(
          json['modulDetail'] as Map<String, dynamic>);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final modul = _modul!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── 1. Custom Top Bar (SafeArea -> Container -> Stack) ──
          const CustomTopBar(
            title: 'Module Materi',
          ),

          // ── 2. Konten Scrollable ──
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshConnectivity,
              color: const Color(0xFF0066FF),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner offline (hanya tampil saat tidak ada koneksi)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => SizeTransition(
                      sizeFactor: animation,
                      axisAlignment: -1,
                      child:
                          FadeTransition(opacity: animation, child: child),
                    ),
                    child: _isOffline
                        ? Padding(
                            key: const ValueKey('offline-banner'),
                            padding: const EdgeInsets.only(bottom: 20),
                            child: OfflineBannerCard(
                              title: _banner!.title,
                              description: _banner!.description,
                              savedModules: _banner!.savedModules,
                            ),
                          )
                        : const SizedBox.shrink(
                            key: ValueKey('no-banner')),
                  ),

                  // Konten Tab
                  _buildTabContent(modul),
                ],
              ),
            ),            // SingleChildScrollView
          ),            // RefreshIndicator
        ),              // Expanded

          // ── 3. Custom Bottom Action Bar (Pill Tabs + Mulai Sesi) ──
          ModulBottomAction(
            activeTab: _activeTab,
            onTabChanged: (tab) => setState(() => _activeTab = tab),
            onStartSession: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ParticipantScreen(modul: modul),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(ModulDetailModel modul) {
    return switch (_activeTab) {
      MateriTab.materi => _MateriTabContent(modul: modul),
      MateriTab.diskusi => _DiskusiTabContent(modul: modul),
      MateriTab.quiz => _QuizTabContent(modul: modul),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Materi
// ─────────────────────────────────────────────────────────────────────────────

class _MateriTabContent extends StatelessWidget {
  final ModulDetailModel modul;
  const _MateriTabContent({required this.modul});

  @override
  Widget build(BuildContext context) {
    final List<Widget> blocks = [];

    for (final item in modul.materi) {
      if (item.imageAsset != null) {
        blocks.add(MateriImageBlock(assetPath: item.imageAsset!));
        blocks.add(const SizedBox(height: 16));
      }
      blocks.add(MateriContentBlock(heading: item.heading, body: item.body));
      blocks.add(const SizedBox(height: 24));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Diskusi
// ─────────────────────────────────────────────────────────────────────────────

class _DiskusiTabContent extends StatelessWidget {
  final ModulDetailModel modul;
  const _DiskusiTabContent({required this.modul});

  @override
  Widget build(BuildContext context) {
    final gq = modul.groupQuestion;
    return GroupQuestionCard(
      title: gq.title,
      instructions: gq.instructions,
      indicators: gq.indicators,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Quiz
// ─────────────────────────────────────────────────────────────────────────────

class _QuizTabContent extends StatelessWidget {
  final ModulDetailModel modul;
  const _QuizTabContent({required this.modul});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header quiz
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pertanyaan Quiz',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'Lihat semua',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF0066FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Daftar pertanyaan
        ...modul.quiz.map(
          (q) => Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: QuizQuestionCard(question: q),
          ),
        ),

        // Tombol semua pertanyaan
        CustomButton(
          label: 'Semua Pertanyaan',
          onPressed: () {},
          backgroundColor: Colors.white,
          textColor: const Color(0xFF0F172A),
          borderRadius: 12,
          height: 48,
          border: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
