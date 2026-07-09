part of 'expense_provider.dart';

extension ExpenseProviderCsv on ExpenseProvider {
  Future<void> importExpensesFromCsv(String csv) async {
    final lines = csv
        .split(RegExp(r'\r?\n'))
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.length <= 1) return;

    await _run(() async {
      for (final line in lines.skip(1)) {
        final columns = CsvExportService.parseLine(line);
        if (columns.length < 4) continue;
        final date =
            DateTime.tryParse(columns[0]) ??
            _parseLooseDate(columns[0]) ??
            DateTime.now();
        final title = columns[1].trim();
        final categoryName = columns[2].trim();
        final amount =
            double.tryParse(columns[3].replaceAll(',', '').trim()) ?? 0;
        final paymentMethod =
            columns.length > 4 && paymentMethods.contains(columns[4].trim())
            ? columns[4].trim()
            : 'Cash';
        final note = columns.length > 5 ? columns[5] : '';
        if (title.length < 2 || amount <= 0) continue;

        var category = _categories.firstWhere(
          (item) => item.name.toLowerCase() == categoryName.toLowerCase(),
          orElse: () => _otherCategory,
        );
        if (category.id == _otherCategory.id &&
            categoryName.isNotEmpty &&
            categoryName.toLowerCase() != 'other') {
          category = await _categoryService.addCategory(categoryName);
          _categories.add(category);
        }

        final created = await _expenseService.addExpense(
          title: title,
          amount: amount,
          category: category,
          date: date,
          paymentMethod: paymentMethod,
          note: note,
        );
        _expenses.add(_withKnownCategory(created));
      }
    });
  }

  String createCsv({DateTime? startDate, DateTime? endDate}) {
    final filtered = expenses.where((expense) {
      if (startDate != null && expense.date.isBefore(startDate)) return false;
      if (endDate != null) {
        final end = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
        if (expense.date.isAfter(end)) return false;
      }
      return true;
    }).toList();

    return CsvExportService.createCsv(filtered);
  }

  DateTime? _parseLooseDate(String value) {
    final parts = value.split(RegExp(r'[-/]'));
    if (parts.length != 3) return null;
    final first = int.tryParse(parts[0]);
    final second = int.tryParse(parts[1]);
    final third = int.tryParse(parts[2]);
    if (first == null || second == null || third == null) return null;
    if (parts[0].length == 4) return DateTime(first, second, third);
    return DateTime(third, second, first);
  }
}
