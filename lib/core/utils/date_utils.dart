import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatMonth(DateTime date) {
    return DateFormat('MM/yyyy').format(date);
  }

  /// weekday: 1=T2(Mon) ... 7=CN(Sun)
  static String formatDayOfWeek(int day) {
    const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    if (day < 1 || day > 7) return '';
    return days[day - 1];
  }

  /// Returns list of dates in [month] that fall on [weekdays] (1=Mon..7=Sun)
  static List<DateTime> getDatesInMonth(DateTime month, List<int> weekdays) {
    final result = <DateTime>[];
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      if (weekdays.contains(date.weekday)) {
        result.add(date);
      }
    }
    return result;
  }

  static String monthName(int month) {
    const names = [
      'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4',
      'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8',
      'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'
    ];
    return names[month - 1];
  }

  static String timeFromMinutes(int totalMinutes) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  static int minutesFromTime(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static double hoursFromTimeRange(String start, String end) {
    final startMin = minutesFromTime(start);
    final endMin = minutesFromTime(end);
    final diff = endMin - startMin;
    return diff > 0 ? diff / 60.0 : 0.0;
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }
}
