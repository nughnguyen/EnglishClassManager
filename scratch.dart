void main() {
  var a = DateTime.parse('2024-10-06');
  var b = DateTime(2024, 10, 6);
  print(a.isUtc);
  print(a.year == b.year && a.month == b.month && a.day == b.day);
  
  var c = DateTime.parse('2024-10-06T00:00:00+00:00');
  print(c.isUtc);
  print(c.year);
  print(c.month);
  print(c.day);
  
  var d = DateTime(2024, 10, 6).toIso8601String();
  print(d);
}

