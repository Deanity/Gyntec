import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/core.dart';
import '../models/session_history_model.dart';
import 'session_history_detail_screen.dart';

/// Tab Sesi Belajar — menampilkan riwayat sesi yang pernah dilakukan.
/// Setiap card bisa di-tap untuk membuka detail sesi.
class SessionHistoryScreen extends StatefulWidget {
  const SessionHistoryScreen({super.key});

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  List<SessionHistoryModel> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final raw = await rootBundle.loadString('assets/data/mock_data.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;

    if (mounted) {
      setState(() {
        _sessions = (json['sessionHistory'] as List)
            .map(
              (e) => SessionHistoryModel.fromJson(e as Map<String, dynamic>),
            )
            .toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Sesi Belajar Terakhir',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 16),
                  AppOfflineBanner(padding: EdgeInsets.zero),
                ],
              ),
            ),
          ),

          // List sesi
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: _sessions.length,
              separatorBuilder: (_, i) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final session = _sessions[index];
                return _SessionHistoryCard(
                  session: session,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          SessionHistoryDetailScreen(session: session),
                    ),
                  ),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card widget
// ---------------------------------------------------------------------------

/// Card sesi belajar: tanggal + badge level, judul, 3 stat chip.
class _SessionHistoryCard extends StatelessWidget {
  final SessionHistoryModel session;
  final VoidCallback onTap;

  const _SessionHistoryCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris atas: tanggal + badge level
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  session.date,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textPlaceholder,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                LevelBadge(level: session.level),
              ],
            ),
            const SizedBox(height: 6),

            // Judul sesi
            Text(
              session.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),

            // Stat row
            Row(
              children: [
                Expanded(
                  child: _StatChip(
                    value: '${session.studentCount}',
                    label: 'Siswa hadir',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatChip(value: session.subject, label: 'Mapel'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatChip(
                    value: '${session.durationMinutes}',
                    label: 'Menit',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Stat chip kecil — value bold atas, label abu bawah.
class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textPlaceholder,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
