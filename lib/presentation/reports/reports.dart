import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/meal_diary_service.dart';
import './widgets/export_options_widget.dart';
import './widgets/macro_distribution_widget.dart';
import './widgets/meal_frequency_widget.dart';
import './widgets/nutritional_summary_widget.dart';
import './widgets/report_header_widget.dart';
import './widgets/weight_trend_widget.dart';

class Reports extends StatefulWidget {
  const Reports({Key? key}) : super(key: key);

  @override
  State<Reports> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  String _selectedDateRange = 'Weekly';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _isLoading = false;
  Map<String, dynamic> _nutritionalSummary = {};
  Map<String, dynamic> _mealStatistics = {};
  bool _hasUserData = false;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    if (!AuthService.instance.isAuthenticated) {
      setState(() {
        _hasUserData = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate = now;

      // Handle custom date range
      if (_selectedDateRange == 'Custom Range' &&
          _customStartDate != null &&
          _customEndDate != null) {
        startDate = _customStartDate!;
        endDate = _customEndDate!;
      } else {
        // Calculate date range based on selection
        switch (_selectedDateRange) {
          case 'Daily':
            startDate = DateTime(now.year, now.month, now.day);
            endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
            break;
          case 'Weekly':
            startDate = now.subtract(Duration(days: 7));
            break;
          case 'Monthly':
            startDate = DateTime(now.year, now.month - 1, now.day);
            break;
          case 'Treatment Cycle':
            // Treatment cycle typically spans 2-3 months based on medical context
            startDate = DateTime(now.year, now.month - 3, now.day);
            break;
          case 'Yearly':
            startDate = DateTime(now.year - 1, now.month, now.day);
            break;
          default:
            startDate = now.subtract(Duration(days: 7));
        }
      }

      final summary = await MealDiaryService.instance.getNutritionalSummary(
        startDate: startDate,
        endDate: endDate,
      );

      final statistics = await MealDiaryService.instance.getMealStatistics(
        startDate: startDate,
        endDate: endDate,
      );

      final hasData = await MealDiaryService.instance.hasUserMeals();

      setState(() {
        _nutritionalSummary = summary;
        _mealStatistics = statistics;
        _hasUserData = hasData;
        _isLoading = false;
      });
    } catch (error) {
      print('Error loading report data: $error');
      setState(() {
        _nutritionalSummary = {};
        _mealStatistics = {};
        _hasUserData = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            ReportHeaderWidget(
              onDateRangeChanged: _handleDateRangeChanged,
              onGeneratePDF: _showExportOptions,
            ),
            Expanded(child: _buildReportContent()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildReportContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (!AuthService.instance.isAuthenticated) {
      return _buildAuthRequiredState();
    }

    if (!_hasUserData) {
      return _buildEmptyDataState();
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: 1.h),

          // Add current date range display
          if (_selectedDateRange == 'Custom Range' &&
              _customStartDate != null &&
              _customEndDate != null)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.lightTheme.primaryColor.withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'analytics',
                    color: AppTheme.lightTheme.primaryColor,
                    size: 24,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Report personalizzato',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.lightTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Dal ${_formatCustomDate(_customStartDate!)} al ${_formatCustomDate(_customEndDate!)}',
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.lightTheme.primaryColor,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          NutritionalSummaryWidget(
            dateRange: _getDisplayDateRange(),
            summaryData: _nutritionalSummary,
          ),
          MacroDistributionWidget(dateRange: _getDisplayDateRange()),
          MealFrequencyWidget(dateRange: _getDisplayDateRange()),
          WeightTrendWidget(dateRange: _getDisplayDateRange()),
          _buildTreatmentCorrelationCard(),
          _buildSyncStatusCard(),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildAuthRequiredState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'login',
            size: 15.w,
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
          SizedBox(height: 3.h),
          Text(
            'Accedi per visualizzare i tuoi report',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Text(
            'I tuoi report nutrizionali personalizzati ti aiutano a monitorare i progressi',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          ElevatedButton(
            onPressed:
                () => Navigator.pushNamed(context, AppRoutes.loginScreen),
            child: Text('Accedi'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDataState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'analytics',
              size: 20.w,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
            SizedBox(height: 4.h),
            Text(
              'Nessun dato disponibile per i report',
              style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              'Inizia a registrare i tuoi pasti nel Diario Pasti per generare report nutrizionali dettagliati e monitorare i tuoi progressi.',
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            ElevatedButton.icon(
              onPressed:
                  () => Navigator.pushNamed(context, AppRoutes.mealDiary),
              icon: CustomIconWidget(
                iconName: 'restaurant_menu',
                color: Colors.white,
                size: 6.w,
              ),
              label: Text(
                'Vai al Diario Pasti',
                style: TextStyle(fontSize: 16.sp),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3.w),
                ),
              ),
            ),
            SizedBox(height: 3.h),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.addMeal),
              icon: CustomIconWidget(
                iconName: 'add',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
              label: Text(
                'Aggiungi primo pasto',
                style: TextStyle(fontSize: 16.sp),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3.w),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.lightTheme.primaryColor),
          SizedBox(height: 2.h),
          Text(
            'Caricamento dati report...',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentCorrelationCard() {
    // Only show if user has data
    if (!_hasUserData) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'healing',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Correlazioni con il trattamento',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.lightTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildInsightItem(
            'Progressi nutrizionali',
            _buildProgressText(),
            const Color(0xFF27AE60),
          ),
          SizedBox(height: 1.h),
          _buildInsightItem(
            'Calorie giornaliere medie',
            '${(_nutritionalSummary['avg_calories_per_day'] ?? 0.0).toStringAsFixed(0)} kcal',
            const Color(0xFFF39C12),
          ),
          SizedBox(height: 1.h),
          _buildInsightItem(
            'Pasti registrati',
            '${_mealStatistics['total_meals'] ?? 0} in totale',
            AppTheme.lightTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  String _buildProgressText() {
    final totalCalories = _nutritionalSummary['total_calories'] ?? 0.0;
    final totalMeals = _mealStatistics['total_meals'] ?? 0;

    if (totalMeals == 0) {
      return 'Inizia a registrare i pasti per vedere i progressi';
    }

    return 'Buon monitoraggio alimentare con $totalMeals pasti registrati';
  }

  Widget _buildInsightItem(String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 3.w,
          height: 3.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                description,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSyncStatusCard() {
    if (!_hasUserData) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: const Color(0xFF27AE60).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF27AE60).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'sync',
            color: const Color(0xFF27AE60),
            size: 20,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stato sincronizzazione dati',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF27AE60),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Tutti i dati sincronizzati • Ultimo aggiornamento: ora',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF27AE60),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed:
                  () => Navigator.pushNamed(context, AppRoutes.dashboard),
              icon: CustomIconWidget(
                iconName: 'dashboard',
                color: AppTheme.lightTheme.primaryColor,
                size: 18,
              ),
              label: Text('Dashboard'),
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
            child: ElevatedButton.icon(
              onPressed: _hasUserData ? _showExportOptions : null,
              icon: CustomIconWidget(
                iconName: 'share',
                color: _hasUserData ? Colors.white : Colors.grey,
                size: 18,
              ),
              label: Text('Condividi report'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: _hasUserData ? null : Colors.grey.shade300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDateRangeChanged(
    String newRange, {
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) {
    setState(() {
      _selectedDateRange = newRange;
      if (newRange == 'Custom Range') {
        _customStartDate = customStartDate;
        _customEndDate = customEndDate;
      } else {
        _customStartDate = null;
        _customEndDate = null;
      }
    });
    _loadReportData();
  }

  String _getDisplayDateRange() {
    if (_selectedDateRange == 'Custom Range' &&
        _customStartDate != null &&
        _customEndDate != null) {
      final days = _customEndDate!.difference(_customStartDate!).inDays;
      if (days <= 7) return 'Custom Weekly';
      if (days <= 31) return 'Custom Monthly';
      return 'Custom Range';
    }
    return _selectedDateRange;
  }

  String _formatCustomDate(DateTime date) {
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

  void _showExportOptions() {
    if (!_hasUserData) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nessun dato da esportare. Registra alcuni pasti prima.',
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            constraints: BoxConstraints(maxHeight: 80.h),
            child: ExportOptionsWidget(
              dateRange: _getDisplayDateRange(),
              onClose: () => Navigator.pop(context),
            ),
          ),
    );
  }
}
