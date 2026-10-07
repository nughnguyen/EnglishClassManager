import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/session.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../../widgets/swipeable_action_card.dart';
import 'widgets/session_card.dart';
import 'add_session_screen.dart';
import '../settings/settings_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => ScheduleScreenState();
}

class ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();
  List<Session> _monthSessions = [];
  bool _loading = true;
  final ScrollController _rulerController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadSessions();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDay());
  }

  @override
  void dispose() {
    _rulerController.dispose();
    super.dispose();
  }

  Future<void> loadSessions({bool showLoading = false}) async {
    if (showLoading) setState(() => _loading = true);
    try {
      final sessions =
          await SupabaseService.instance.getSessionsForMonth(_currentMonth);
      if (mounted) setState(() => _monthSessions = sessions);

      // Schedule local notifications for pending sessions
      for (final s in sessions) {
        if (s.status == SessionStatus.pending) {
          final parts = s.timeSlot.split('-');
          if (parts.length == 2) {
            final endParts = parts[1].trim().split(':');
            if (endParts.length == 2) {
              final h = int.tryParse(endParts[0]) ?? 0;
              final m = int.tryParse(endParts[1]) ?? 0;
              final endTime =
                  DateTime(s.date.year, s.date.month, s.date.day, h, m);
              if (endTime.isAfter(DateTime.now())) {
                NotificationService().scheduleSessionEndNotification(
                  id: s.id.hashCode.abs(),
                  sessionId: s.id,
                  sessionName: s.studentName,
                  endTime: endTime,
                );
              }
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Lỗi đồng bộ dữ liệu'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đóng'))
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void handleNotificationTap(String payload) {
    try {
      final session = _monthSessions.firstWhere((s) => s.id == payload);
      setState(() {
        _currentMonth = DateTime(session.date.year, session.date.month);
        _selectedDate = session.date;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedDay();
        _showActionBottomSheet(session);
      });
    } catch (e) {
      // Session not found in current loaded month or deleted
    }
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _currentMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _currentMonth = DateTime(picked.year, picked.month);
        _selectedDate =
            picked; // select first day of chosen month if wanted, or just keep same day
      });
      loadSessions();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToSelectedDay());
    }
  }

  void _scrollToSelectedDay() {
    if (!_rulerController.hasClients) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = 50.0; // 46 width + 4 margin total
    final offset = (_selectedDate.day - 1) * itemWidth -
        (screenWidth / 2) +
        (itemWidth / 2);
    _rulerController.animateTo(
      offset.clamp(0.0, _rulerController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _selectedDate = _currentMonth;
    });
    loadSessions();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDay());
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _selectedDate = _currentMonth;
    });
    loadSessions();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDay());
  }

  List<Session> get _selectedDaySessions {
    print('DEBUG-UI: _monthSessions length = ${_monthSessions.length}');
    final filtered = _monthSessions.where((s) {
      final same = AppDateUtils.isSameDay(s.date, _selectedDate);
      print(
          'DEBUG-UI: comparing session date ${s.date} (day: ${s.date.day}) with _selectedDate $_selectedDate (day: ${_selectedDate.day}) -> match: $same');
      return same;
    }).toList();
    print('DEBUG-UI: _selectedDaySessions length = ${filtered.length}');
    return filtered;
  }

  Map<int, List<String>> get _dotsByDay {
    final Map<int, List<String>> result = {};
    for (final s in _monthSessions) {
      final day = s.date.day;
      result.putIfAbsent(day, () => []).add(s.colorHex);
    }
    return result;
  }

  Future<void> _updateStatus(Session session, SessionStatus status) async {
    try {
      await SupabaseService.instance.updateSessionStatus(session.id, status);
      await loadSessions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteSession(String id) async {
    try {
      await SupabaseService.instance.deleteSession(id);
      await loadSessions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi xoá: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showActionBottomSheet(Session session) {
    if (session.status != SessionStatus.pending) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Xác nhận điểm danh',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Lớp ${session.studentName} - ${session.timeSlot}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _updateStatus(session, SessionStatus.cancelled);
                    },
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Vắng mặt'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _updateStatus(session, SessionStatus.completed);
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Điểm danh'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _onEditSession(Session session) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
        child: AddSessionScreen(session: session),
      ),
    );
    if (result == true) {
      loadSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final dots = _dotsByDay;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 16, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TKCA VN',
                          style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                      const Text('Lịch dạy',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 28)),
                      Text(
                          '${_monthSessions.where((s) => s.date.year == _selectedDate.year && s.date.month == _selectedDate.month && s.date.day == _selectedDate.day).length} lớp học hôm nay',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chưa có thông báo mới')),
                      );
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.cardShadow,
                              blurRadius: 4,
                              offset: const Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            // Month selector & Calendar
            Container(
              color: AppColors.surface,
              child: Column(
                children: [
                  // Month pill selector
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _prevMonth,
                          icon: const Icon(Icons.chevron_left_rounded,
                              color: AppColors.primary),
                          padding: EdgeInsets.zero,
                        ),
                        InkWell(
                          onTap: _pickMonth,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            child: Text(
                              '${AppDateUtils.monthName(_currentMonth.month)} ${_currentMonth.year}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _nextMonth,
                          icon: const Icon(Icons.chevron_right_rounded,
                              color: AppColors.primary),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                  // Day Ruler
                  SizedBox(
                    height: 72,
                    child: ListView.builder(
                      controller: _rulerController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: daysInMonth,
                      itemBuilder: (context, index) {
                        final day = index + 1;
                        final date = DateTime(
                            _currentMonth.year, _currentMonth.month, day);
                        final isSelected = date.day == _selectedDate.day &&
                            date.month == _selectedDate.month &&
                            date.year == _selectedDate.year;
                        final dayDots = dots[day] ?? [];
                        final dayOfWeek =
                            AppDateUtils.formatDayOfWeek(date.weekday);

                        final isRealToday =
                            AppDateUtils.isSameDay(date, DateTime.now());

                        Widget content = Container(
                          width: 46,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.navyDark
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayOfWeek,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected
                                      ? Colors.white70
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                day.toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : (isRealToday
                                          ? AppColors.primary
                                          : AppColors.textPrimary),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Dot indicators
                              if (dayDots.isNotEmpty)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: dayDots
                                      .take(3)
                                      .map((hex) => Container(
                                            width: 5,
                                            height: 5,
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 1),
                                            decoration: BoxDecoration(
                                              color: AppColors.fromHex(hex),
                                              shape: BoxShape.circle,
                                            ),
                                          ))
                                      .toList(),
                                ),
                            ],
                          ),
                        );

                        if (isRealToday && !isSelected) {
                          content = CustomPaint(
                            painter:
                                DashedRectPainter(color: AppColors.primary),
                            child: content,
                          );
                        }

                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() => _selectedDate = date);
                            WidgetsBinding.instance.addPostFrameCallback(
                                (_) => _scrollToSelectedDay());
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 2, vertical: 6),
                            child: content,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Sessions list
            Expanded(
              child: _loading
                  ? _buildSessionSkeleton()
                  : _selectedDaySessions.isEmpty
                      ? RefreshIndicator(
                          onRefresh: loadSessions,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.4,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.event_available_rounded,
                                        size: 56,
                                        color: AppColors.textSecondary
                                            .withOpacity(0.4),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Không có ca học ngày ${_selectedDate.day}/${_selectedDate.month}',
                                        style: const TextStyle(
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: loadSessions,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _selectedDaySessions.length,
                            itemBuilder: (context, i) {
                              final session = _selectedDaySessions[i];
                              return SwipeableActionCard(
                                key: ValueKey(session.id),
                                margin: const EdgeInsets.only(bottom: 8),
                                deleteLabel: 'ca học này',
                                onDeleteConfirmed: () =>
                                    _deleteSession(session.id),
                                onEdit: () => _onEditSession(session),
                                child: GestureDetector(
                                  onTap: () => _showActionBottomSheet(session),
                                  child: SessionCard(session: session),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.gap = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    var path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(12)));

    Path dashPath = Path();
    for (var measurePath in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < measurePath.length) {
        dashPath.addPath(
            measurePath.extractPath(distance, distance + gap), Offset.zero);
        distance += gap * 2;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap;
  }
}
