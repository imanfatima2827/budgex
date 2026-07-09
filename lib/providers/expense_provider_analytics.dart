part of 'expense_provider.dart';

extension ExpenseProviderAnalytics on ExpenseProvider {
  List<Expense> expensesForMonth(DateTime month) {
    return expenses
        .where((expense) => isSameMonth(expense.date, month))
        .toList();
  }

  List<Income> incomesForMonth(DateTime month) {
    return incomes.where((income) => isSameMonth(income.date, month)).toList();
  }

  List<Expense> recentExpenses({int limit = 4}) {
    return expenses.take(limit).toList();
  }

  double totalForMonth(DateTime month) {
    return expensesForMonth(
      month,
    ).fold<double>(0, (sum, expense) => sum + expense.amount);
  }

  double incomeForMonth(DateTime month) {
    return incomesForMonth(
      month,
    ).fold<double>(0, (sum, income) => sum + income.amount);
  }

  double savingsForMonth(DateTime month) {
    return incomeForMonth(month) - totalForMonth(month);
  }

  double savingsRate(DateTime month) {
    final income = incomeForMonth(month);
    if (income <= 0) return 0;
    return (savingsForMonth(month) / income) * 100;
  }

  double totalForDateRange(DateTime start, DateTime end) {
    return expenses.where((expense) {
      return !expense.date.isBefore(start) && !expense.date.isAfter(end);
    }).fold<double>(0, (sum, expense) => sum + expense.amount);
  }

  double incomeForDateRange(DateTime start, DateTime end) {
    return incomes.where((income) {
      return !income.date.isBefore(start) && !income.date.isAfter(end);
    }).fold<double>(0, (sum, income) => sum + income.amount);
  }

  Map<ExpenseCategory, double> categoryTotals(DateTime month) {
    final totals = <ExpenseCategory, double>{};
    for (final expense in expensesForMonth(month)) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals;
  }

  Map<int, double> dailyTotals(DateTime month) {
    final totals = <int, double>{};
    for (final expense in expensesForMonth(month)) {
      totals[expense.date.day] =
          (totals[expense.date.day] ?? 0) + expense.amount;
    }
    return totals;
  }

  Map<int, double> dailyTotalsForDateRange(DateTime start, DateTime end) {
    final totals = <int, double>{};
    for (final expense in expenses) {
      if (expense.date.isBefore(start) || expense.date.isAfter(end)) continue;
      totals[expense.date.day] =
          (totals[expense.date.day] ?? 0) + expense.amount;
    }
    return totals;
  }

  Map<ExpenseCategory, double> categoryTotalsForDateRange(
    DateTime start,
    DateTime end,
  ) {
    final totals = <ExpenseCategory, double>{};
    for (final expense in expenses) {
      if (expense.date.isBefore(start) || expense.date.isAfter(end)) continue;
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals;
  }

  double categoryBudgetLimit(String categoryId) {
    final matches = _categoryBudgets.where(
      (budget) => budget.categoryId == categoryId,
    );
    if (matches.isEmpty) return 0;
    return matches.first.monthlyLimit;
  }

  double categorySpendingForMonth(String categoryId, DateTime month) {
    return expensesForMonth(month)
        .where(
          (expense) =>
              expense.category.id == categoryId ||
              expense.categoryId == categoryId,
        )
        .fold<double>(0, (sum, expense) => sum + expense.amount);
  }

  double comparisonPercentage(DateTime month) {
    final currentTotal = totalForMonth(month);
    final previousMonth = DateTime(month.year, month.month - 1, 1);
    final previousTotal = totalForMonth(previousMonth);
    if (previousTotal == 0) return currentTotal == 0 ? 0 : 100;
    return ((currentTotal - previousTotal) / previousTotal) * 100;
  }

  double averageDailySpend(DateTime month) {
    final total = totalForMonth(month);
    final now = DateTime.now();
    final daysElapsed = isSameMonth(now, month)
        ? now.day
        : DateTime(month.year, month.month + 1, 0).day;
    if (daysElapsed <= 0) return 0;
    return total / daysElapsed;
  }

  double projectedMonthSpend(DateTime month) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    return averageDailySpend(month) * daysInMonth;
  }

