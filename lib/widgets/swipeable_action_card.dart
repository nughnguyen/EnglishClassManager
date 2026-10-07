import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SwipeableActionCard extends StatefulWidget {
  final Widget child;
  final String deleteLabel;
  final Future<void> Function() onDeleteConfirmed;
  final VoidCallback? onEdit;
  final EdgeInsetsGeometry? margin;

  const SwipeableActionCard({
    super.key,
    required this.child,
    this.deleteLabel = 'mục này',
    required this.onDeleteConfirmed,
    this.onEdit,
    this.margin,
  });

  @override
  State<SwipeableActionCard> createState() => _SwipeableActionCardState();
}

class _SwipeableActionCardState extends State<SwipeableActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  bool _isRevealed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    final offset = widget.onEdit != null ? -0.4 : -0.22;
    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(offset, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (details.primaryDelta! < -8) { // Increased threshold to prevent accidental triggers while scrolling
      if (!_isRevealed) {
        _controller.forward();
        setState(() => _isRevealed = true);
      }
    } else if (details.primaryDelta! > 8) {
      if (_isRevealed) {
        _controller.reverse();
        setState(() => _isRevealed = false);
      }
    }
  }

  void _onTapOutside() {
    if (_isRevealed) {
      _controller.reverse();
      setState(() => _isRevealed = false);
    }
  }

  Future<void> _onDeletePressed(BuildContext context) async {
    _controller.reverse();
    setState(() => _isRevealed = false);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa ${widget.deleteLabel} không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.onDeleteConfirmed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      child: GestureDetector(
        onTap: _onTapOutside,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background actions
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    if (_controller.value == 0) return const SizedBox.shrink();
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.onEdit != null) ...[
                            GestureDetector(
                              onTap: () {
                                _controller.reverse();
                                setState(() => _isRevealed = false);
                                widget.onEdit!();
                              },
                              child: Container(
                                width: 56,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 24),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          GestureDetector(
                            onTap: () => _onDeletePressed(context),
                            child: Container(
                              width: 56,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.delete_rounded, color: Colors.white, size: 24),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Foreground card
              SlideTransition(
                position: _offsetAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: widget.child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
