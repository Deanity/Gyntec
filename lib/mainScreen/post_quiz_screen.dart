import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../components/common/button.dart';
import '../utils/models.dart';

/// Screen "Post Quiz" yang muncul setelah user menyelesaikan kuis.
/// Menampilkan rekap modul, perolehan poin per kelompok, daftar anggota,
/// dan tombol "Kembali ke Beranda".
class PostQuizScreen extends StatefulWidget {
  final ModulDetailModel modul;
  final List<DiscussionGroupModel> groups;
  final List<StudentModel> participants;

  const PostQuizScreen({
    super.key,
    required this.modul,
    required this.groups,
    required this.participants,
  });

  @override
  State<PostQuizScreen> createState() => _PostQuizScreenState();
}

class _PostQuizScreenState extends State<PostQuizScreen> {
  // Track status ekspansi masing-masing kelompok (default kelompok 1 terbuka)
  final Set<int> _expandedGroupNumbers = {1};

  // Mock poin per kelompok sesuai mockup (Rajawali: 3, Garuda: 2, Merpati: 1)
  final Map<int, int> _groupScores = {1: 3, 2: 2, 3: 1};

  void _toggleGroupExpansion(int groupNumber) {
    setState(() {
      if (_expandedGroupNumbers.contains(groupNumber)) {
        _expandedGroupNumbers.remove(groupNumber);
      } else {
        _expandedGroupNumbers.add(groupNumber);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final modul = widget.modul;

    // Daftar anggota mandiri (sesuai mockup: Reza Kecap, Reza Arap, Ryan Pekalongan)
    final individualMembers = widget.participants.isNotEmpty
        ? widget.participants.take(5).toList()
        : const [
            StudentModel(id: 'a1', name: 'Reza Kecap'),
            StudentModel(id: 'a2', name: 'Reza Arap'),
            StudentModel(id: 'a3', name: 'Ryan Pekalongan'),
          ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Navigation Bar ("< Post Quiz") ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        LucideIcons.chevronLeft,
                        size: 22,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Post Quiz',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable Body Content ──
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul Modul
                    Text(
                      modul.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Badges Tag Row (SMA, IPA, 30 Soal, 1 Diskusi)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildBadge(modul.level),
                        _buildBadge(modul.subject),
                        _buildBadge('${modul.totalQuestions} Soal'),
                        _buildBadge('${modul.discussionCount} Diskusi'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section: Kelompok
                    const Text(
                      'Kelompok',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Accordion List Kelompok
                    ...widget.groups.map((group) {
                      final isExpanded =
                          _expandedGroupNumbers.contains(group.number);
                      final score = _groupScores[group.number] ?? 1;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildGroupAccordionCard(
                          group: group,
                          score: score,
                          isExpanded: isExpanded,
                          onToggle: () => _toggleGroupExpansion(group.number),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // Section: Anggota
                    const Text(
                      'Anggota',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // List Anggota Pill Cards
                    ...individualMembers.map(
                      (student) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFAFA),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.userRound,
                                size: 18,
                                color: Color(0xFF475569),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                student.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ── Bottom Action Button ("Kembali ke Beranda") ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFF1F5F9),
                    width: 1,
                  ),
                ),
              ),
              child: CustomButton(
                label: 'Kembali ke Beranda',
                onPressed: () {
                  // Kembali ke halaman Home / Screen awal
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                backgroundColor: const Color(0xFF0066FF),
                borderRadius: 28,
                height: 52,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF93C5FD),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0066FF),
        ),
      ),
    );
  }

  Widget _buildGroupAccordionCard({
    required DiscussionGroupModel group,
    required int score,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card (Bisa diklik untuk expand/collapse)
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total $score poin',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 20,
                    color: const Color(0xFF475569),
                  ),
                ],
              ),
            ),
          ),

          // Konten Anggota saat Expanded
          if (isExpanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: group.members.map((member) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.userRound,
                          size: 16,
                          color: Color(0xFF475569),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          member.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
