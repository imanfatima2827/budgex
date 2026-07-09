import '../utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense_filter.dart';
import '../providers/expense_provider.dart';
import '../utils/date_helpers.dart';
import '../widgets/app_scaled_text.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key, required this.initialFilter});

  final ExpenseFilter initialFilter;

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  late final TextEditingController _searchController;
  late final TextEditingController _minAmountController;
  late final TextEditingController _maxAmountController;

  String? _categoryId;
  String? _paymentMethod;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();

    _searchController = TextEditingController(
      text: widget.initialFilter.searchText,
    );

    _minAmountController = TextEditingController(
      text: widget.initialFilter.minAmount?.toStringAsFixed(0) ?? '',
    );

    _maxAmountController = TextEditingController(
      text: widget.initialFilter.maxAmount?.toStringAsFixed(0) ?? '',
    );

    _categoryId = widget.initialFilter.categoryId;
    _paymentMethod = widget.initialFilter.paymentMethod;
    _startDate = widget.initialFilter.startDate;
    _endDate = widget.initialFilter.endDate;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppTheme.bodyColor(context),
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: AppTheme.softSurfaceColor(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      prefixIconColor: AppTheme.primary,
      suffixIconColor: AppTheme.primary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTheme.primary, width: 1.2),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppTheme.titleColor(context),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      builder: (context, child) {
        final pickerScheme = AppTheme.isDark(context)
            ? ColorScheme.dark(
                primary: AppTheme.primary,
                onPrimary: Colors.white,
                surface: AppTheme.surfaceColor(context),
                onSurface: AppTheme.titleColor(context),
              )
            : ColorScheme.light(
                primary: AppTheme.primary,
                onPrimary: Colors.white,
                surface: AppTheme.surfaceColor(context),
                onSurface: AppTheme.titleColor(context),
              );

        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: pickerScheme,
            datePickerTheme: DatePickerThemeData(
              backgroundColor: AppTheme.surfaceColor(context),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      ExpenseFilter(
        searchText: _searchController.text.trim(),
        categoryId: _categoryId,
        paymentMethod: _paymentMethod,
        startDate: _startDate,
        endDate: _endDate,
        minAmount: double.tryParse(_minAmountController.text.trim()),
        maxAmount: double.tryParse(_maxAmountController.text.trim()),
      ),
    );
  }

  void _clear() {
    setState(() {
      _searchController.clear();
      _minAmountController.clear();
      _maxAmountController.clear();
      _categoryId = null;
      _paymentMethod = null;
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();

    final paymentMethods = provider.paymentMethods.isEmpty
        ? <String>['Cash']
        : provider.paymentMethods;

    if (_paymentMethod != null && !paymentMethods.contains(_paymentMethod)) {
      _paymentMethod = null;
    }

    final categoryExists = provider.categories.any(
      (category) => category.id == _categoryId,
    );

    if (_categoryId != null && !categoryExists) {
      _categoryId = null;
    }

    return Scaffold(
      backgroundColor: AppTheme.scaffoldColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Search & Filter',
          style: TextStyle(
            color: AppTheme.titleColor(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderColor(context)),
            ),
            child: Icon(Icons.arrow_back, color: AppTheme.titleColor(context)),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: GestureDetector(
                onTap: _clear,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.softSurfaceColor(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderColor(context)),
                  ),
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor(context),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: AppTheme.isDark(context) ? 0.20 : 0.05,
                      ),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Search'),
                    SizedBox(height: 8),
                    TextField(
                      controller: _searchController,
                      cursorColor: AppTheme.primary,
                      style: TextStyle(
                        color: AppTheme.titleColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: _inputStyle('Search by title or note...')
                          .copyWith(
                            prefixIcon: Icon(
                              Icons.search,
                              color: AppTheme.primary,
                            ),
                          ),
                    ),

                    SizedBox(height: 18),

                    _fieldLabel('Category'),
                    SizedBox(height: 8),
                    _categoryDropdown(provider),

                    SizedBox(height: 18),

                    _fieldLabel('Date Range'),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _dateBox(
                            label: 'From',
                            value: _startDate == null
                                ? 'Select'
                                : formatDate(_startDate!),
                            onTap: () => _pickDate(isStart: true),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _dateBox(
                            label: 'To',
                            value: _endDate == null
                                ? 'Select'
                                : formatDate(_endDate!),
                            onTap: () => _pickDate(isStart: false),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 18),

                    _fieldLabel('Payment Method'),
                    SizedBox(height: 8),
                    _paymentMethodDropdown(paymentMethods),

                    SizedBox(height: 18),

                    _fieldLabel('Amount Range'),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minAmountController,
                            cursorColor: AppTheme.primary,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              color: AppTheme.titleColor(context),
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: _inputStyle('Min Amount'),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _maxAmountController,
                            cursorColor: AppTheme.primary,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              color: AppTheme.titleColor(context),
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: _inputStyle('Max Amount'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 25),

              Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: AppTheme.primary,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: _apply,
                    child: Center(
                      child: Text(
                        'APPLY FILTERS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryDropdown(ExpenseProvider provider) {
    return Container(
      height: 50,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppTheme.softSurfaceColor(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _categoryId,
          isExpanded: true,
          dropdownColor: AppTheme.dropdownColor(context),
          menuMaxHeight: 240,
          borderRadius: BorderRadius.circular(18),
          alignment: AlignmentDirectional.centerStart,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppTheme.primary,
          ),
          style: TextStyle(
            color: AppTheme.titleColor(context),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'All Categories',
                style: TextStyle(
                  color: AppTheme.titleColor(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            ...provider.categories.map(
              (category) => DropdownMenuItem<String?>(
                value: category.id,
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        category.icon,
                        color: category.color,
                        size: 16,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: AppScaledText(
                        category.name,
                        maxLines: 1,
                        minFontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _categoryId = value;
            });
          },
        ),
      ),
    );
  }

  Widget _paymentMethodDropdown(List<String> paymentMethods) {
    return Container(
      height: 50,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppTheme.softSurfaceColor(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _paymentMethod,
          isExpanded: true,
          dropdownColor: AppTheme.dropdownColor(context),
          menuMaxHeight: 220,
          borderRadius: BorderRadius.circular(18),
          alignment: AlignmentDirectional.centerStart,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppTheme.primary,
          ),
          style: TextStyle(
            color: AppTheme.titleColor(context),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'All Methods',
                style: TextStyle(
                  color: AppTheme.titleColor(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            ...paymentMethods.map(
              (method) => DropdownMenuItem<String?>(
                value: method,
                child: AppScaledText(method, maxLines: 1, minFontSize: 10),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _paymentMethod = value;
            });
          },
        ),
      ),
    );
  }

  Widget _dateBox({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final isSelected = value != 'Select';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppTheme.softSurfaceColor(context),
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: AppTheme.primary, width: 1.1)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              color: AppTheme.primary,
              size: 19,
            ),
            SizedBox(width: 9),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppTheme.bodyColor(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  AppScaledText(
                    value,
                    minFontSize: 9,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.titleColor(context)
                          : AppTheme.bodyColor(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
