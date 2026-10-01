import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Model sederhana untuk data perangkat tujuan
class TargetDeviceModel {
  final String id;
  final String name;

  const TargetDeviceModel({required this.id, required this.name});
}

/// Card pilihan perangkat tujuan pengiriman modul.
/// Menampilkan avatar perangkat, nama perangkat, dan checkbox selectable.
///
/// Parameters:
/// - [device] : data perangkat (id, name)
/// - [isSelected] : apakah perangkat ini sedang dipilih
/// - [onTap] : callback saat card ditekan
class DeviceSelectCard extends StatelessWidget {
  final TargetDeviceModel device;
  final bool isSelected;
  final VoidCallback onTap;

  const DeviceSelectCard({
    super.key,
    required this.device,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0066FF)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            //  Avatar perangkat
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0066FF)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.userRound,
                size: 22,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 14),

            //  Nama perangkat
            Expanded(
              child: Text(
                device.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
            ),

            //  Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0066FF)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0066FF)
                      : const Color(0xFF334155),
                  width: 2.0,
                ),
              ),
              child: isSelected
                  ? const Icon(LucideIcons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
