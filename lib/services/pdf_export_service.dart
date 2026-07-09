import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/category.dart';
import '../models/expense.dart';
import '../utils/date_helpers.dart';

class PdfExportService {
  const PdfExportService._();

  static Future<File> createExpenseReport({
    required List<Expense> expenses,
    required Map<ExpenseCategory, double> categoryTotals,
    required DateTime startDate,
    required DateTime endDate,
    required String currencySymbol,
    required double income,
  }) async {
    final total = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final savings = income - total;
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return [
            pw.Text(
              'Budgex Report',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text('${formatDate(startDate)} - ${formatDate(endDate)}'),
            pw.SizedBox(height: 18),
            pw.Row(
              children: [
                _summaryBox(
                  'Income',
                  formatCurrency(income, symbol: currencySymbol),
                ),
                pw.SizedBox(width: 10),
                _summaryBox(
                  'Expenses',
                  formatCurrency(total, symbol: currencySymbol),
                ),
                pw.SizedBox(width: 10),
                _summaryBox(
                  'Savings',
                  formatCurrency(savings, symbol: currencySymbol),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Category Breakdown',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            if (categoryTotals.isEmpty)
              pw.Text('No category spending found.')
            else
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headers: ['Category', 'Amount', 'Share'],
                data: categoryTotals.entries.map((entry) {
                  final share = total <= 0 ? 0 : (entry.value / total) * 100;
                  return [
                    entry.key.name,
                    formatCurrency(entry.value, symbol: currencySymbol),
                    '${share.toStringAsFixed(0)}%',
                  ];
                }).toList(),
              ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Transactions',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            if (expenses.isEmpty)
              pw.Text('No expenses found for this period.')
            else
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headers: ['Date', 'Title', 'Category', 'Amount', 'Payment'],
                data: expenses.map((expense) {
                  return [
                    formatDate(expense.date),
                    expense.title,
                    expense.category.name,
                    formatCurrency(expense.amount, symbol: currencySymbol),
                    expense.paymentMethod,
                  ];
                }).toList(),
              ),
          ];
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/expense_report_${startDate.year}_${startDate.month.toString().padLeft(2, '0')}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _summaryBox(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
