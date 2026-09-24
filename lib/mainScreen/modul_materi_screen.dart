import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../components/components.dart';
import '../utils/models.dart';

/// Tab yang tersedia di Modul Materi Screen
enum MateriTab { materi, diskusi, quiz }

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

  @override
  void initState() {
    super.initState();
    _loadData();
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
          // ── Konten scrollable ──
          Expanded(
            child: CustomScrollView(
              slivers: [
                // ── App Bar ──
                SliverAppBar(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  pinned: true,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(
                      LucideIcons.chevronLeft,
                      color: Color(0xFF0F172A),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: const Text(
                    'Module Materi',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  centerTitle: true,
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Divider(
                      height: 1,
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
                ),

                // ── Body konten berdasarkan tab ──
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Banner offline
                      OfflineBannerCard(
                        title: _banner!.title,
                        description: _banner!.description,
                        savedModules: _banner!.savedModules,
                      ),
                      const SizedBox(height: 24),

                      // Konten tab
                      _buildTabContent(modul),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // ── Tab Bar + Tombol Mulai Sesi (sticky di bawah) ──
          _BottomActionBar(
            activeTab: _activeTab,
            onTabChanged: (tab) => setState(() => _activeTab = tab),
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
      blocks.add(MateriContentBlock(heading: item.heading, body: item.body));
      if (item.imageAsset != null) {
        blocks.add(const SizedBox(height: 16));
        blocks.add(MateriImageBlock(assetPath: item.imageAsset!));
      }
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

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Action Bar: Tab switcher + Mulai Sesi button
// ─────────────────────────────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  final MateriTab activeTab;
  final ValueChanged<MateriTab> onTabChanged;

  const _BottomActionBar({
    required this.activeTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tab switcher
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: MateriTab.values.map((tab) {
                  final isActive = tab == activeTab;
                  final label = switch (tab) {
                    MateriTab.materi => 'Materi',
                    MateriTab.diskusi => 'Diskusi',
                    MateriTab.quiz => 'Quiz',
                  };
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTabChanged(tab),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: isActive
                              ? [
                                  const BoxShadow(
                                    color: Color(0x14000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isActive
                                ? const Color(0xFF0F172A)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Tombol Mulai Sesi
            CustomButton(
              label: 'Mulai Sesi',
              onPressed: () {},
              backgroundColor: const Color(0xFF0066FF),
              borderRadius: 14,
              height: 52,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
