import 'package:intl/intl.dart';
import '../models/month_option.dart';

String formatDate(DateTime date) => DateFormat('MMM d, yyyy').format(date);

String formatShortDate(DateTime date) => DateFormat('MMM d').format(date);

String formatMonth(DateTime date) => DateFormat('MMMM yyyy').format(date);

String formatCurrency(double amount, {String symbol = r'$'}) {
  return '$symbol${amount.toStringAsFixed(2)}';
}

DateTime startOfMonth(DateTime date) => DateTime(date.year, date.month, 1);

DateTime endOfMonth(DateTime date) => DateTime(date.year, date.month + 1, 0, 23, 59, 59);

bool isSameMonth(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month;
}

List<MonthOption> lastMonths({int count = 6}) {
  final now = DateTime.now();
  return List.generate(count, (index) {
    final date = DateTime(now.year, now.month - index, 1);
    return MonthOption(
      label: formatMonth(date),
      start: startOfMonth(date),
      end: endOfMonth(date),
    );
  });
}
