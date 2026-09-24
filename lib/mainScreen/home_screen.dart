import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/components.dart';
import '../utils/models.dart';
import 'modul_materi_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  // Data yang dimuat dari data.json
  UserModel? _user;
  OfflineBannerModel? _banner;
  List<SessionModel> _sessions = [];
  List<ModuleModel> _modules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Membaca dan mem-parse data.json dari assets.
  Future<void> _loadData() async {
    final raw = await rootBundle.loadString('lib/utils/data.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;

    setState(() {
      _user = UserModel.fromJson(json['user'] as Map<String, dynamic>);
      _banner = OfflineBannerModel.fromJson(
          json['offlineBanner'] as Map<String, dynamic>);
      _sessions = (json['recentSessions'] as List)
          .map((e) => SessionModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _modules = (json['modules'] as List)
          .map((e) => ModuleModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _isLoading = false;
    });
  }

  String _currentDateTime() {
    final now = DateTime.now();
    const days = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    final day = days[now.weekday - 1];
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return 'Hari ini $day, pukul $hour.$minute';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // ── Konten utama ──
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── Header: salam & tanggal ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_user!.greeting}, ${_user!.name}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentDateTime(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Banner offline ──
                        OfflineBannerCard(
                          title: _banner!.title,
                          description: _banner!.description,
                          savedModules: _banner!.savedModules,
                        ),
                        const SizedBox(height: 28),

                        // ── Sesi Belajar Terakhir header ──
                        SectionHeader(
                          title: 'Sesi Belajar Terakhir',
                          onActionTap: () {},
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),

                // ── Horizontal scroll: SessionCard ──
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 170,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _sessions.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => SessionCard(
                        session: _sessions[index],
                        onTap: () {},
                      ),
                    ),
                  ),
                ),

                // ── Modul Pembelajaran header ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                    child: SectionHeader(
                      title: 'Modul Pembelajaran',
                      onActionTap: () {},
                    ),
                  ),
                ),

                // ── Vertical list: ModuleListItem ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: _modules.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => ModuleListItem(
                      module: _modules[index],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ModulMateriScreen(),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom padding — beri ruang agar konten tidak tertutup navbar
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),

          // ── Floating Pill NavBar — mengambang di bawah layar ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: HomeBottomNavBar(
              currentIndex: _navIndex,
              onTap: (i) => setState(() => _navIndex = i),
            ),
          ),
        ],
      ),
    );
  }
}
