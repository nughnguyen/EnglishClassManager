import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class CompactHeaderAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool loading;

  const CompactHeaderAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled
            ? AppColors.primary.withOpacity(.10)
            : AppColors.divider.withOpacity(.45),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    )
                  : Icon(
                      icon,
                      size: 21,
                      color:
                          enabled ? AppColors.primary : AppColors.textSecondary,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
