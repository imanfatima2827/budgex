import '../models/expense.dart';
import '../utils/date_helpers.dart';

class CsvExportService {
  const CsvExportService._();

  static String createCsv(List<Expense> expenses) {
    final rows = <String>['Date,Title,Category,Amount,Payment Method,Note'];
    for (final expense in expenses) {
      rows.add([
        _escape(_isoDate(expense.date)),
        _escape(expense.title),
        _escape(expense.category.name),
        expense.amount.toStringAsFixed(2),
        _escape(expense.paymentMethod),
        _escape(expense.note),
      ].join(','));
    }
    return rows.join('\n');
  }

  static String createReadableCsv(List<Expense> expenses) {
    final rows = <String>['Date,Title,Category,Amount,Payment Method,Note'];
    for (final expense in expenses) {
      rows.add([
        formatDate(expense.date),
        _escape(expense.title),
        _escape(expense.category.name),
        expense.amount.toStringAsFixed(2),
        _escape(expense.paymentMethod),
        _escape(expense.note),
      ].join(','));
    }
    return rows.join('\n');
  }

  static List<String> parseLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;
    var i = 0;
    while (i < line.length) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i += 2;
          continue;
        }
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
      i++;
    }
    result.add(buffer.toString());
    return result;
  }

  static String _isoDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
