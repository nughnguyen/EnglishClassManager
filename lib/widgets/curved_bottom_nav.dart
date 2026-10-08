import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

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
    return SafeArea(
      top: false,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.divider),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x151C2740),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _NavItem(
                      icon: Icons.calendar_month_rounded,
                      label: 'Lịch dạy',
                      selected: currentIndex == 0,
                      onTap: () => onTap(0),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.groups_rounded,
                      label: 'Lớp học',
                      selected: currentIndex == 1,
                      onTap: () => onTap(1),
                    ),
                  ),
                  const SizedBox(width: 60),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.query_stats_rounded,
                      label: 'Lương',
                      selected: currentIndex == 2,
                      onTap: () => onTap(2),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.tune_rounded,
                      label: 'Cài đặt',
                      selected: currentIndex == 3,
                      onTap: () => onTap(3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Semantics(
              button: true,
              label: 'Thêm ca học',
              child: GestureDetector(
                onTap: onFabPressed,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.94, end: 1),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) => Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6682F4), AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.32),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
    final foreground = selected ? AppColors.primary : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 230),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withOpacity(0.09) : Colors.transparent,
            borderRadius: BorderRadius.circular(19),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.08 : 1,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: Icon(icon, color: foreground, size: 21),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(
                  fontSize: 10,
                  height: 1,
                  color: foreground,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                child: Text(label, maxLines: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