  List<SpendingInsight> insightsForMonth(
    DateTime month, {
    double monthlyBudget = 0,
  }) {
    final total = totalForMonth(month);
    final income = incomeForMonth(month);
    final comparison = comparisonPercentage(month);
    final avg = averageDailySpend(month);
    final projected = projectedMonthSpend(month);
    final categoryEntries = categoryTotals(month).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final insights = <SpendingInsight>[];

    if (income > 0) {
      final rate = savingsRate(month);
      insights.add(SpendingInsight(
        title: 'Savings rate',
        message: rate >= 0
            ? 'You saved ${rate.toStringAsFixed(0)}% of your income this month.'
            : 'Your expenses are higher than your income this month.',
        icon: Icons.savings_outlined,
        isPositive: rate >= 20,
        isWarning: rate < 0,
      ));
    }

    if (categoryEntries.isNotEmpty) {
      insights.add(SpendingInsight(
        title: 'Top category',
        message:
            'Your highest spending category is ${categoryEntries.first.key.name}.',
        icon: Icons.pie_chart_outline_rounded,
      ));
    }

    if (monthlyBudget > 0) {
      final progress = total / monthlyBudget;
      if (progress >= 1) {
        insights.add(SpendingInsight(
          title: 'Budget crossed',
          message: 'You crossed your monthly budget. Review non-essential spending.',
          icon: Icons.warning_amber_rounded,
          isWarning: true,
        ));
      } else if (progress >= 0.8) {
        insights.add(SpendingInsight(
          title: 'Budget alert',
          message: 'You used ${(progress * 100).toStringAsFixed(0)}% of your monthly budget.',
          icon: Icons.notifications_active_outlined,
          isWarning: true,
        ));
      }
    }

    for (final budget in _categoryBudgets) {
      if (budget.monthlyLimit <= 0) continue;
      final spent = categorySpendingForMonth(budget.categoryId, month);
      final ratio = spent / budget.monthlyLimit;
      final categoryName =
          budget.category?.name ?? categoryById(budget.categoryId).name;
      if (ratio >= 1) {
        insights.add(SpendingInsight(
          title: '$categoryName over budget',
          message: '$categoryName spending crossed its category budget.',
          icon: Icons.report_problem_outlined,
          isWarning: true,
        ));
      } else if (ratio >= 0.8) {
        insights.add(SpendingInsight(
          title: '$categoryName near limit',
          message: '$categoryName is at ${(ratio * 100).toStringAsFixed(0)}% of its budget.',
          icon: Icons.notifications_none_rounded,
          isWarning: true,
        ));
      }
    }

    if (total > 0) {
      insights.add(SpendingInsight(
        title: 'Daily average',
        message: 'Your average daily spending is ${avg.toStringAsFixed(0)}.',
        icon: Icons.speed_rounded,
      ));
      insights.add(SpendingInsight(
        title: 'Projected spend',
        message: 'At this speed, month-end spend may be ${projected.toStringAsFixed(0)}.',
        icon: Icons.trending_up_rounded,
        isWarning: monthlyBudget > 0 && projected > monthlyBudget,
      ));
    }

    if (comparison != 0 && total > 0) {
      insights.add(SpendingInsight(
        title: 'Month comparison',
        message: comparison < 0
            ? 'You spent ${comparison.abs().toStringAsFixed(0)}% less than last month.'
            : 'You spent ${comparison.toStringAsFixed(0)}% more than last month.',
        icon: comparison < 0
            ? Icons.trending_down_rounded
            : Icons.trending_up_rounded,
        isPositive: comparison < 0,
        isWarning: comparison > 0,
      ));
    }

    return insights.take(6).toList();
  }

  List<Expense> filteredExpenses(ExpenseFilter filter) {
    return expenses.where((expense) {
      final search = filter.searchText.trim().toLowerCase();
      if (search.isNotEmpty) {
        final titleMatch = expense.title.toLowerCase().contains(search);
        final noteMatch = expense.note.toLowerCase().contains(search);
        final categoryMatch = expense.category.name
            .toLowerCase()
            .contains(search);
        if (!titleMatch && !noteMatch && !categoryMatch) return false;
      }
      if (filter.categoryId != null &&
          expense.category.id != filter.categoryId) {
        return false;
      }
      if (filter.paymentMethod != null &&
          expense.paymentMethod != filter.paymentMethod) {
        return false;
      }
      if (filter.startDate != null &&
          expense.date.isBefore(
            DateTime(
              filter.startDate!.year,
              filter.startDate!.month,
              filter.startDate!.day,
            ),
          )) {
        return false;
      }
      if (filter.endDate != null) {
        final end = DateTime(
          filter.endDate!.year,
          filter.endDate!.month,
          filter.endDate!.day,
          23,
          59,
          59,
        );
        if (expense.date.isAfter(end)) return false;
      }
      if (filter.minAmount != null && expense.amount < filter.minAmount!) {
        return false;
      }
      if (filter.maxAmount != null && expense.amount > filter.maxAmount!) {
        return false;
      }
      return true;
    }).toList();
  }
}
