import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Item navigasi untuk BottomNavBar.
class BottomNavItem {
  final IconData icon;
  final String label;

  const BottomNavItem({required this.icon, required this.label});
}

/// Bottom navigation bar dengan 4 tab: Beranda, Modul, Sesi Belajar, Murid.
/// Digunakan di semua halaman utama aplikasi.
class HomeBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<BottomNavItem> _items = [
    BottomNavItem(icon: LucideIcons.house, label: 'Beranda'),
    BottomNavItem(icon: LucideIcons.bookOpen, label: 'Modul'),
    BottomNavItem(icon: LucideIcons.clock, label: 'Sesi Belajar'),
    BottomNavItem(icon: LucideIcons.users, label: 'Murid'),
  ];

  const HomeBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final isActive = i == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: isActive
                            ? const Color(0xFF0066FF)
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isActive
                              ? const Color(0xFF0066FF)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
