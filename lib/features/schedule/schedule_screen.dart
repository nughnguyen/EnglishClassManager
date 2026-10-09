import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/session.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../../widgets/swipeable_action_card.dart';
import '../../../widgets/form_bottom_sheet.dart';
import 'widgets/session_card.dart';
import 'add_session_screen.dart';

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
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    loadSessions();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDay());
  }

  @override
  void dispose() {
    _rulerController.dispose();
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> loadSessions(
      {bool showLoading = false, bool forceRefresh = false}) async {
    if (showLoading && _monthSessions.isEmpty) setState(() => _loading = true);
    try {
      final sessions = await SupabaseService.instance.getSessionsForMonth(
        _currentMonth,
        forceRefresh: forceRefresh,
      );
      if (mounted) setState(() => _monthSessions = sessions);

      // Schedule local notifications for pending sessions
      for (final s in sessions) {
        if (s.status == SessionStatus.pending) {
          final timeMatch = RegExp(
            r'^\s*\d{1,2}:\d{2}\s*-\s*(\d{1,2}):(\d{2})\s*$',
          ).firstMatch(s.timeSlot);
          if (timeMatch == null) continue;

          final hour = int.tryParse(timeMatch.group(1)!);
          final minute = int.tryParse(timeMatch.group(2)!);
          if (hour == null || minute == null || hour > 23 || minute > 59) {
            continue;
          }

          final endTime = DateTime(
            s.date.year,
            s.date.month,
            s.date.day,
            hour,
            minute,
          );
          if (endTime.isAfter(DateTime.now())) {
            await NotificationService().scheduleSessionEndNotification(
              id: s.id.hashCode & 0x7fffffff,
              sessionId: s.id,
              sessionName: s.studentName,
              endTime: endTime,
            );
          }
        } else {
          await NotificationService()
              .cancelNotification(s.id.hashCode & 0x7fffffff);
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
    _openSessionFromNotification(payload);
  }

  Future<void> _openSessionFromNotification(String sessionId) async {
    try {
      Session? session = _findSession(_monthSessions, sessionId);
      if (session == null) {
        final monthSessions =
            await SupabaseService.instance.getSessionsForMonth(DateTime.now());
        session = _findSession(monthSessions, sessionId);
        if (session == null) {
          for (var offset = 1; offset <= 12 && session == null; offset++) {
            final month =
                DateTime(DateTime.now().year, DateTime.now().month - offset);
            final olderSessions =
                await SupabaseService.instance.getSessionsForMonth(month);
            session = _findSession(olderSessions, sessionId);
            if (session == null) {
              final futureMonth =
                  DateTime(DateTime.now().year, DateTime.now().month + offset);
              final futureSessions = await SupabaseService.instance
                  .getSessionsForMonth(futureMonth);
              session = _findSession(futureSessions, sessionId);
            }
          }
        }
      }
      if (session == null || !mounted) return;
      final selectedSession = session;
      setState(() {
        _currentMonth =
            DateTime(selectedSession.date.year, selectedSession.date.month);
        _selectedDate = selectedSession.date;
      });
      await loadSessions();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedDay();
        _showActionBottomSheet(selectedSession);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Không tìm thấy ca học trong thông báo.')));
      }
    }
  }

  Session? _findSession(List<Session> sessions, String id) {
    for (final session in sessions) {
      if (session.id == id) return session;
    }
    return null;
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
    return _monthSessions
        .where((session) => AppDateUtils.isSameDay(session.date, _selectedDate))
        .toList();
  }

  bool _isSessionOngoing(Session session) {
    final now = DateTime.now();
    if (session.status != SessionStatus.pending ||
        !AppDateUtils.isSameDay(session.date, now)) {
      return false;
    }
    final match = RegExp(
      r'^\s*(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})\s*$',
    ).firstMatch(session.timeSlot);
    if (match == null) return false;
    final values =
        List.generate(4, (index) => int.tryParse(match.group(index + 1)!));
    if (values.any((value) => value == null)) return false;
    final start =
        DateTime(now.year, now.month, now.day, values[0]!, values[1]!);
    var end = DateTime(now.year, now.month, now.day, values[2]!, values[3]!);
    if (end.isBefore(start)) end = end.add(const Duration(days: 1));
    return !now.isBefore(start) && now.isBefore(end);
  }

  List<Session> get _ongoingSessions =>
      _selectedDaySessions.where(_isSessionOngoing).toList();

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
    final result = await showFormBottomSheet<bool>(
      context: context,
      child: AddSessionScreen(session: session),
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
                      const Text('Lịch dạy',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 20)),
                      Text(
                          '${_monthSessions.where((s) => s.date.year == _selectedDate.year && s.date.month == _selectedDate.month && s.date.day == _selectedDate.day).length} lớp học hôm nay',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ],
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
                          onRefresh: () => loadSessions(forceRefresh: true),
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
                          onRefresh: () => loadSessions(forceRefresh: true),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _selectedDaySessions.length +
                                (_ongoingSessions.isNotEmpty ? 1 : 0),
                            itemBuilder: (context, i) {
                              if (_ongoingSessions.isNotEmpty && i == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 9),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withOpacity(.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.auto_awesome_rounded,
                                            color: AppColors.success, size: 16),
                                        const SizedBox(width: 7),
                                        Expanded(
                                          child: Text(
                                            'Các lớp học đang diễn ra: ${_ongoingSessions.map((session) => session.studentName).join(', ')}',
                                            style: const TextStyle(
                                              color: AppColors.success,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              final session = _selectedDaySessions[
                                  i - (_ongoingSessions.isNotEmpty ? 1 : 0)];
                              return SwipeableActionCard(
                                key: ValueKey(session.id),
                                margin: const EdgeInsets.only(bottom: 8),
                                deleteLabel: 'ca học này',
                                onDeleteConfirmed: () =>
                                    _deleteSession(session.id),
                                onEdit: () => _onEditSession(session),
                                child: GestureDetector(
                                  onTap: () => _showActionBottomSheet(session),
                                  child: SessionCard(
                                    session: session,
                                    isOngoing: _isSessionOngoing(session),
                                  ),
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
