import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/session.dart';
import '../../../../core/utils/currency_formatter.dart';

class SessionCard extends StatelessWidget {
  final Session session;
  final bool isOngoing;
  final bool isCompleted;
  final Animation<double> ongoingAnimation;

  const SessionCard({
    super.key,
    required this.session,
    required this.ongoingAnimation,
    this.isOngoing = false,
    this.isCompleted = false,
  });

  String get _statusLabel {
    switch (session.status) {
      case SessionStatus.pending:
        if (isOngoing) return 'Đang diễn ra';
        return _hasEnded ? 'Chờ điểm danh' : 'Sắp tới';
      case SessionStatus.completed:
        return 'Hoàn thành';
      case SessionStatus.cancelled:
        return 'Vắng mặt';
    }
  }

  bool get _hasEnded {
    final match = RegExp(
      r'^\s*(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})\s*$',
    ).firstMatch(session.timeSlot);
    if (match == null) return false;
    final values =
        List.generate(4, (index) => int.tryParse(match.group(index + 1)!));
    if (values.any((value) => value == null) ||
        values[0]! > 23 ||
        values[2]! > 23 ||
        values[1]! > 59 ||
        values[3]! > 59) {
      return false;
    }
    final start = DateTime(session.date.year, session.date.month,
        session.date.day, values[0]!, values[1]!);
    var end = DateTime(session.date.year, session.date.month, session.date.day,
        values[2]!, values[3]!);
    if (end.isBefore(start)) end = end.add(const Duration(days: 1));
    return DateTime.now().isAfter(end);
  }

  Color get _statusColor {
    switch (session.status) {
      case SessionStatus.pending:
        return isOngoing ? AppColors.success : AppColors.warning;
      case SessionStatus.completed:
        return AppColors.success;
      case SessionStatus.cancelled:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionColor = AppColors.fromHex(session.colorHex);
    return _OngoingFrame(
      isActive: isOngoing,
      showStaticBorder: isCompleted,
      accentColor: sessionColor,
      animation: ongoingAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: sessionColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                session.studentName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _statusLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                session.timeSlot,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: sessionColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                session.programName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: sessionColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                session.branchName,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(session.totalAmount),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: session.status == SessionStatus.completed
                                    ? AppColors.success
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OngoingFrame extends StatelessWidget {
  final bool isActive;
  final bool showStaticBorder;
  final Color accentColor;
  final Animation<double> animation;
  final Widget child;

  const _OngoingFrame({
    required this.isActive,
    required this.showStaticBorder,
    required this.accentColor,
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isActive) {
      if (!showStaticBorder) return child;
      return CustomPaint(
        foregroundPainter: _OrbitingBorderPainter(
          progress: 0,
          accentColor: accentColor,
          isAnimated: false,
        ),
        child: child,
      );
    }
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) => CustomPaint(
        foregroundPainter: _OrbitingBorderPainter(
          progress: animation.value,
          accentColor: accentColor,
          isAnimated: true,
        ),
        child: child,
      ),
    );
  }
}

class _OrbitingBorderPainter extends CustomPainter {
  final double progress;
  final Color accentColor;
  final bool isAnimated;

  const _OrbitingBorderPainter({
    required this.progress,
    required this.accentColor,
    required this.isAnimated,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(1.5),
      const Radius.circular(16),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isAnimated ? 3 : 2.5;
    if (isAnimated) {
      paint.shader = SweepGradient(
        transform: GradientRotation(progress * 6.283185307),
        colors: [
          Colors.transparent,
          Colors.transparent,
          accentColor.withValues(alpha: .25),
          Colors.white,
          accentColor,
          Colors.transparent,
        ],
        stops: const [0, .66, .73, .77, .81, 1],
      ).createShader(rect);
    } else {
      paint.color = accentColor;
    }
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _OrbitingBorderPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.isAnimated != isAnimated;
}
