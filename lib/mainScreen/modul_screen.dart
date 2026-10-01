import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../utils/models.dart';
import 'modul_materi_screen.dart';

/// Screen tab "Modul" — menampilkan daftar semua modul yang tersedia,
/// lengkap dengan search bar untuk filter, dan FAB (+) untuk tambah modul baru.
class ModulScreen extends StatefulWidget {
  const ModulScreen({super.key});

  @override
  State<ModulScreen> createState() => _ModulScreenState();
}

class _ModulScreenState extends State<ModulScreen> {
  List<ModuleModel> _allModules = [];
  List<ModuleModel> _filteredModules = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final raw = await rootBundle.loadString('lib/utils/data.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final modules = (json['modules'] as List)
        .map((e) => ModuleModel.fromJson(e as Map<String, dynamic>))
        .toList();

    setState(() {
      _allModules = modules;
      _filteredModules = modules;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      if (query.trim().isEmpty) {
        _filteredModules = _allModules;
      } else {
        final q = query.toLowerCase().trim();
        _filteredModules = _allModules.where((m) {
          return m.title.toLowerCase().contains(q) ||
              m.description.toLowerCase().contains(q) ||
              m.level.toLowerCase().contains(q) ||
              m.subject.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // ── Konten utama ──
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Search Bar ──
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _SearchBar(
                    controller: _searchController,
                    query: _searchQuery,
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Header "Modul Tersedia" ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Modul Tersedia',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Daftar Modul ──
                Expanded(
                  child: _filteredModules.isEmpty
                      ? _EmptySearchState(query: _searchQuery)
                      : ListView.separated(
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            bottom: 120, // ruang untuk FAB + navbar
                          ),
                          itemCount: _filteredModules.length,
                          separatorBuilder: (a, b) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final module = _filteredModules[index];
                            return _ModulCard(
                              module: module,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ModulMateriScreen(),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // ── Floating Action Button (+) ──
          Positioned(
            right: 20,
            bottom: 100, // di atas navbar
            child: _FloatingAddButton(
              onTap: () {
                // TODO: navigasi ke screen tambah modul baru
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.controller,
    required this.query,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: 'Cari module',
          hintStyle: const TextStyle(
            fontSize: 14,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 16, right: 10),
            child: Icon(
              LucideIcons.search,
              size: 18,
              color: Color(0xFF94A3B8),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x,
                      size: 16, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modul Card — title, deskripsi, badge row (level, subject, soal, diskusi)
// ─────────────────────────────────────────────────────────────────────────────

class _ModulCard extends StatelessWidget {
  final ModuleModel module;
  final VoidCallback? onTap;

  const _ModulCard({required this.module, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Judul ──
            Text(
              module.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),

            // ── Deskripsi singkat ──
            Text(
              module.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),

            // ── Badge Row: Level, Subject, Soal, Diskusi ──
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Badge(label: module.level),
                _Badge(label: module.subject),
                _Badge(label: '${module.totalQuestions} Soal'),
                _Badge(label: '${module.discussionCount} Diskusi'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge pill ──
class _Badge extends StatelessWidget {
  final String label;

  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF93C5FD), width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0066FF),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state saat search tidak menemukan hasil
// ─────────────────────────────────────────────────────────────────────────────

class _EmptySearchState extends StatelessWidget {
  final String query;

  const _EmptySearchState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.bookOpen,
            size: 48,
            color: Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ditemukan hasil\nuntuk "$query"',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF94A3B8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating Action Button (+)
// ─────────────────────────────────────────────────────────────────────────────

class _FloatingAddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FloatingAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF0066FF),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x440066FF),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          LucideIcons.plus,
          size: 26,
          color: Colors.white,
        ),
      ),
    );
  }
}
