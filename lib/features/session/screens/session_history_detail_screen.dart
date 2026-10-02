import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/level_badge.dart';
import '../models/session_history_model.dart';

/// Halaman detail riwayat sesi belajar.
///
/// Menampilkan:
/// - Header: judul sesi + badge-badge info (level, mapel, soal, diskusi)
/// - Section "Kelompok": accordion per kelompok (nama, poin, anggota)
/// - Section "Anggota": flat list semua peserta
class SessionHistoryDetailScreen extends StatefulWidget {
  final SessionHistoryModel session;

  const SessionHistoryDetailScreen({super.key, required this.session});

  @override
  State<SessionHistoryDetailScreen> createState() =>
      _SessionHistoryDetailScreenState();
}

class _SessionHistoryDetailScreenState
    extends State<SessionHistoryDetailScreen> {
  /// Track kelompok mana yang sedang expanded (accordion)
  late List<bool> _expanded;

  @override
  void initState() {
    super.initState();
    // Buka kelompok pertama by default
    _expanded = List.generate(
      widget.session.groups.length,
      (i) => i == 0,
    );
  }

  void _toggleGroup(int index) {
    setState(() => _expanded[index] = !_expanded[index]);
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
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
                      'Sesi Belajar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Judul sesi ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                session.title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
            ),
          ),

          // ── Badge row: level, mapel, soal, diskusi ────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  LevelBadge(level: session.level),
                  _InfoBadge(label: session.subject),
                  _InfoBadge(label: '${session.totalQuestions} Soal'),
                  _InfoBadge(
                    label: '${session.discussionCount} Diskusi',
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // ── Section Kelompok ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Kelompok',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: session.groups.length,
              separatorBuilder: (_, i) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final group = session.groups[index];
                final isExpanded = _expanded[index];
                return _GroupAccordionCard(
                  group: group,
                  isExpanded: isExpanded,
                  onToggle: () => _toggleGroup(index),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // ── Section Anggota ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Anggota',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: session.members.length,
              separatorBuilder: (_, i) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _MemberRow(name: session.members[index]),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

/// Badge info kecil (level, mapel, soal, diskusi) — sama style dengan LevelBadge
/// tapi warna latar lebih netral.
class _InfoBadge extends StatelessWidget {
  final String label;
  const _InfoBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Accordion card untuk satu kelompok diskusi.
/// Collapsed: tampilkan nama + poin + chevron.
/// Expanded: tambahkan list anggota di bawahnya.
class _GroupAccordionCard extends StatelessWidget {
  final SessionGroupModel group;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _GroupAccordionCard({
    required this.group,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header baris: nama + chevron
            Row(
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
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total ${group.totalPoints} poin',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: const Icon(
                    LucideIcons.chevronDown,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            // Anggota — hanya tampil saat expanded
            if (isExpanded) ...[
              const SizedBox(height: 14),
              ...group.members.map(
                (name) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.userRound,
                        size: 17,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
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
            ],
          ],
        ),
      ),
    );
  }
}

/// Row satu anggota (di section Anggota) — bordered card tipis.
class _MemberRow extends StatelessWidget {
  final String name;
  const _MemberRow({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.userRound,
            size: 18,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
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
    );
  }
}
