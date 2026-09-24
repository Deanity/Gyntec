import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../utils/models.dart';

/// Menampilkan modal popup "Tambah Peserta" sesuai desain Figma.
/// Dipanggil via [showAddParticipantDialog].
void showAddParticipantDialog({
  required BuildContext context,
  required List<StudentModel> allStudents,
  required List<StudentModel> currentSelected,
  required ValueChanged<List<StudentModel>> onSave,
}) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Tutup',
    barrierColor: const Color(0x80CBD5E1), // abu-abu semi-transparan
    transitionDuration: const Duration(milliseconds: 220),
    transitionBuilder: (context, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      );
    },
    pageBuilder: (context, _, __) => _AddParticipantModal(
      allStudents: allStudents,
      currentSelected: currentSelected,
      onSave: onSave,
    ),
  );
}

/// Widget modal popup utama.
class _AddParticipantModal extends StatefulWidget {
  final List<StudentModel> allStudents;
  final List<StudentModel> currentSelected;
  final ValueChanged<List<StudentModel>> onSave;

  const _AddParticipantModal({
    required this.allStudents,
    required this.currentSelected,
    required this.onSave,
  });

  @override
  State<_AddParticipantModal> createState() => _AddParticipantModalState();
}

class _AddParticipantModalState extends State<_AddParticipantModal> {
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

  // ── Filter siswa berdasarkan query ──
  List<StudentModel> get _filteredStudents {
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

  // ── Siswa yang belum ada di daftar & cocok pencarian ──
  bool get _canAddManual {
    final q = _searchQuery.trim();
    if (q.isEmpty) return false;
    final exactMatch = widget.allStudents.any(
      (s) => s.name.toLowerCase() == q.toLowerCase(),
    );
    return !exactMatch;
  }

  void _addStudent(StudentModel student) {
    final already = _selected.any((s) => s.id == student.id);
    if (already) return;
    setState(() {
      _selected.add(student);
      _searchController.clear();
      _searchQuery = '';
    });
  }

  void _addManual() {
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

  void _removeStudent(StudentModel student) {
    setState(() => _selected.removeWhere((s) => s.id == student.id));
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final filtered = _filteredStudents;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // ── Area kosong atas (klik untuk tutup) ──
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),

          // ── Konten modal ──
          Container(
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.65,
            ),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Judul Kartu ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Text(
                    'Peserta Sebelumnya',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),

                // ── List peserta terpilih + hasil pencarian ──
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 8),
                    children: [
                      // Peserta yang sudah dipilih
                      if (_selected.isEmpty && _searchQuery.trim().isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: Text(
                            'Belum ada peserta. Cari di bawah.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        )
                      else ...[
                        ..._selected.map(
                          (student) => _ParticipantRow(
                            student: student,
                            onRemove: () => _removeStudent(student),
                          ),
                        ),
                      ],

                      // Hasil pencarian (bukan yang sudah dipilih)
                      if (filtered.isNotEmpty) ...[
                        if (_selected.isNotEmpty)
                          const Divider(
                            height: 1,
                            color: Color(0xFFF1F5F9),
                            indent: 20,
                            endIndent: 20,
                          ),
                        ...filtered
                            .where(
                              (s) => !_selected.any((sel) => sel.id == s.id),
                            )
                            .map(
                              (student) => _SearchResultRow(
                                student: student,
                                onAdd: () => _addStudent(student),
                              ),
                            ),
                      ],

                      // Tombol "Tambah [nama]" jika tidak ada di daftar
                      if (_canAddManual && filtered.isEmpty)
                        _TambahManualButton(
                          name: _searchQuery.trim(),
                          onTap: _addManual,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),

          // ── Sticky Bottom: Search + Selesai ──
          Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 24),
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
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Icon(
                        LucideIcons.search,
                        size: 18,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) =>
                              setState(() => _searchQuery = v),
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
                      const SizedBox(width: 16),
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

// ── Row peserta yang sudah dipilih (dengan icon hapus) ──
class _ParticipantRow extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onRemove;

  const _ParticipantRow({required this.student, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
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
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              LucideIcons.x,
              size: 16,
              color: Color(0xFFCBD5E1),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Row hasil pencarian (bisa di-tap untuk tambah) ──
class _SearchResultRow extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onAdd;

  const _SearchResultRow({required this.student, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onAdd,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '${student.schoolClass} • NIS ${student.nis}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
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

// ── Tombol "Tambah [nama]" untuk input manual ──
class _TambahManualButton extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _TambahManualButton({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
                  fontWeight: FontWeight.w500,
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

// ── Backward-compat alias (tidak dipakai, tapi jaga export tetap valid) ──
typedef AddParticipantBottomSheet = _AddParticipantModal;
