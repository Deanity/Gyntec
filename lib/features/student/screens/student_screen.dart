import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'student_detail_screen.dart';
import 'add_student_screen.dart';
import '../../../core/core.dart';
import '../../session/models/student_model.dart';
import '../widgets/student_list_item.dart';

/// Halaman tab Murid — menampilkan daftar semua murid/peserta sesi.
///
/// Fitur:
/// - Search bar untuk filter murid berdasarkan nama
/// - List murid dengan jumlah sesi yang pernah diikuti
/// - FAB tombol "+" untuk menambah murid baru (placeholder)
class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<StudentModel> _allStudents = [];
  List<StudentModel> _filteredStudents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Memuat daftar murid dari mock_data.json
  Future<void> _loadStudents() async {
    final raw = await rootBundle.loadString('assets/data/mock_data.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final students = (json['students'] as List)
        .map((e) => StudentModel.fromJson(e as Map<String, dynamic>))
        .toList();

    if (mounted) {
      setState(() {
        _allStudents = students;
        _filteredStudents = students;
        _isLoading = false;
      });
    }
  }

  /// Filter murid berdasarkan query pencarian (case-insensitive)
  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredStudents = query.isEmpty
          ? _allStudents
          : _allStudents
              .where((s) => s.name.toLowerCase().contains(query))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _SearchBar(controller: _searchController),
                ),
              ),

              // Offline banner
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: AppOfflineBanner(padding: EdgeInsets.zero),
                ),
              ),

              // Header "List Murid / Peserta Sesi"
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text(
                    'List Murid / Peserta Sesi',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),

              // List murid
              _filteredStudents.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.userX,
                              size: 40,
                              color: AppColors.textPlaceholder,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Murid tidak ditemukan',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textPlaceholder,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList.separated(
                        itemCount: _filteredStudents.length,
                        separatorBuilder: (_, i) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => StudentListItem(
                          student: _filteredStudents[index],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StudentDetailScreen(
                                student: _filteredStudents[index],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

              // Bottom padding agar tidak tertutup FAB & nav bar
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          // FAB tombol tambah murid
          Positioned(
            right: 20,
            bottom: 96,
            child: _AddStudentFab(
              onTap: () async {
                final result = await Navigator.of(context).push<List<String>>(
                  MaterialPageRoute(
                    builder: (_) => AddStudentScreen(
                      existingStudents: _allStudents,
                    ),
                  ),
                );
                if (result != null && result.isNotEmpty) {
                  setState(() {
                    for (final name in result) {
                      // Hindari duplikat nama
                      final alreadyExists = _allStudents.any(
                        (s) =>
                            s.name.toLowerCase() == name.toLowerCase(),
                      );
                      if (!alreadyExists) {
                        final newStudent = StudentModel(
                          id: 'std_new_${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          sessionCount: 0,
                          sessions: const [],
                        );
                        _allStudents.insert(0, newStudent);
                      }
                    }
                    _onSearchChanged(); // refresh filtered list
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

/// Search bar dengan icon kaca pembesar, pill shape, background abu-abu muda.
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;

  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(50),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Cari Murid',
          hintStyle: const TextStyle(
            fontSize: 14,
            color: AppColors.textPlaceholder,
          ),
          prefixIcon: const Icon(
            LucideIcons.search,
            size: 18,
            color: AppColors.textPlaceholder,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        textInputAction: TextInputAction.search,
      ),
    );
  }
}

/// FAB biru bulat dengan icon "+".
class _AddStudentFab extends StatelessWidget {
  final VoidCallback onTap;

  const _AddStudentFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          LucideIcons.plus,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}
