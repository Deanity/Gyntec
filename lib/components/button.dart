import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? textColor;
  final double height;
  final double borderRadius;
  final double fontSize;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.backgroundColor,
    this.textColor,
    this.height = 52,
    this.borderRadius = 28,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    const defaultBgColor = Color(0xFF0066FF);
    final effectiveBgColor = backgroundColor ?? defaultBgColor;
    const effectiveTextColor = Colors.white;

    Widget childContent;
    if (isLoading) {
      childContent = const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else if (icon != null) {
      childContent = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor ?? effectiveTextColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    } else {
      childContent = Text(
        label,
        style: TextStyle(
          color: textColor ?? effectiveTextColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final buttonWidget = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: effectiveBgColor,
        foregroundColor: textColor ?? effectiveTextColor,
        disabledBackgroundColor: effectiveBgColor.withValues(alpha: 0.6),
        minimumSize: Size(isFullWidth ? double.infinity : 0, height),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      child: childContent,
    );

    return isFullWidth
        ? SizedBox(width: double.infinity, height: height, child: buttonWidget)
        : SizedBox(height: height, child: buttonWidget);
  }
}
