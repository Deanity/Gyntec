import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../session/models/student_model.dart';

/// Screen tambah peserta baru.
///
/// Layout:
/// - Background abu-abu gelap (dim overlay feel)
/// - AppBar tipis: back chevron + "Peserta"
/// - Area atas: kosong / semi-transparent (area gelap)
/// - Card putih "Tambah Peserta" — pinned tepat di atas search bar
/// - Search bar + tombol Selesai di paling bawah
///
/// State flow:
/// 1. Awal: card hanya tampilkan judul + deskripsi instruksi
/// 2. Ketik nama → suggestion chip "Tambah [nama]" muncul di dalam card
/// 3. Tap suggestion → nama masuk list di card (dengan × hapus), search clear
/// 4. Repeat sampai semua peserta ditambahkan → tekan Selesai
class AddStudentScreen extends StatefulWidget {
  final List<StudentModel> existingStudents;

  const AddStudentScreen({super.key, required this.existingStudents});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final List<String> _addedNames = [];
  String _query = '';

  /// Suggestion dari existing students yang match query
  StudentModel? get _matchedStudent {
    if (_query.trim().isEmpty) return null;
    final q = _query.trim().toLowerCase();
    try {
      return widget.existingStudents.firstWhere(
        (s) =>
            s.name.toLowerCase().contains(q) &&
            !_addedNames
                .map((n) => n.toLowerCase())
                .contains(s.name.toLowerCase()),
      );
    } catch (_) {
      return null;
    }
  }

  /// Nama bebas (tidak ada di existing) untuk ditambahkan langsung
  String? get _freeQueryName {
    final trimmed = _query.trim();
    if (trimmed.isEmpty) return null;
    // sudah ada di existing → pakai _matchedStudent
    final existsInAll = widget.existingStudents
        .any((s) => s.name.toLowerCase().contains(trimmed.toLowerCase()));
    if (existsInAll) return null;
    // sudah ada di added list
    if (_addedNames.any((n) => n.toLowerCase() == trimmed.toLowerCase())) {
      return null;
    }
    return trimmed;
  }

  String? get _suggestionName =>
      _matchedStudent?.name ?? _freeQueryName;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (_addedNames.any((n) => n.toLowerCase() == trimmed.toLowerCase())) {
      return;
    }
    setState(() {
      _addedNames.add(trimmed);
      _searchController.clear();
      _query = '';
    });
    _focusNode.requestFocus();
  }

  void _removeName(String name) {
    setState(() => _addedNames.remove(name));
  }

  void _onSelesai() {
    Navigator.of(context).pop(_addedNames);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      // Background abu-abu gelap — mirip dim overlay
      backgroundColor: const Color(0xFFDDDFE6),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── AppBar ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      LucideIcons.chevronLeft,
                      size: 22,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'Peserta',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // ── Spacer (area atas yang kosong & gelap) ─────────────────────
            const Spacer(),

            // ── Card "Tambah Peserta" — pinned di atas search bar ──────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _TambahCard(
                addedNames: _addedNames,
                suggestionName: _suggestionName,
                onAdd: _addName,
                onRemove: _removeName,
              ),
            ),

            const SizedBox(height: 16),

            // ── Search bar + tombol Selesai ────────────────────────────────
            AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: bottomInset > 0 ? bottomInset + 12 : 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search / tambah input
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: _query.isEmpty
                          ? AppColors.surface
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: _addedNames.isEmpty
                            ? 'Cari atau tambah peserta'
                            : 'Tambah Peserta',
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
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 15),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) _addName(val.trim());
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Tombol Selesai
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _onSelesai,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: const Text(
                        'Selesai',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

/// Card putih "Tambah Peserta" yang berisi:
/// - Judul + deskripsi saat kosong
/// - List nama yang sudah ditambahkan (dengan × hapus)
/// - Suggestion chip untuk nama berikutnya
class _TambahCard extends StatelessWidget {
  final List<String> addedNames;
  final String? suggestionName;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  const _TambahCard({
    required this.addedNames,
    required this.suggestionName,
    required this.onAdd,
    required this.onRemove,
  });

  bool get _isEmpty => addedNames.isEmpty && suggestionName == null;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: _isEmpty ? 28 : 20,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: _isEmpty ? _buildEmptyState() : _buildFilledState(),
      ),
    );
  }

  /// State awal — judul + deskripsi terpusat
  Widget _buildEmptyState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Text(
          'Tambah Peserta',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Ketik nama peserta untuk menambahkan peserta baru.\nAnda dapat menambahkan lebih dari 1 peserta',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  /// State setelah ada konten — list nama + suggestion
  Widget _buildFilledState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Judul kiri
        const Text(
          'Tambah Peserta',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Nama-nama yang sudah ditambahkan
        ...addedNames.map(
          (name) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => onRemove(name),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(
                      Icons.close,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Suggestion chip
        if (suggestionName != null) ...[
          if (addedNames.isNotEmpty) const SizedBox(height: 2),
          _SuggestionChip(
            name: suggestionName!,
            onTap: () => onAdd(suggestionName!),
          ),
        ],
      ],
    );
  }
}

/// Chip abu-abu dengan icon user-plus dan label "Tambah [nama]"
class _SuggestionChip extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _SuggestionChip({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              LucideIcons.userRoundPlus,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(
              'Tambah $name',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
