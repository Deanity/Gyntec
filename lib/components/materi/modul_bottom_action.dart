import 'package:flutter/material.dart';
import '../common/button.dart';

enum MateriTab { materi, diskusi, quiz }

/// Bottom action bar kustom untuk modul materi:
/// - Pill segment tab switcher (Materi, Diskusi, Quiz) di tengah
/// - Tombol aksi utama "Mulai Sesi"
class ModulBottomAction extends StatelessWidget {
  final MateriTab activeTab;
  final ValueChanged<MateriTab> onTabChanged;
  final VoidCallback onStartSession;

  const ModulBottomAction({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
    required this.onStartSession,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pill capsule tab switcher di tengah
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: MateriTab.values.map((tab) {
                    final isActive = tab == activeTab;
                    final label = switch (tab) {
                      MateriTab.materi => 'Materi',
                      MateriTab.diskusi => 'Diskusi',
                      MateriTab.quiz => 'Quiz',
                    };
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTabChanged(tab),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF0066FF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive
                                ? Colors.white
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Tombol Mulai Sesi
            CustomButton(
              label: 'Mulai Sesi',
              onPressed: onStartSession,
              backgroundColor: const Color(0xFF0066FF),
              borderRadius: 28,
              height: 52,
            ),
          ],
        ),
      ),
    );
  }
}
