import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Custom Top App Bar dengan tombol back (arrow) di sebelah kiri dan teks navbar di sampingnya (rata kiri).
class CustomTopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final bool showBackButton;

  const CustomTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              if (showBackButton) ...[
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onBack ?? () => Navigator.of(context).maybePop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      LucideIcons.chevronLeft,
                      size: 22,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
