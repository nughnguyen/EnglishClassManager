import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/session.dart';
import '../../../../core/utils/currency_formatter.dart';

class SessionCard extends StatelessWidget {
  final Session session;
  final bool isOngoing;

  const SessionCard({
    super.key,
    required this.session,
    this.isOngoing = false,
  });

  String get _statusLabel {
    switch (session.status) {
      case SessionStatus.pending:
        return 'Chưa học';
      case SessionStatus.completed:
        return 'Hoàn thành';
      case SessionStatus.cancelled:
        return 'Vắng mặt';
    }
  }

  Color get _statusColor {
    switch (session.status) {
      case SessionStatus.pending:
        return AppColors.warning;
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
      accentColor: sessionColor,
      animationSeed: session.id.hashCode,
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

class _OngoingFrame extends StatefulWidget {
  final bool isActive;
  final Color accentColor;
  final int animationSeed;
  final Widget child;

  const _OngoingFrame({
    required this.isActive,
    required this.accentColor,
    required this.animationSeed,
    required this.child,
  });

  @override
  State<_OngoingFrame> createState() => _OngoingFrameState();
}

class _OngoingFrameState extends State<_OngoingFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 2400 + widget.animationSeed.abs() % 2100,
      ),
    );
    if (widget.isActive) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _OngoingFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
      _controller.value = 0;
    } else if (widget.isActive &&
        widget.animationSeed != oldWidget.animationSeed) {
      _controller.duration = Duration(
        milliseconds: 2400 + widget.animationSeed.abs() % 2100,
      );
      _controller
        ..value = 0
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => CustomPaint(
        foregroundPainter: widget.isActive
            ? _OrbitingBorderPainter(
                progress: _controller.value,
                accentColor: widget.accentColor,
                animationSeed: widget.animationSeed,
              )
            : null,
        child: child,
      ),
    );
  }
}

class _OrbitingBorderPainter extends CustomPainter {
  final double progress;
  final Color accentColor;
  final int animationSeed;

  const _OrbitingBorderPainter({
    required this.progress,
    required this.accentColor,
    required this.animationSeed,
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
      ..strokeWidth = 3
      ..shader = SweepGradient(
        transform: GradientRotation(
          (progress * (animationSeed.isEven ? 1 : -1) * 6.283185307) +
              (animationSeed.abs() % 360) * 0.017453293,
        ),
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
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _OrbitingBorderPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.animationSeed != animationSeed;
}
