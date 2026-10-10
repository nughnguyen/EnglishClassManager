import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

Future<TimeOfDay?> showTimeWheelPicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  required String title,
}) async {
  final hourController =
      FixedExtentScrollController(initialItem: initialTime.hour);
  final minuteController =
      FixedExtentScrollController(initialItem: initialTime.minute);
  try {
    return await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        var hour = initialTime.hour;
        var minute = initialTime.minute;
        return StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(title,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                      ),
                      Text(
                        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 176,
                    child: Row(
                      children: [
                        Expanded(
                          child: _TimeWheelColumn(
                            label: 'GIỜ',
                            count: 24,
                            controller: hourController,
                            onChanged: (value) =>
                                setSheetState(() => hour = value),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 22),
                          child: Text(':',
                              style: TextStyle(
                                  color: AppColors.primary.withOpacity(.7),
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700)),
                        ),
                        Expanded(
                          child: _TimeWheelColumn(
                            label: 'PHÚT',
                            count: 60,
                            controller: minuteController,
                            onChanged: (value) =>
                                setSheetState(() => minute = value),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(
                          sheetContext, TimeOfDay(hour: hour, minute: minute)),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text('Xác nhận giờ'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  } finally {
    hourController.dispose();
    minuteController.dispose();
  }
}

class _TimeWheelColumn extends StatelessWidget {
  final String label;
  final int count;
  final FixedExtentScrollController controller;
  final ValueChanged<int> onChanged;

  const _TimeWheelColumn({
    required this.label,
    required this.count,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
        Expanded(
          child: CupertinoPicker.builder(
            scrollController: controller,
            itemExtent: 42,
            childCount: count,
            selectionOverlay: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(.18)),
                ),
              ),
            ),
            onSelectedItemChanged: onChanged,
            itemBuilder: (_, index) => Center(
              child: Text(
                index.toString().padLeft(2, '0'),
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 25,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
