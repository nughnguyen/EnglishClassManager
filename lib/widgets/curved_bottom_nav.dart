import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Curved Bottom Navigation Bar with a notch for FAB
class CurvedBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabPressed;

  const CurvedBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Bottom bar background
        CustomPaint(
          size: Size(MediaQuery.of(context).size.width, 72),
          painter: _CurvedBarPainter(),
          child: SizedBox(
            height: 72,
            child: Row(
              children: [
                // Left side tabs
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NavItem(
                        icon: Icons.calendar_today_rounded,
                        label: 'Lịch dạy',
                        selected: currentIndex == 0,
                        onTap: () => onTap(0),
                      ),
                      _NavItem(
                        icon: Icons.school_rounded,
                        label: 'Lớp học',
                        selected: currentIndex == 1,
                        onTap: () => onTap(1),
                      ),
                    ],
                  ),
                ),
                // Center space for FAB
                const SizedBox(width: 80),
                // Right side tabs
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NavItem(
                        icon: Icons.bar_chart_rounded,
                        label: 'Lương',
                        selected: currentIndex == 2,
                        onTap: () => onTap(2),
                      ),
                      _NavItem(
                        icon: Icons.settings_rounded,
                        label: 'Cài đặt',
                        selected: currentIndex == 3,
                        onTap: () => onTap(3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // FAB button in center notch
        Positioned(
          top: -22,
          child: GestureDetector(
            onTap: onFabPressed,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryLight, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryLight : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurvedBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    const notchRadius = 40.0;
    final centerX = size.width / 2;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(centerX - notchRadius - 15, 0);
    // Curved notch
    path.cubicTo(
      centerX - notchRadius - 5, 0,
      centerX - notchRadius, notchRadius * 0.8,
      centerX, notchRadius * 0.8,
    );
    path.cubicTo(
      centerX + notchRadius, notchRadius * 0.8,
      centerX + notchRadius + 5, 0,
      centerX + notchRadius + 15, 0,
    );
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Draw shadow
    canvas.drawPath(path, shadowPaint);
    // Draw fill
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CurvedBarPainter oldDelegate) => false;
}
