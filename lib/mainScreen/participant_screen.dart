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

class _ParticipantScreenState extends State<ParticipantScreen> {
  ModulDetailModel? _modul;
  List<StudentModel> _allStudents = [];
  final List<StudentModel> _participants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
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

  void _openAddParticipantSheet() {
    showAddParticipantDialog(
      context: context,
      allStudents: _allStudents,
      currentSelected: _participants,
      onSave: (updated) {
        setState(() {
          _participants.clear();
          _participants.addAll(updated);
        });
      },
    );
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Top App Bar ("< Peserta") ──
          CustomTopBar(
            title: 'Peserta',
            onBack: () => Navigator.of(context).maybePop(),
          ),

          // ── 2. Informasi Modul (Judul & Chip Badges) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

                // Baris Badges: SMA | IPA | 30 Soal | 1 Diskusi
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

          // ── 3. Area Tengah: Status Kosong atau Daftar Peserta ──
          Expanded(
            child: _participants.isEmpty
                ? const EmptyParticipantView()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    itemCount: _participants.length,
                    itemBuilder: (context, index) {
                      final student = _participants[index];
                      return ParticipantCard(
                        student: student,
                        onRemove: () {
                          setState(() {
                            _participants.removeAt(index);
                          });
                        },
                      );
                    },
                  ),
          ),

          // ── 4. Bottom Controls Area ──
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 16,
                top: 8,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tombol "Tambah Peserta" (kanan atas tombol Mulai Sesi)
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: _openAddParticipantSheet,
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

                      // Tombol "Mulai Sesi" (Full width biru)
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
        );
  }
}
