import 'package:flutter/material.dart';

Future<T?> showFormBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  double heightFactor = .9,
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
