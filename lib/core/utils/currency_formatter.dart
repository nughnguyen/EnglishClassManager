import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat('#,###', 'vi_VN');

  static String format(num amount) {
    return '${_formatter.format(amount)}đ';
  }

  static String formatShort(num amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M đ';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K đ';
    }
    return '${amount.toStringAsFixed(0)}đ';
  }
}

