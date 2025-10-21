import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/body_metrics_service.dart';
import '../../widgets/custom_date_picker_widget.dart';
import './widgets/bmi_display_card.dart';
import './widgets/clinical_indicators_section.dart';
import './widgets/metric_input_card.dart';
import './widgets/notes_section.dart';
import './widgets/quick_entry_buttons.dart';
import './widgets/weight_trend_chart.dart';

class BodyMetrics extends StatefulWidget {
  const BodyMetrics({Key? key}) : super(key: key);

  @override
  State<BodyMetrics> createState() => _BodyMetricsState();
}

class _BodyMetricsState extends State<BodyMetrics> {
  final BodyMetricsService _bodyMetricsService = BodyMetricsService.instance;

  // Current metric values
  String _currentWeight = "";
  String _currentHeight = "";
  String _currentWaistCircumference = "";
  String _currentHipCircumference = "";
  String _currentLeanMass = "";
  String _currentFatMass = "";
  String _currentCellularMass = "";
  String _currentPhaseAngle = "";
  String _currentHandGrip = "";
  String _notes = "";

  // Unit toggles
  bool _isWeightInLbs = false; // Default to kg
  bool _isHeightInFeet = false; // Default to cm
  bool _isTempInFahrenheit = true;

  // Date range
  String _selectedDateRange = "Ultimi 30 giorni";
  int _selectedNavIndex = 0;

  // NEW: Date selection for weight entry
  DateTime _selectedWeightDate = DateTime.now();

  // Loading states
  bool _isLoading = false;
  bool _isSaving = false;

  // Data
  List<Map<String, dynamic>> _weightData = [];
  Map<String, dynamic>? _medicalProfile;
  Map<String, dynamic>? _latestWeight;

  @override
  void initState() {
    super.initState();
    _loadBodyMetricsData();
  }

  Future<void> _loadBodyMetricsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // FIXED: Better error handling and data validation
      final results = await Future.wait([
        _bodyMetricsService.getBodyMetricsSummary(),
        _bodyMetricsService.getWeightProgressData(limit: 50),
      ]);

      final summary = results[0] as Map<String, dynamic>;
      final weightData = results[1] as List<Map<String, dynamic>>;

