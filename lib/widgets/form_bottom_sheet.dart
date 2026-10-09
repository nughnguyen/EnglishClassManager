import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

Future<T?> showFormBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  double heightFactor = .85,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      height: MediaQuery.sizeOf(sheetContext).height * heightFactor,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    ),
  );
}

class FormSheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const FormSheetHeader({
    super.key,
    required this.title,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Đóng',
          onPressed: onClose,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.textSecondary,
          ),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}
