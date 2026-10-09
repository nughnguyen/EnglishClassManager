import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class CurvedBottomNav extends StatefulWidget {
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
  State<CurvedBottomNav> createState() => _CurvedBottomNavState();
}

class _CurvedBottomNavState extends State<CurvedBottomNav> {
  int? _trackedPointer;
  double? _pointerStartX;
  double? _pointerStartY;
  bool _draggingAcrossTabs = false;

  int? _indexAtPosition(double x, double width) {
    final itemWidth = (width - 60) / 4;
    if (itemWidth <= 0 || x < 0 || x > width) return null;
    if (x < itemWidth) return 0;
    if (x < itemWidth * 2) return 1;
    final rightSideStart = itemWidth * 2 + 60;
    if (x < rightSideStart) return null;
    if (x < rightSideStart + itemWidth) return 2;
    if (x <= rightSideStart + itemWidth * 2) return 3;
    return null;
  }

  void _onPointerDown(PointerDownEvent event, double width) {
    if (_trackedPointer != null ||
        _indexAtPosition(event.localPosition.dx, width) == null) {
      return;
    }
    _trackedPointer = event.pointer;
    _pointerStartX = event.localPosition.dx;
    _pointerStartY = event.localPosition.dy;
    _draggingAcrossTabs = false;
  }

  void _onPointerMove(PointerMoveEvent event, double width) {
    if (event.pointer != _trackedPointer) return;
    final dx = event.localPosition.dx - _pointerStartX!;
    final dy = event.localPosition.dy - _pointerStartY!;
    if (!_draggingAcrossTabs) {
      if (dx.abs() < 8 || dx.abs() < dy.abs()) return;
      _draggingAcrossTabs = true;
    }
    final index = _indexAtPosition(event.localPosition.dx, width);
    if (index != null && index != widget.currentIndex) {
      widget.onTap(index);
    }
  }

  void _clearPointer(PointerEvent event) {
    if (event.pointer != _trackedPointer) return;
    _trackedPointer = null;
    _pointerStartX = null;
    _pointerStartY = null;
    _draggingAcrossTabs = false;
  }

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
              child: LayoutBuilder(
                builder: (context, constraints) => Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (event) =>
                      _onPointerDown(event, constraints.maxWidth),
                  onPointerMove: (event) =>
                      _onPointerMove(event, constraints.maxWidth),
                  onPointerUp: _clearPointer,
                  onPointerCancel: _clearPointer,
                  child: Row(
                    children: [
                      Expanded(
                        child: _NavItem(
                          icon: Icons.calendar_month_rounded,
                          label: 'Lịch dạy',
                          selected: widget.currentIndex == 0,
                          onTap: () => widget.onTap(0),
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          icon: Icons.groups_rounded,
                          label: 'Lớp học',
                          selected: widget.currentIndex == 1,
                          onTap: () => widget.onTap(1),
                        ),
                      ),
                      const SizedBox(width: 60),
                      Expanded(
                        child: _NavItem(
                          icon: Icons.query_stats_rounded,
                          label: 'Lương',
                          selected: widget.currentIndex == 2,
                          onTap: () => widget.onTap(2),
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          icon: Icons.tune_rounded,
                          label: 'Cài đặt',
                          selected: widget.currentIndex == 3,
                          onTap: () => widget.onTap(3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Semantics(
              button: true,
              label: 'Thêm ca học',
              child: GestureDetector(
                onTap: widget.onFabPressed,
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
            color: selected
                ? AppColors.primary.withOpacity(0.09)
                : Colors.transparent,
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
