import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../utils/models.dart';

/// Bottom sheet interaktif untuk memilih peserta didik dari data yang tersedia
/// atau menambahkan peserta baru secara manual.
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

class _AddParticipantBottomSheetState extends State<AddParticipantBottomSheet> {
  late List<StudentModel> _selected;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _manualNameController = TextEditingController();
  final TextEditingController _manualNisController = TextEditingController();
  bool _isManualMode = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.currentSelected);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _manualNameController.dispose();
    _manualNisController.dispose();
    super.dispose();
  }

  List<StudentModel> get _filteredStudents {
    if (_searchQuery.trim().isEmpty) {
      return widget.allStudents;
    }
    final q = _searchQuery.toLowerCase();
    return widget.allStudents
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.nis.toLowerCase().contains(q) ||
            s.schoolClass.toLowerCase().contains(q))
        .toList();
  }

  void _toggleSelection(StudentModel student) {
    setState(() {
      final exists = _selected.any((s) => s.id == student.id);
      if (exists) {
        _selected.removeWhere((s) => s.id == student.id);
      } else {
        _selected.add(student);
      }
    });
  }

  void _addManualStudent() {
    final name = _manualNameController.text.trim();
    if (name.isEmpty) return;

    final nis = _manualNisController.text.trim().isEmpty
        ? '${DateTime.now().millisecondsSinceEpoch % 100000}'
        : _manualNisController.text.trim();

    final newStudent = StudentModel(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      nis: nis,
      schoolClass: 'Peserta Baru',
    );

    setState(() {
      _selected.add(newStudent);
      _manualNameController.clear();
      _manualNisController.clear();
      _isManualMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle Bar ──
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Header Title & Toggle Mode ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isManualMode ? 'Tambah Peserta Manual' : 'Pilih Peserta Didik',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() => _isManualMode = !_isManualMode);
                },
                icon: Icon(
                  _isManualMode ? LucideIcons.list : LucideIcons.userPlus,
                  size: 16,
                  color: const Color(0xFF0066FF),
                ),
                label: Text(
                  _isManualMode ? 'Dari Daftar' : 'Input Baru',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0066FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_isManualMode) ...[
            // ── Input Manual Form ──
            TextField(
              controller: _manualNameController,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap Peserta',
                hintText: 'Contoh: Rian Anggoro',
                prefixIcon: const Icon(LucideIcons.user, size: 18),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _manualNisController,
              decoration: InputDecoration(
                labelText: 'Nomor Induk Siswa (NIS)',
                hintText: 'Contoh: 20240109',
                prefixIcon: const Icon(LucideIcons.hash, size: 18),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _addManualStudent,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Tambahkan ke Daftar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 14),
          ] else ...[
            // ── Search Bar ──
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Cari nama atau NIS siswa...',
                hintStyle:
                    const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon:
                    const Icon(LucideIcons.search, size: 18, color: Color(0xFF94A3B8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Daftar Siswa ──
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _filteredStudents.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  color: Color(0xFFF1F5F9),
                ),
                itemBuilder: (context, index) {
                  final student = _filteredStudents[index];
                  final isSelected =
                      _selected.any((s) => s.id == student.id);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(student),
                    contentPadding: EdgeInsets.zero,
                    activeColor: const Color(0xFF0066FF),
                    title: Text(
                      student.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    subtitle: Text(
                      'NIS: ${student.nis} • ${student.schoolClass}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Bottom Action Button ──
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onSave(_selected);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'Simpan (${_selected.length} Peserta)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
