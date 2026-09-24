import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../utils/models.dart';

/// Bottom sheet untuk menambahkan peserta didik.
/// Desain: background abu-abu, kartu putih berisi daftar peserta terpilih,
/// search bar sticky di bawah, dan tombol Selesai.
class AddParticipantBottomSheet extends StatefulWidget {
  final List<StudentModel> allStudents;
  final List<StudentModel> currentSelected;
  final ValueChanged<List<StudentModel>> onSave;

  const AddParticipantBottomSheet({
    super.key,
    required this.allStudents,
    required this.currentSelected,
    required this.onSave,
  });

  @override
  State<AddParticipantBottomSheet> createState() =>
      _AddParticipantBottomSheetState();
}

class _AddParticipantBottomSheetState
    extends State<AddParticipantBottomSheet> {
  late List<StudentModel> _selected;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.currentSelected);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Hasil pencarian dari daftar siswa ──
  List<StudentModel> get _searchResults {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return [];
    return widget.allStudents
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.nis.toLowerCase().contains(q) ||
              s.schoolClass.toLowerCase().contains(q),
        )
        .toList();
  }

  // ── Tambah peserta dari hasil pencarian ──
  void _addStudent(StudentModel student) {
    final alreadyIn = _selected.any((s) => s.id == student.id);
    if (alreadyIn) return;
    setState(() {
      _selected.add(student);
      _searchController.clear();
      _searchQuery = '';
    });
  }

  // ── Tambah peserta baru manual (nama diketik langsung) ──
  void _addManualFromSearch() {
    final name = _searchQuery.trim();
    if (name.isEmpty) return;

    final newStudent = StudentModel(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      nis: '${DateTime.now().millisecondsSinceEpoch % 100000}',
      schoolClass: 'Peserta Baru',
    );

    setState(() {
      _selected.add(newStudent);
      _searchController.clear();
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final results = _searchResults;
    final showAddButton = _searchQuery.trim().isNotEmpty && results.isEmpty;

    return Container(
      // ── Full-height abu-abu (bukan white sheet) ──
      color: const Color(0xFFE8EAF0),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        children: [
          // ── Top Bar: "< Peserta" ──
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      LucideIcons.chevronLeft,
                      size: 22,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Text(
                    'Peserta',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Area Tengah: Kartu Putih ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Judul kartu ──
                    const Text(
                      'Peserta Sebelumnya',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── List peserta yang sudah dipilih ──
                    if (_selected.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Belum ada peserta dipilih.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      )
                    else
                      ...List.generate(_selected.length, (index) {
                        final student = _selected[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.userRound,
                                size: 20,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  student.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                    // ── Hasil pencarian / tombol tambah ──
                    if (results.isNotEmpty) ...[
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 10),
                      ...results.map(
                        (student) => _SearchResultItem(
                          student: student,
                          onTap: () => _addStudent(student),
                        ),
                      ),
                    ],

                    // ── Tombol "Tambah [nama]" jika tidak ditemukan di daftar ──
                    if (showAddButton) ...[
                      const SizedBox(height: 4),
                      _AddNewButton(
                        name: _searchQuery.trim(),
                        onTap: _addManualFromSearch,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom Sticky: Search + Selesai ──
          Container(
            color: const Color(0xFFE8EAF0),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search bar
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      const Icon(
                        LucideIcons.search,
                        size: 18,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Cari atau tambah peserta',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFCBD5E1),
                            ),
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Tombol Selesai
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onSave(_selected);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Selesai',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget: Baris hasil pencarian ──
class _SearchResultItem extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onTap;

  const _SearchResultItem({required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            const Icon(
              LucideIcons.userRound,
              size: 20,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'NIS: ${student.nis} • ${student.schoolClass}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.plus,
              size: 18,
              color: Color(0xFF0066FF),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget: Tombol "Tambah [nama]" untuk input manual ──
class _AddNewButton extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _AddNewButton({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(
              LucideIcons.userRoundPlus,
              size: 20,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tambah $name',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
