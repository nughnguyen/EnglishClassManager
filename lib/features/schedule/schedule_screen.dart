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

class ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();
  List<Session> _monthSessions = [];
  bool _loading = true;
  final ScrollController _rulerController = ScrollController();
  Timer? _clockTimer;
  late final AnimationController _ongoingBorderAnimation;
  late final AnimationController _greetingTypingAnimation;
  String _teacherName = '';
  int _greetingMessageIndex = 0;
  Timer? _greetingCycleTimer;
  bool _staleNotificationsCleaned = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ongoingBorderAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
    _greetingTypingAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _loadTeacherName();
    loadSessions();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDay());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rulerController.dispose();
    _clockTimer?.cancel();
    _greetingCycleTimer?.cancel();
    _ongoingBorderAnimation.dispose();
    _greetingTypingAnimation.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherName() async {
    try {
      final profile = await SupabaseService.instance.getProfile();
      final name = profile?.fullName?.trim() ?? '';
      if (!mounted || name.isEmpty) return;
      setState(() => _teacherName = name);
      _greetingTypingAnimation.forward(from: 0);
      _greetingCycleTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        _greetingTypingAnimation.reverse().then((_) {
          if (!mounted) return;
          setState(() => _greetingMessageIndex =
              (_greetingMessageIndex + 1) % 2);
          _greetingTypingAnimation.forward();
        });
      });
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _returnToToday();
  }

  Future<void> showToday() => _returnToToday();

  Future<void> showDateAndRefresh(DateTime date) async {
    setState(() {
      _currentMonth = DateTime(date.year, date.month);
      _selectedDate = DateTime(date.year, date.month, date.day);
    });
    await loadSessions(forceRefresh: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDay());
  }

  String get _greetingMessage => _greetingMessageIndex == 0
      ? 'Xin chào, $_teacherName!'
      : 'Chúc bạn một ngày tốt lành!';

  Future<void> _returnToToday() async {
    final today = DateTime.now();
    final dateChanged = !AppDateUtils.isSameDay(_selectedDate, today);
    final monthChanged =
        _currentMonth.year != today.year || _currentMonth.month != today.month;
    if (dateChanged || monthChanged) {
      setState(() {
        _currentMonth = DateTime(today.year, today.month);
        _selectedDate = today;
      });
    }
    await loadSessions(showLoading: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDay());
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

      if (!_staleNotificationsCleaned) {
        try {
          final notificationService = NotificationService();
          final pendingSessions = await SupabaseService.instance
              .getPendingSessionsForNotifications();
          // Remove old alarms and already displayed reminders, including ones
          // left behind by sessions deleted before this cleanup was added.
          await notificationService.cancelAllNotifications();
          for (final session in pendingSessions) {
            final endTime = _sessionEndTime(session);
            if (endTime == null || !endTime.isAfter(DateTime.now())) continue;
            await notificationService.scheduleSessionEndNotification(
              id: session.id.hashCode & 0x7fffffff,
              sessionId: session.id,
              sessionName: session.studentName,
              endTime: endTime,
            );
          }
          _staleNotificationsCleaned = true;
        } catch (_) {
          // Retry reconciliation on the next successful schedule refresh.
        }
      }

      // Schedule local notifications for pending sessions
      for (final s in sessions) {
        if (s.status == SessionStatus.pending) {
          final endTime = _sessionEndTime(s);
          if (endTime != null && endTime.isAfter(DateTime.now())) {
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

  DateTime? _sessionEndTime(Session session) {
    final match = RegExp(
      r'^\s*(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})\s*$',
    ).firstMatch(session.timeSlot);
    if (match == null) return null;
    final values = List.generate(
        4, (index) => int.tryParse(match.group(index + 1)!));
    if (values.any((value) => value == null) ||
        values[0]! > 23 ||
        values[2]! > 23 ||
        values[1]! > 59 ||
        values[3]! > 59) {
      return null;
    }
    final start = DateTime(session.date.year, session.date.month,
        session.date.day, values[0]!, values[1]!);
    var end = DateTime(session.date.year, session.date.month, session.date.day,
        values[2]!, values[3]!);
    if (end.isBefore(start)) end = end.add(const Duration(days: 1));
    return end;
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
    const itemExtent = 62.0; // 54 px day circle + 8 px horizontal spacing.
    const leadingPadding = 12.0;
    const circleSize = 54.0;
    final offset = leadingPadding +
        (_selectedDate.day - 1) * itemExtent +
        circleSize / 2 -
        screenWidth / 2;
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
    final sessions = _monthSessions
        .where((session) => AppDateUtils.isSameDay(session.date, _selectedDate))
        .toList();
    sessions.sort((a, b) {
      final absentOrder = (a.status == SessionStatus.cancelled ? 1 : 0)
          .compareTo(b.status == SessionStatus.cancelled ? 1 : 0);
      if (absentOrder != 0) return absentOrder;
      final ongoingOrder = (_isSessionOngoing(b) ? 1 : 0)
          .compareTo(_isSessionOngoing(a) ? 1 : 0);
      if (ongoingOrder != 0) return ongoingOrder;
      return _startMinute(a).compareTo(_startMinute(b));
    });
    return sessions;
  }

  int _startMinute(Session session) {
    final match = RegExp(r'^\s*(\d{1,2}):(\d{2})\s*-').firstMatch(session.timeSlot);
    if (match == null) return 24 * 60;
    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return 24 * 60;
    }
    return hour * 60 + minute;
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
      try {
        await NotificationService().cancelNotificationsForSessions({id});
      } catch (_) {}
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
    final result = await showFormBottomSheet<DateTime>(
      context: context,
      child: AddSessionScreen(session: session),
    );
    if (result != null) {
      await showDateAndRefresh(result);
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
                      if (_teacherName.isNotEmpty)
                        AnimatedBuilder(
                          animation: _greetingTypingAnimation,
                          builder: (context, child) {
                            final message = _greetingMessage;
                            final count = (message.length *
                                    _greetingTypingAnimation.value)
                                .ceil()
                                .clamp(0, message.length);
                            return Text(
                              message.substring(0, count),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      const Text('Lịch dạy',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 20)),
                      Text(
                          '${_selectedDaySessions.length} lớp học · ${_selectedDate.day}/${_selectedDate.month}',
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
                          constraints:
                              const BoxConstraints.tightFor(width: 38, height: 38),
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
                                horizontal: 14, vertical: 8),
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
                          constraints:
                              const BoxConstraints.tightFor(width: 38, height: 38),
                          padding: EdgeInsets.zero,
                        ),
                        if (!AppDateUtils.isSameDay(
                            _selectedDate, DateTime.now()))
                          IconButton(
                            tooltip: 'Quay về hôm nay',
                            onPressed: _returnToToday,
                            constraints:
                                const BoxConstraints.tightFor(width: 38, height: 38),
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  AppColors.primary.withOpacity(.1),
                              foregroundColor: AppColors.primary,
                            ),
                            icon: const Icon(Icons.today_rounded, size: 19),
                          ),
                      ],
                    ),
                  ),
                  // Day Ruler
                  SizedBox(
                    height: 94,
                    child: ListView.builder(
                      controller: _rulerController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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

                        final content = AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          width: 54,
                          height: 54,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.navyDark,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isSelected ? null : AppColors.background,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : isRealToday
                                      ? AppColors.primary.withOpacity(.5)
                                      : AppColors.divider.withOpacity(.7),
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 5),
                                    ),
                                  ]
                                : const [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayOfWeek,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white.withOpacity(.76)
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                day.toString(),
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? Colors.white
                                      : (isRealToday
                                          ? AppColors.primary
                                          : AppColors.textPrimary),
                                ),
                              ),
                              const SizedBox(height: 5),
                              SizedBox(
                                height: 6,
                                child: dayDots.isEmpty
                                    ? null
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: dayDots.take(3).map((hex) {
                                          return Container(
                                            width: 5,
                                            height: 5,
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 1),
                                            decoration: BoxDecoration(
                                              color: AppColors.fromHex(hex),
                                              shape: BoxShape.circle,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                              ),
                            ],
                          ),
                        );

                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() => _selectedDate = date);
                            WidgetsBinding.instance.addPostFrameCallback(
                                (_) => _scrollToSelectedDay());
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 5),
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
                                    isCompleted: session.status ==
                                        SessionStatus.completed,
                                    ongoingAnimation: _ongoingBorderAnimation,
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
