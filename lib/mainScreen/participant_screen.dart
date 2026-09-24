import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../components/components.dart';
import '../utils/models.dart';

/// Screen "Peserta" (Add Participant Screen) yang muncul setelah user menekan
/// tombol "Mulai Sesi" pada Module Materi Screen.
class ParticipantScreen extends StatefulWidget {
  final ModulDetailModel? modul;

  const ParticipantScreen({super.key, this.modul});

  @override
  State<ParticipantScreen> createState() => _ParticipantScreenState();
}

class _ParticipantScreenState extends State<ParticipantScreen>
    with SingleTickerProviderStateMixin {
  ModulDetailModel? _modul;
  List<StudentModel> _allStudents = [];
  final List<StudentModel> _participants = [];
  bool _isLoading = true;

  // ── Add Participant Overlay State ──
  bool _isAddMode = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Animation controller untuk transisi overlay
  late final AnimationController _animController;
  late final Animation<double> _overlayFade;
  late final Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _initData();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _overlayFade = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    final raw = await rootBundle.loadString('lib/utils/data.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final allStudents = (json['students'] as List? ?? [])
        .map((e) => StudentModel.fromJson(e as Map<String, dynamic>))
        .toList();

    ModulDetailModel modul;
    if (widget.modul != null) {
      modul = widget.modul!;
    } else {
      modul = ModulDetailModel.fromJson(
          json['modulDetail'] as Map<String, dynamic>);
    }

    setState(() {
      _modul = modul;
      _allStudents = allStudents;
      _isLoading = false;
    });
  }

  /// Masuk ke mode "tambah peserta" dengan animasi transformasi
  void _enterAddMode() {
    setState(() {
      _isAddMode = true;
      _searchQuery = '';
      _searchController.clear();
    });
    _animController.forward(from: 0);
  }

  /// Keluar dari mode "tambah peserta" (tombol Selesai)
  void _exitAddMode() {
    _animController.reverse().then((_) {
      if (mounted) {
        setState(() => _isAddMode = false);
      }
    });
  }

  /// Toggle seleksi peserta dari daftar saran
  void _toggleParticipant(StudentModel student) {
    setState(() {
      final exists = _participants.any((s) => s.id == student.id);
      if (exists) {
        _participants.removeWhere((s) => s.id == student.id);
      } else {
        _participants.add(student);
        // Clear search setelah memilih
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  /// Tambah peserta dari query search (jika nama belum ada di allStudents)
  void _addFromSearch() {
    final name = _searchQuery.trim();
    if (name.isEmpty) return;

    // Cek apakah sudah ada siswa dengan nama persis
    final existing = _allStudents
        .where((s) => s.name.toLowerCase() == name.toLowerCase())
        .toList();

    if (existing.isNotEmpty) {
      _toggleParticipant(existing.first);
    } else {
      // Tambah sebagai peserta baru custom
      final newStudent = StudentModel(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
      );
      setState(() {
        _allStudents.add(newStudent);
        _participants.add(newStudent);
        _searchController.clear();
        _searchQuery = '';
      });
    }
  }

  /// Daftar siswa yang cocok dengan query pencarian.
  /// Menggunakan prefix match (startsWith) per kata agar hasil lebih relevan
  /// saat user baru mengetik 1–2 huruf.
  List<StudentModel> get _filteredSuggestions {
    if (_searchQuery.trim().isEmpty) return [];
    final q = _searchQuery.toLowerCase().trim();
    return _allStudents.where((s) {
      final nameLower = s.name.toLowerCase();
      final nameWords = nameLower.split(' ');
      return nameLower.startsWith(q) ||
          nameWords.any((word) => word.startsWith(q));
    }).take(6).toList();
  }

  void _startSession() {
    if (_participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Silahkan tambahkan minimal 1 peserta untuk memulai sesi.',
          ),
          backgroundColor: Color(0xFFEF4444),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Sesi Dimulai',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Sesi pembelajaran untuk "${_modul?.title}" berhasil dimulai dengan ${_participants.length} peserta.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final modul = _modul!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Layer 1: Konten Utama ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Top App Bar ("< Peserta") ──
              CustomTopBar(
                title: 'Peserta',
                onBack: _isAddMode
                    ? _exitAddMode
                    : () => Navigator.of(context).maybePop(),
              ),

              // ── 2. Informasi Modul (hanya tampil saat BUKAN add mode) ──
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: _isAddMode
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              modul.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ParticipantBadge(label: modul.level),
                                ParticipantBadge(label: modul.subject),
                                ParticipantBadge(
                                  label: '${modul.totalQuestions} Soal',
                                ),
                                ParticipantBadge(
                                  label: '${modul.discussionCount} Diskusi',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),

              // ── 3. Area Tengah ──
              Expanded(
                child: _isAddMode
                    // Sembunyikan saat add mode — biar tidak kelihatan di balik overlay
                    ? const SizedBox.shrink()
                    : _participants.isEmpty
                        ? const EmptyParticipantView()
                        : Align(
                            alignment: Alignment.topCenter,
                            child: _ParticipantSummaryCard(
                              participants: _participants,
                            ),
                          ),
              ),

              // ── 4. Bottom Controls (mode normal) ──

              if (!_isAddMode)
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: 16,
                      top: 8,
                    ),
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tombol "Tambah Peserta"
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: _enterAddMode,
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFFCBD5E1),
                                  width: 1.2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x06000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.userRoundPlus,
                                    size: 18,
                                    color: Color(0xFF1E293B),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Tambah Peserta',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Tombol "Mulai Sesi"
                        CustomButton(
                          label: 'Mulai Sesi',
                          onPressed: _startSession,
                          backgroundColor: const Color(0xFF0066FF),
                          textColor: Colors.white,
                          borderRadius: 26,
                          height: 52,
                          fontSize: 16,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // ── Layer 2: Overlay Add Mode (muncul di atas konten) ──
          if (_isAddMode)
            FadeTransition(
              opacity: _overlayFade,
              child: _AddParticipantOverlay(
                participants: _participants,
                filteredSuggestions: _filteredSuggestions,
                searchQuery: _searchQuery,
                searchController: _searchController,
                onSearchChanged: (val) => setState(() => _searchQuery = val),
                onToggleParticipant: _toggleParticipant,
                onAddFromSearch: _addFromSearch,
                onDone: _exitAddMode,
                slideAnimation: _cardSlide,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card ringkasan "Peserta Sesi Ini" — tampil di area tengah setelah add mode selesai
// ─────────────────────────────────────────────────────────────────────────────

class _ParticipantSummaryCard extends StatelessWidget {
  final List<StudentModel> participants;

  const _ParticipantSummaryCard({required this.participants});

  @override
  Widget build(BuildContext context) {
    // Batas maksimal tinggi daftar peserta (agar tidak overflow saat peserta banyak)
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.35;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Peserta Sesi Ini',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxListHeight),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: participants.asMap().entries.map((entry) {
                    final index = entry.key;
                    final s = entry.value;
                    final isLast = index == participants.length - 1;
                    return Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.userRound,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              s.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Widget Overlay "Tambah Peserta" — muncul ketika _isAddMode = true
// ─────────────────────────────────────────────────────────────────────────────

class _AddParticipantOverlay extends StatelessWidget {
  final List<StudentModel> participants;
  final List<StudentModel> filteredSuggestions;
  final String searchQuery;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<StudentModel> onToggleParticipant;
  final VoidCallback onAddFromSearch;
  final VoidCallback onDone;
  final Animation<Offset> slideAnimation;

  const _AddParticipantOverlay({
    required this.participants,
    required this.filteredSuggestions,
    required this.searchQuery,
    required this.searchController,
    required this.onSearchChanged,
    required this.onToggleParticipant,
    required this.onAddFromSearch,
    required this.onDone,
    required this.slideAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      color: const Color(0xFF1A1A2E).withValues(alpha: 0.35),
      child: Column(
        children: [
          // Spacer di atas — area kosong abu-abu (bisa diklik untuk dismiss)
          Expanded(
            child: GestureDetector(
              onTap: onDone,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),

          // ── Card putih — 1 section, isinya berubah sesuai state ──
          SlideTransition(
            position: slideAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _CardContent(
                participants: participants,
                searchQuery: searchQuery,
                filteredSuggestions: filteredSuggestions,
                onToggle: onToggleParticipant,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Search Bar & Tombol Selesai ──
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: bottomInset > 0 ? bottomInset + 8 : 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search field — hasil muncul di card atas, BUKAN dropdown terpisah
                _SearchField(
                  controller: searchController,
                  query: searchQuery,
                  onChanged: onSearchChanged,
                  onAdd: onAddFromSearch,
                ),
                const SizedBox(height: 12),

                // Tombol "Selesai"
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
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

// ─────────────────────────────────────────────────────────────────────────────
// _CardContent — router: pilih tampilan card berdasarkan state
// ─────────────────────────────────────────────────────────────────────────────

class _CardContent extends StatelessWidget {
  final List<StudentModel> participants;
  final String searchQuery;
  final List<StudentModel> filteredSuggestions;
  final ValueChanged<StudentModel> onToggle;

  const _CardContent({
    required this.participants,
    required this.searchQuery,
    required this.filteredSuggestions,
    required this.onToggle,
  });

  bool get _isSearching => searchQuery.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    // State 1: Ada query → tampilkan hasil search DI DALAM card
    if (_isSearching) {
      return _SearchResultContent(
        query: searchQuery,
        suggestions: filteredSuggestions,
        selectedIds: participants.map((s) => s.id).toSet(),
        onToggle: onToggle,
      );
    }

    // State 2: Tidak ada query, belum ada peserta → empty state
    if (participants.isEmpty) {
      return const _EmptyStateCard();
    }

    // State 3: Tidak ada query, ada peserta → daftar peserta
    return _ParticipantListCard(participants: participants, onToggle: onToggle);
  }
}

// ── Card: Empty state ──
class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EmptyParticipantIcon(size: 52, color: Color(0xFF1E293B)),
        SizedBox(height: 14),
        Text(
          'Belum ada Peserta',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 6),
        Text(
          'Silahkan tambah peserta didik untuk memulai sesi pembelajaran',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Card: Hasil search ──
class _SearchResultContent extends StatelessWidget {
  final String query;
  final List<StudentModel> suggestions;
  final Set<String> selectedIds;
  final ValueChanged<StudentModel> onToggle;

  const _SearchResultContent({
    required this.query,
    required this.suggestions,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Tidak ada hasil pencarian
    if (suggestions.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.userRoundPlus,
              size: 36, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            'Tidak ditemukan hasil untuk "$query"',
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          // Tawarkan tambah manual
          InkWell(
            onTap: () => onToggle(
              StudentModel(
                id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                name: query.trim(),
              ),
            ),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.userRoundPlus,
                      size: 17, color: Color(0xFF0066FF)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tambah "${query.trim()}"',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0066FF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Ada hasil pencarian — tampilkan list langsung di card
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hasil pencarian "$query"',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        ...suggestions.map((s) {
          final isSelected = selectedIds.contains(s.id);
          return InkWell(
            onTap: () => onToggle(s),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? LucideIcons.circleCheckBig
                        : LucideIcons.userRound,
                    size: 18,
                    color: isSelected
                        ? const Color(0xFF0066FF)
                        : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF0066FF)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Text(
                      'Dipilih',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0066FF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}


// ── Card: Daftar peserta yang sudah dipilih ──
class _ParticipantListCard extends StatelessWidget {
  final List<StudentModel> participants;
  final ValueChanged<StudentModel> onToggle;

  const _ParticipantListCard({
    required this.participants,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Peserta Sebelumnya',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        ...participants.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.userRound,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                // Tombol hapus ×
                GestureDetector(
                  onTap: () => onToggle(s),
                  child: const Icon(
                    LucideIcons.x,
                    size: 16,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


// ── Search Field (tanpa dropdown — hasil tampil di card) ──
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onAdd;

  const _SearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: (_) => onAdd(),
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Cari atau tambah peserta',
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
        prefixIcon: const Icon(LucideIcons.search,
            size: 18, color: Color(0xFF94A3B8)),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Color(0xFF0066FF), width: 1.5),
        ),
      ),
    );
  }
}
