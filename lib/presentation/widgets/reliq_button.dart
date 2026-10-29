import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum ReliqButtonVariant { primary, secondary, subtle }

/// A clean, tactile button designed for intentional mobile interaction.
class ReliqButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final ReliqButtonVariant variant;
  final bool isLoading;
  final double height;

  const ReliqButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.variant = ReliqButtonVariant.primary,
    this.isLoading = false,
    this.height = 54.0,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Border? border;

    switch (variant) {
      case ReliqButtonVariant.primary:
        bg = AppColors.textPrimary;
        fg = AppColors.background;
        border = null;
        break;
      case ReliqButtonVariant.secondary:
        bg = AppColors.surface;
        fg = AppColors.textPrimary;
        border = Border.all(color: AppColors.border, width: 1.0);
        break;
      case ReliqButtonVariant.subtle:
        bg = AppColors.surfaceElevated;
        fg = AppColors.textSecondary;
        border = null;
        break;
    }

    return Material(
      color: onTap == null ? bg.withOpacity(0.35) : bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: border,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(fg),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: fg),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: fg,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

