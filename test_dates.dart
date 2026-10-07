void main() {
  final month = DateTime(2026, 10);
  final weekdays = [3]; // Wednesday
  final result = <DateTime>[];
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  for (int d = 1; d <= daysInMonth; d++) {
    final date = DateTime(month.year, month.month, d);
    if (weekdays.contains(date.weekday)) {
      result.add(date);
    }
  }
  print(result);
}
