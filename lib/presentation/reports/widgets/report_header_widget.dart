import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ReportHeaderWidget extends StatefulWidget {
  final Function(String, {DateTime? customStartDate, DateTime? customEndDate})
  onDateRangeChanged;
  final VoidCallback onGeneratePDF;

  const ReportHeaderWidget({
    Key? key,
    required this.onDateRangeChanged,
    required this.onGeneratePDF,
  }) : super(key: key);

  @override
  State<ReportHeaderWidget> createState() => _ReportHeaderWidgetState();
}

class _ReportHeaderWidgetState extends State<ReportHeaderWidget> {
  String _selectedRange = 'Settimanale';
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  final List<String> _dateRanges = [
    'Settimanale',
    'Mensile',
    'Ciclo di trattamento',
    'Intervallo personalizzato',
  ];

  // Map Italian labels to English values for internal processing
  final Map<String, String> _rangeMapping = {
    'Settimanale': 'Weekly',
    'Mensile': 'Monthly',
    'Ciclo di trattamento': 'Treatment Cycle',
    'Intervallo personalizzato': 'Custom Range',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reports',
                style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                  color: AppTheme.lightTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              ElevatedButton.icon(
                onPressed: widget.onGeneratePDF,
                icon: CustomIconWidget(
                  iconName: 'picture_as_pdf',
                  color: Colors.white,
                  size: 18,
                ),
                label: Text(
                  'Genera PDF',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 3.w),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRange,
                isExpanded: true,
                icon: CustomIconWidget(
                  iconName: 'keyboard_arrow_down',
                  color: AppTheme.lightTheme.primaryColor,
                  size: 24,
                ),
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
                items:
                    _dateRanges.map((String range) {
                      return DropdownMenuItem<String>(
                        value: range,
                        child: Text(range),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedRange = newValue;
                    });

                    if (newValue == 'Intervallo personalizzato') {
                      _showCustomDatePicker();
                    } else {
                      // Reset custom dates for predefined ranges
                      _customStartDate = null;
                      _customEndDate = null;
                      final mappedValue = _rangeMapping[newValue] ?? 'Weekly';
                      widget.onDateRangeChanged(mappedValue);
                    }
                  }
                },
              ),
            ),
          ),

          // Show selected custom date range if applicable
          if (_selectedRange == 'Intervallo personalizzato' &&
              _customStartDate != null &&
              _customEndDate != null)
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: 2.h),
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.lightTheme.primaryColor.withValues(
                    alpha: 0.3,
                  ),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'date_range',
                    color: AppTheme.lightTheme.primaryColor,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Intervallo selezionato',
                          style: AppTheme.lightTheme.textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.lightTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          '${_formatDate(_customStartDate!)} - ${_formatDate(_customEndDate!)}',
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.lightTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _showCustomDatePicker,
                    child: Text(
                      'Modifica',
                      style: TextStyle(
                        color: AppTheme.lightTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showCustomDatePicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDateRangePicker(
          initialStartDate: _customStartDate,
          initialEndDate: _customEndDate,
          onDateRangeSelected: (DateTime startDate, DateTime endDate) {
            setState(() {
              _customStartDate = startDate;
              _customEndDate = endDate;
            });

            // Notify parent with custom dates
            widget.onDateRangeChanged(
              'Custom Range',
              customStartDate: startDate,
              customEndDate: endDate,
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Gen',
      'Feb',
      'Mar',
      'Apr',
      'Mag',
      'Giu',
      'Lug',
      'Ago',
      'Set',
      'Ott',
      'Nov',
      'Dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class CustomDateRangePicker extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Function(DateTime startDate, DateTime endDate) onDateRangeSelected;

  const CustomDateRangePicker({
    Key? key,
    this.initialStartDate,
    this.initialEndDate,
    required this.onDateRangeSelected,
  }) : super(key: key);

  @override
  State<CustomDateRangePicker> createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<CustomDateRangePicker> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(6.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Seleziona Intervallo',
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        color: AppTheme.lightTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: CustomIconWidget(
                        iconName: 'close',
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3.h),

                // Start Date Picker
                _buildDateField(
                  label: 'Data Inizio',
                  date: _startDate,
                  onTap: () => _selectStartDate(),
                  iconName: 'calendar_today',
                ),

                SizedBox(height: 2.h),

                // End Date Picker
                _buildDateField(
                  label: 'Data Fine',
                  date: _endDate,
                  onTap: () => _selectEndDate(),
                  iconName: 'event',
                ),

                // Validation Error
                if (_validationError != null) ...[
                  SizedBox(height: 2.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'error',
                          color: Colors.red,
                          size: 20,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            _validationError!,
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 4.h),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Annulla'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _canApply() ? _applyDateRange : null,
                        child: Text('Applica'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required String iconName,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.lightTheme.colorScheme.outline,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: AppTheme.lightTheme.primaryColor,
              size: 20,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    date != null ? _formatDate(date) : 'Seleziona data',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color:
                          date != null
                              ? AppTheme.lightTheme.colorScheme.onSurface
                              : AppTheme
                                  .lightTheme
                                  .colorScheme
                                  .onSurfaceVariant,
                      fontWeight:
                          date != null ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'keyboard_arrow_right',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _startDate ?? DateTime.now().subtract(Duration(days: 30)),
        firstDate: DateTime.now().subtract(Duration(days: 365)),
        lastDate: DateTime.now(),
        locale: const Locale('it', 'IT'),
        useRootNavigator: false,
        barrierDismissible: true,
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: AppTheme.lightTheme.copyWith(
              colorScheme: AppTheme.lightTheme.colorScheme.copyWith(
                primary: AppTheme.lightTheme.primaryColor,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black87,
              ),
              canvasColor: Colors.white, dialogTheme: DialogThemeData(backgroundColor: Colors.white),
            ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: child!,
              ),
            ),
          );
        },
      );

      if (picked != null && picked != _startDate) {
        setState(() {
          _startDate = picked;
          _validateDateRange();
        });
      }
    } catch (e) {
      debugPrint('Error selecting start date: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nella selezione della data. Riprova.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectEndDate() async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _endDate ?? DateTime.now(),
        firstDate: _startDate ?? DateTime.now().subtract(Duration(days: 365)),
        lastDate: DateTime.now(),
        locale: const Locale('it', 'IT'),
        useRootNavigator: false,
        barrierDismissible: true,
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: AppTheme.lightTheme.copyWith(
              colorScheme: AppTheme.lightTheme.colorScheme.copyWith(
                primary: AppTheme.lightTheme.primaryColor,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black87,
              ),
              canvasColor: Colors.white, dialogTheme: DialogThemeData(backgroundColor: Colors.white),
            ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: child!,
              ),
            ),
          );
        },
      );

      if (picked != null && picked != _endDate) {
        setState(() {
          _endDate = picked;
          _validateDateRange();
        });
      }
    } catch (e) {
      debugPrint('Error selecting end date: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nella selezione della data. Riprova.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _validateDateRange() {
    setState(() {
      _validationError = null;
    });

    if (_startDate != null && _endDate != null) {
      // Check if end date is before start date
      if (_endDate!.isBefore(_startDate!)) {
        setState(() {
          _validationError =
              'La data fine deve essere successiva alla data inizio';
        });
        return;
      }

      // Check if range is too long (more than 1 year)
      final difference = _endDate!.difference(_startDate!).inDays;
      if (difference > 365) {
        setState(() {
          _validationError = 'L\'intervallo non può essere superiore a 1 anno';
        });
        return;
      }

      // Check if start date is in the future
      if (_startDate!.isAfter(DateTime.now())) {
        setState(() {
          _validationError = 'La data inizio non può essere nel futuro';
        });
        return;
      }

      // Check if end date is in the future
      if (_endDate!.isAfter(DateTime.now())) {
        setState(() {
          _validationError = 'La data fine non può essere nel futuro';
        });
        return;
      }
    }
  }

  bool _canApply() {
    return _startDate != null && _endDate != null && _validationError == null;
  }

  void _applyDateRange() {
    if (_canApply()) {
      widget.onDateRangeSelected(_startDate!, _endDate!);
      Navigator.pop(context);
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Gennaio',
      'Febbraio',
      'Marzo',
      'Aprile',
      'Maggio',
      'Giugno',
      'Luglio',
      'Agosto',
      'Settembre',
      'Ottobre',
      'Novembre',
      'Dicembre',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