      setState(() {
        _medicalProfile = summary['medical_profile'];
        _latestWeight = summary['latest_weight'];
        _weightData = weightData;

        // FIXED: Safe string conversion with null checks for existing fields
        _currentWeight =
            (_latestWeight?['weight_kg'] as num?)?.toString() ?? "";
        _currentHeight =
            (_medicalProfile?['height_cm'] as num?)?.toString() ?? "";

        // NEW: Load new body metrics fields
        _currentWaistCircumference =
            (_latestWeight?['waist_circumference_cm'] as num?)?.toString() ??
            "";
        _currentHipCircumference =
            (_latestWeight?['hip_circumference_cm'] as num?)?.toString() ?? "";
        _currentLeanMass =
            (_latestWeight?['lean_mass_kg'] as num?)?.toString() ?? "";
        _currentFatMass =
            (_latestWeight?['fat_mass_kg'] as num?)?.toString() ?? "";
        _currentCellularMass =
            (_latestWeight?['cellular_mass_kg'] as num?)?.toString() ?? "";
        _currentPhaseAngle =
            (_latestWeight?['phase_angle_degrees'] as num?)?.toString() ?? "";
        _currentHandGrip =
            (_latestWeight?['hand_grip_strength_kg'] as num?)?.toString() ?? "";

        _notes = _latestWeight?['notes']?.toString() ?? "";
      });
    } catch (error) {
      print('Error loading body metrics data: $error');
      _showErrorSnackBar(
        'Errore nel caricamento dei dati: ${error.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(height: 2.h),

                    // NEW: Weight Entry Date Selector - moved up
                    _buildWeightEntryDateSelector(),
                    SizedBox(height: 2.h),

                    // REARRANGED: Basic metrics (Peso, Altezza) above Clinical Indicators
                    _buildBasicMetricsCards(),
                    SizedBox(height: 2.h),

                    // MOVED: BMI Display placed between basic metrics and clinical indicators
                    _buildBMIDisplay(),
                    SizedBox(height: 2.h),

                    // REARRANGED: Clinical Indicators Section (Indicatori Nutrizionali Clinici)
                    _buildClinicalIndicatorsSection(),
                    SizedBox(height: 2.h),

                    // MOVED: Date Range Selector moved here, just above the Weight Trend Chart
                    _buildDateRangeSelector(),
                    SizedBox(height: 2.h),

                    WeightTrendChart(
                      weightData: _weightData,
                      dateRange: _selectedDateRange,
                    ),
                    SizedBox(height: 2.h),
                    QuickEntryButtons(
                      onSameAsYesterday: _handleSameAsYesterday,
                    ),
                    SizedBox(height: 2.h),
                    NotesSection(
                      notes: _notes,
                      onNotesChanged: (notes) {
                        setState(() {
                          _notes = notes;
                        });
                      },
                    ),
                    SizedBox(height: 4.h),
                    _buildSaveButton(),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // NEW: Weight Entry Date Selector Widget - UPDATED
  Widget _buildWeightEntryDateSelector() {
    return CustomDatePickerWidget(
      selectedDate: _selectedWeightDate,
      title: 'Data della misurazione del peso',
      helpText: 'Seleziona data della misurazione',
      onDateSelected: (DateTime pickedDate) {
        setState(() {
          _selectedWeightDate = pickedDate;
        });

        // Show confirmation message
        final isToday =
            pickedDate.year == DateTime.now().year &&
            pickedDate.month == DateTime.now().month &&
            pickedDate.day == DateTime.now().day;

        _showSuccessSnackBar(
          isToday
              ? 'Data impostata per oggi'
              : 'Data impostata: ${_formatWeightSelectedDate()}',
        );
      },
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 1)),
      showPastIndicator: true,
    );
  }

  // NEW: Format selected weight date
  String _formatWeightSelectedDate() {
    final now = DateTime.now();
    if (_selectedWeightDate.year == now.year &&
        _selectedWeightDate.month == now.month &&
        _selectedWeightDate.day == now.day) {
      return 'Oggi';
    }

    final yesterday = now.subtract(Duration(days: 1));
    if (_selectedWeightDate.year == yesterday.year &&
        _selectedWeightDate.month == yesterday.month &&
        _selectedWeightDate.day == yesterday.day) {
      return 'Ieri';
    }

    final weekdays = ['', 'Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
    final months = [
      '',
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

    return '${weekdays[_selectedWeightDate.weekday]} ${_selectedWeightDate.day} ${months[_selectedWeightDate.month]}';
  }

  // NEW: Weight entry date picker
  Future<void> _selectWeightEntryDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedWeightDate,
      firstDate: DateTime.now().subtract(
        Duration(days: 365),
      ), // Up to 1 year ago
      lastDate: DateTime.now().add(Duration(days: 1)), // Up to tomorrow
      locale: const Locale('it', 'IT'),
      builder: (context, child) {
        return Theme(
          data: AppTheme.lightTheme.copyWith(
            colorScheme: AppTheme.lightTheme.colorScheme.copyWith(
              primary: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
      helpText: 'Seleziona data della misurazione',
      cancelText: 'Annulla',
      confirmText: 'Conferma',
    );

    if (pickedDate != null && pickedDate != _selectedWeightDate) {
      setState(() {
        _selectedWeightDate = pickedDate;
      });

      // Show confirmation message
      final isToday =
          pickedDate.year == DateTime.now().year &&
          pickedDate.month == DateTime.now().month &&
          pickedDate.day == DateTime.now().day;

      _showSuccessSnackBar(
        isToday
            ? 'Data impostata per oggi'
            : 'Data impostata: ${_formatWeightSelectedDate()}',
      );
    }
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12.sp,
        unselectedFontSize: 12.sp,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: CustomIconWidget(iconName: 'dashboard', size: 24),
            activeIcon: CustomIconWidget(
              iconName: 'dashboard',
              size: 24,
              color: Color(0xFF4CAF50),
            ),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(iconName: 'book', size: 24),
            activeIcon: CustomIconWidget(
              iconName: 'book',
              size: 24,
              color: Color(0xFF4CAF50),
            ),
            label: 'Diario pasti',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(iconName: 'add_circle_outline', size: 24),
            activeIcon: CustomIconWidget(
              iconName: 'add_circle_outline',
              size: 24,
              color: Color(0xFF4CAF50),
            ),
            label: 'Aggiungi pasto',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(iconName: 'bar_chart', size: 24),
            activeIcon: CustomIconWidget(
              iconName: 'bar_chart',
              size: 24,
              color: Color(0xFF4CAF50),
            ),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(iconName: 'person', size: 24),
            activeIcon: CustomIconWidget(
              iconName: 'person',
              size: 24,
              color: Color(0xFF4CAF50),
            ),
            label: 'Profilo',
          ),
        ],
      ),
    );
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedNavIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.mealDiary);
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.addMeal);
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.reports);
        break;
      case 4:
        Navigator.pushReplacementNamed(context, AppRoutes.profileSettings);
        break;
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: CustomIconWidget(
          iconName: 'arrow_back',
          color: AppTheme.lightTheme.primaryColor,
          size: 24,
        ),
      ),
      title: Text(
        'Metriche Corporee',
        style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
          color: AppTheme.lightTheme.primaryColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    final dateRanges = [
      "Ultimi 7 giorni",
      "Ultimi 30 giorni",
      "Ultimi 3 mesi",
      "Ultimi 6 mesi",
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 2.w, bottom: 1.h),
            child: Text(
              'Periodo di visualizzazione',
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  dateRanges.map((range) {
                    final isSelected = _selectedDateRange == range;
                    return GestureDetector(
                      onTap: () async {
                        if (_selectedDateRange != range) {
                          // Show loading indicator for selected filter
                          setState(() {
                            _selectedDateRange = range;
                            _isLoading = true;
                          });

                          try {
                            await _loadWeightDataForRange(range);

                            // Show success feedback with data count
                            final dataCount = _weightData.length;
                            _showSuccessSnackBar(
                              '$range: ${dataCount > 0 ? "$dataCount misurazioni trovate" : "Nessuna misurazione trovata"}',
                            );
                          } catch (error) {
                            _showErrorSnackBar(
                              'Errore nel caricamento dati per $range: ${error.toString()}',
                            );
                          } finally {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      },
                      child: Container(
                        margin: EdgeInsets.only(right: 2.w),
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.5.h,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? AppTheme.lightTheme.primaryColor
                                  : AppTheme.lightTheme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                isSelected
                                    ? AppTheme.lightTheme.primaryColor
                                    : AppTheme.lightTheme.colorScheme.outline,
                            width: 1.5,
                          ),
                          boxShadow:
                              isSelected
                                  ? [
                                    BoxShadow(
                                      color: AppTheme.lightTheme.primaryColor
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                  : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              CustomIconWidget(
                                iconName: 'check_circle',
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 1.w),
                            ],
                            Text(
                              range,
                              style: AppTheme.lightTheme.textTheme.labelMedium
                                  ?.copyWith(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : AppTheme
                                                .lightTheme
                                                .colorScheme
                                                .onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
          SizedBox(height: 1.h),
          // Data summary indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'info',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 16,
                ),
                SizedBox(width: 1.w),
                Text(
                  '${_weightData.length} misurazione${_weightData.length != 1 ? "i" : ""} nel periodo selezionato',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (_weightData.isNotEmpty) ...[
                  SizedBox(width: 2.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.2.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27AE60).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Dati disponibili',
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF27AE60),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadWeightDataForRange(String range) async {
    try {
      DateTime startDate;
      final now = DateTime.now();

      switch (range) {
        case "Ultimi 7 giorni":
          startDate = now.subtract(const Duration(days: 7));
          break;
        case "Ultimi 30 giorni":
          startDate = now.subtract(const Duration(days: 30));
          break;
        case "Ultimi 3 mesi":
          startDate = now.subtract(const Duration(days: 90));
          break;
        case "Ultimi 6 mesi":
          startDate = now.subtract(const Duration(days: 180));
          break;
        default:
          startDate = now.subtract(const Duration(days: 30));
      }

      // FIXED: Better date filtering and ensure selected date is included
      final endDate = now.add(const Duration(days: 1)); // Include today

      // If selected date is outside the range, extend the range to include it
      DateTime effectiveStartDate = startDate;
      if (_selectedWeightDate.isBefore(startDate)) {
        effectiveStartDate = DateTime(
          _selectedWeightDate.year,
          _selectedWeightDate.month,
          _selectedWeightDate.day,
        );
      }

      final weightData = await _bodyMetricsService.getWeightProgressData(
        startDate: effectiveStartDate,
        endDate: endDate,
        limit: 100,
      );

      if (mounted) {
        setState(() {
          _weightData = weightData;
        });
      }

      // Debug logging to help users understand what's happening
      print('Filter applied: $range');
      print(
        'Date range: ${effectiveStartDate.toIso8601String()} to ${endDate.toIso8601String()}',
      );
      print('Data found: ${weightData.length} entries');
    } catch (error) {
      print('Error loading weight data for range $range: $error');
      if (mounted) {
        _showErrorSnackBar(
          'Errore nel caricamento dei dati: ${error.toString()}',
        );
      }
    }
  }

  Widget _buildBasicMetricsCards() {
    return Column(
      children: [
        // Basic metrics (Peso and Altezza) - now separated from clinical indicators
        MetricInputCard(
          title: 'Peso Attuale',
          iconName: 'monitor_weight',
          value: _currentWeight,
          unit: _isWeightInLbs ? 'lbs' : 'kg',
          onTap: () => _showWeightInputDialog(),
          showUnitToggle: true,
          alternateUnit: _isWeightInLbs ? 'kg' : 'lbs',
          onUnitToggle: () {
            setState(() {
              _isWeightInLbs = !_isWeightInLbs;
              if (_currentWeight.isNotEmpty) {
                final weight = double.tryParse(_currentWeight);
                if (weight != null) {
                  _currentWeight =
                      _isWeightInLbs
                          ? (weight * 2.20462).toStringAsFixed(1)
                          : (weight / 2.20462).toStringAsFixed(1);
                }
              }
            });
          },
        ),
        MetricInputCard(
          title: 'Altezza',
          iconName: 'height',
          value: _currentHeight,
          unit: _isHeightInFeet ? 'ft' : 'cm',
          onTap: () => _showHeightInputDialog(),
          showUnitToggle: true,
          alternateUnit: _isHeightInFeet ? 'cm' : 'ft',
          onUnitToggle: () {
            setState(() {
              _isHeightInFeet = !_isHeightInFeet;
            });
          },
        ),
      ],
    );
  }

  Widget _buildClinicalIndicatorsSection() {
    return Column(
      children: [
        // Clinical Nutritional Indicators in collapsible section
        ClinicalIndicatorsSection(
          currentWaistCircumference: _currentWaistCircumference,
          currentHipCircumference: _currentHipCircumference,
          currentLeanMass: _currentLeanMass,
          currentFatMass: _currentFatMass,
          currentCellularMass: _currentCellularMass,
          currentPhaseAngle: _currentPhaseAngle,
          currentHandGrip: _currentHandGrip,
          onWaistCircumferenceTap: () => _showWaistCircumferenceInputDialog(),
          onHipCircumferenceTap: () => _showHipCircumferenceInputDialog(),
          onLeanMassTap: () => _showLeanMassInputDialog(),
          onFatMassTap: () => _showFatMassInputDialog(),
          onCellularMassTap: () => _showCellularMassInputDialog(),
          onPhaseAngleTap: () => _showPhaseAngleInputDialog(),
          onHandGripTap: () => _showHandGripInputDialog(),
        ),
      ],
    );
  }

  // NEW: Input dialogs for new metrics
  void _showWaistCircumferenceInputDialog() {
    final controller = TextEditingController(text: _currentWaistCircumference);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Inserisci Circonferenza vita',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                color: AppTheme.lightTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Circonferenza vita (cm)',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Annulla',
                  style: TextStyle(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentWaistCircumference = controller.text;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Salva'),
              ),
            ],
          ),
    );
  }

  void _showHipCircumferenceInputDialog() {
    final controller = TextEditingController(text: _currentHipCircumference);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Inserisci Circonferenza fianchi',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                color: AppTheme.lightTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Circonferenza fianchi (cm)',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Annulla',
                  style: TextStyle(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentHipCircumference = controller.text;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Salva'),
              ),
            ],
          ),
    );
  }

  void _showLeanMassInputDialog() {
    final controller = TextEditingController(text: _currentLeanMass);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Inserisci Massa magra',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                color: AppTheme.lightTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Massa magra (kg)',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Annulla',
                  style: TextStyle(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentLeanMass = controller.text;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Salva'),
              ),
            ],
          ),
    );
  }

  void _showFatMassInputDialog() {
    final controller = TextEditingController(text: _currentFatMass);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Inserisci Massa grassa',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                color: AppTheme.lightTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Massa grassa (kg)',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Annulla',
                  style: TextStyle(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentFatMass = controller.text;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Salva'),
              ),
            ],
          ),
    );
  }

  void _showCellularMassInputDialog() {
    final controller = TextEditingController(text: _currentCellularMass);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Inserisci Massa cellulare',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                color: AppTheme.lightTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Massa cellulare (kg)',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Annulla',
                  style: TextStyle(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentCellularMass = controller.text;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Salva'),
              ),
            ],
          ),
    );
  }

  void _showPhaseAngleInputDialog() {
    final controller = TextEditingController(text: _currentPhaseAngle);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Inserisci Angolo di fase',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                color: AppTheme.lightTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Angolo di fase (°)',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Annulla',
                  style: TextStyle(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentPhaseAngle = controller.text;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Salva'),
              ),
            ],
          ),
    );
  }

  void _showHandGripInputDialog() {
    final controller = TextEditingController(text: _currentHandGrip);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Inserisci Hand Grip',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                color: AppTheme.lightTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Hand Grip (kg)',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Annulla',
                  style: TextStyle(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentHandGrip = controller.text;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Salva'),
              ),
            ],
          ),
    );
  }

  // FIXED: Updated "Come Ieri" handler to use the new service method
  Future<void> _handleSameAsYesterday() async {
    try {
      // Show loading feedback
      _showSuccessSnackBar('Ricerca peso del giorno precedente...');

      // Use the new service method to get specifically the previous day's weight
      final previousDayEntry = await _bodyMetricsService
          .getPreviousDayWeightEntry(currentDate: _selectedWeightDate);

      if (previousDayEntry != null) {
        final weightValue = (previousDayEntry['weight_kg'] as num?)?.toDouble();
        final waistCircumferenceValue =
            (previousDayEntry['waist_circumference_cm'] as num?)?.toDouble();
        final hipCircumferenceValue =
            (previousDayEntry['hip_circumference_cm'] as num?)?.toDouble();
        final leanMassValue =
            (previousDayEntry['lean_mass_kg'] as num?)?.toDouble();
        final fatMassValue =
            (previousDayEntry['fat_mass_kg'] as num?)?.toDouble();
        final cellularMassValue =
            (previousDayEntry['cellular_mass_kg'] as num?)?.toDouble();
        final phaseAngleValue =
            (previousDayEntry['phase_angle_degrees'] as num?)?.toDouble();
        final handGripValue =
            (previousDayEntry['hand_grip_strength_kg'] as num?)?.toDouble();
        final notesValue = previousDayEntry['notes']?.toString() ?? '';

        if (weightValue != null) {
          setState(() {
            _currentWeight = weightValue.toStringAsFixed(1);
            _currentWaistCircumference =
                waistCircumferenceValue?.toStringAsFixed(1) ?? '';
            _currentHipCircumference =
                hipCircumferenceValue?.toStringAsFixed(1) ?? '';
            _currentLeanMass = leanMassValue?.toStringAsFixed(1) ?? '';
            _currentFatMass = fatMassValue?.toStringAsFixed(1) ?? '';
            _currentCellularMass = cellularMassValue?.toStringAsFixed(1) ?? '';
            _currentPhaseAngle = phaseAngleValue?.toStringAsFixed(1) ?? '';
            _currentHandGrip = handGripValue?.toStringAsFixed(1) ?? '';
            _notes = notesValue;
          });

          // Show success with date information
          final previousDate = DateTime.parse(previousDayEntry['recorded_at']);
          final formattedDate = _formatDate(previousDate);

          _showSuccessSnackBar(
            'Valori impostati dal $formattedDate: ${weightValue.toStringAsFixed(1)} kg e altre metriche corporee',
          );
        } else {
          _showErrorSnackBar('Errore nei dati del peso precedente');
        }
      } else {
        _showErrorSnackBar('Nessun peso registrato nei giorni precedenti');
      }
    } catch (error) {
      print('Error in _handleSameAsYesterday: $error');
      _showErrorSnackBar(
        'Errore nel recupero del peso precedente: ${error.toString()}',
      );
    }
  }

  /// NEW: Helper method to format date for user display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'ieri';
    }

    final weekdays = ['', 'Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
    final months = [
      '',
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

    return '${weekdays[date.weekday]} ${date.day} ${months[date.month]}';
  }

  Future<void> _handleSaveEntry() async {
    // FIXED: Better validation and error handling
    if (_currentWeight.isEmpty) {
      _showErrorSnackBar('Inserisci il peso per salvare le metriche');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final weight = double.tryParse(_currentWeight.replaceAll(',', '.'));
      if (weight == null || weight <= 0) {
        throw Exception('Peso non valido: deve essere un numero positivo');
      }

      final weightInKg = _isWeightInLbs ? weight / 2.20462 : weight;

      // NEW: Parse new metrics
      final waistCircumference =
          _currentWaistCircumference.isNotEmpty
              ? double.tryParse(_currentWaistCircumference.replaceAll(',', '.'))
              : null;
      final hipCircumference =
          _currentHipCircumference.isNotEmpty
              ? double.tryParse(_currentHipCircumference.replaceAll(',', '.'))
              : null;
      final leanMass =
          _currentLeanMass.isNotEmpty
              ? double.tryParse(_currentLeanMass.replaceAll(',', '.'))
              : null;
      final fatMass =
          _currentFatMass.isNotEmpty
              ? double.tryParse(_currentFatMass.replaceAll(',', '.'))
              : null;
      final cellularMass =
          _currentCellularMass.isNotEmpty
              ? double.tryParse(_currentCellularMass.replaceAll(',', '.'))
              : null;
      final phaseAngle =
          _currentPhaseAngle.isNotEmpty
              ? double.tryParse(_currentPhaseAngle.replaceAll(',', '.'))
              : null;
      final handGrip =
          _currentHandGrip.isNotEmpty
              ? double.tryParse(_currentHandGrip.replaceAll(',', '.'))
              : null;

      print(
        'Saving weight entry for date: ${_selectedWeightDate.toIso8601String()}',
      );

      // FIXED: Save weight entry with selected date using upsert to prevent duplicates
      await _bodyMetricsService.saveWeightEntry(
        weightKg: weightInKg,
        waistCircumferenceCm: waistCircumference,
        hipCircumferenceCm: hipCircumference,
        leanMassKg: leanMass,
        fatMassKg: fatMass,
        cellularMassKg: cellularMass,
        phaseAngleDegrees: phaseAngle,
        handGripStrengthKg: handGrip,
        notes: _notes.isNotEmpty ? _notes : null,
        recordedAt:
            _selectedWeightDate, // This will be normalized to date in the service
      );

      // Update medical profile if height is provided
      if (_currentHeight.isNotEmpty) {
        final height = double.tryParse(_currentHeight.replaceAll(',', '.'));
        if (height != null && height > 0) {
          final heightInCm = _isHeightInFeet ? height * 30.48 : height;
          await _bodyMetricsService.updateMedicalProfile(
            heightCm: heightInCm,
            currentWeightKg: weightInKg,
          );
        }
      }

      // FIXED: Force reload data to ensure UI updates with new entry - with delay for database sync
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadBodyMetricsData();

      // FIXED: Also refresh the current date range to include the new entry
      await _loadWeightDataForRange(_selectedDateRange);

      HapticFeedback.lightImpact();

      // FIXED: Show success message with selected date indicating upsert behavior
      final dateText = _formatWeightSelectedDate();
      final isToday =
          _selectedWeightDate.year == DateTime.now().year &&
          _selectedWeightDate.month == DateTime.now().month &&
          _selectedWeightDate.day == DateTime.now().day;

      _showSuccessSnackBar(
        isToday
            ? 'Metriche corporee salvate per oggi - I dati appariranno nel dashboard'
            : 'Metriche corporee salvate per $dateText - I dati appariranno nel dashboard',
      );

      // FIXED: Clear form but keep date for potential additional entries
      setState(() {
        _currentWeight = "";
        _currentWaistCircumference = "";
        _currentHipCircumference = "";
        _currentLeanMass = "";
        _currentFatMass = "";
        _currentCellularMass = "";
        _currentPhaseAngle = "";
        _currentHandGrip = "";
        _notes = "";
        // Keep _selectedWeightDate to allow reviewing the saved entry
      });

      // NEW: Navigate back to dashboard to show updated data
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        }
      });
    } catch (error) {
      print('Error saving weight entry: $error');
      _showErrorSnackBar('Errore nel salvare le metriche: ${error.toString()}');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Widget _buildBMIDisplay() {
    double? bmi;
    String bmiCategory = 'Non Disponibile';

    if (_currentWeight.isNotEmpty && _currentHeight.isNotEmpty) {
      final weight = double.tryParse(_currentWeight);
      final height = double.tryParse(_currentHeight);

      if (weight != null && height != null && height > 0) {
        final weightInKg = _isWeightInLbs ? weight / 2.20462 : weight;
        final heightInCm = _isHeightInFeet ? height * 30.48 : height;

        bmi = _bodyMetricsService.calculateBMI(
          weightKg: weightInKg,
          heightCm: heightInCm,
        );

        if (bmi != null) {
          bmiCategory = _bodyMetricsService.getBMICategory(bmi);
        }
      }
    }

    return BMIDisplayCard(bmiValue: bmi, bmiCategory: bmiCategory);
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _handleSaveEntry,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.lightTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child:
            _isSaving
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Salvando...',
                      style: AppTheme.lightTheme.textTheme.titleMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CustomIconWidget(
                      iconName: 'save',
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Salva Metriche',
                      style: AppTheme.lightTheme.textTheme.titleMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
      ),
    );
  }

  void _showWeightInputDialog() {
    final controller = TextEditingController(text: _currentWeight);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Inserisci Peso',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                color: AppTheme.lightTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Peso (${_isWeightInLbs ? 'lbs' : 'kg'})',
                    border: const OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Annulla',
                  style: TextStyle(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentWeight = controller.text;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Salva'),
              ),
            ],
          ),
    );
  }

  void _showHeightInputDialog() {
    final controller = TextEditingController(text: _currentHeight);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Inserisci Altezza',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                color: AppTheme.lightTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    labelText:
                        _isHeightInFeet ? 'Altezza (ft)' : 'Altezza (cm)',
                    border: const OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Annulla',
                  style: TextStyle(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentHeight = controller.text;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Salva'),
              ),
            ],
          ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const CustomIconWidget(
              iconName: 'check_circle',
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                message,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF27AE60),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.all(4.w),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const CustomIconWidget(
              iconName: 'error',
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                message,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.all(4.w),
      ),
    );
  }
}
