import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/auth_service.dart';
import '../../../services/body_metrics_service.dart';

class WeightTrendWidget extends StatefulWidget {
  final String dateRange;

  const WeightTrendWidget({Key? key, required this.dateRange})
    : super(key: key);

  @override
  State<WeightTrendWidget> createState() => _WeightTrendWidgetState();
}

class _WeightTrendWidgetState extends State<WeightTrendWidget> {
  List<Map<String, dynamic>> _weightData = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWeightData();
  }

  @override
  void didUpdateWidget(WeightTrendWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dateRange != widget.dateRange) {
      _loadWeightData();
    }
  }

  Future<void> _loadWeightData() async {
    if (!AuthService.instance.isAuthenticated) {
      setState(() {
        _weightData = _getMockData();
        _isLoading = false;
        _hasError = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate = now;

      // Calculate date range based on selection
      switch (widget.dateRange) {
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
          // Treatment cycle typically spans 2-3 months for medical monitoring
          startDate = DateTime(now.year, now.month - 3, now.day);
          break;
        case 'Yearly':
          startDate = DateTime(now.year - 1, now.month, now.day);
          break;
        default:
          startDate = now.subtract(Duration(days: 7));
      }

      final weightProgressData = await BodyMetricsService.instance
          .getWeightProgressData(
            startDate: startDate,
            endDate: endDate,
            limit:
                widget.dateRange == 'Yearly'
                    ? 365
                    : widget.dateRange == 'Treatment Cycle'
                    ? 90
                    : 30,
          );

      // Get medical profile for BMI calculation
      final bodyMetricsSummary =
          await BodyMetricsService.instance.getBodyMetricsSummary();
      final heightCm = bodyMetricsSummary['height'] as double?;

      // Process data and calculate BMI
      final processedData =
          weightProgressData.map((entry) {
            final weightKg = entry['weight_kg'] as double;
            double? bmi;

            if (heightCm != null && heightCm > 0) {
              bmi = BodyMetricsService.instance.calculateBMI(
                weightKg: weightKg,
                heightCm: heightCm,
              );
            }

            return {
              'date': entry['date'],
              'weight': weightKg,
              'weight_kg': weightKg,
              'bmi': bmi ?? 0.0,
            };
          }).toList();

      // Sort by date (oldest first for chart display)
      processedData.sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
      );

      setState(() {
        _weightData = processedData.isNotEmpty ? processedData : _getMockData();
        _isLoading = false;
        _hasError = false;
      });
    } catch (error) {
      print('Error loading weight data: $error');
      setState(() {
        _weightData = _getMockData();
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Errore nel caricamento dei dati del peso';
      });
    }
  }

  List<Map<String, dynamic>> _getMockData() {
    final now = DateTime.now();

    switch (widget.dateRange) {
      case 'Daily':
        return [
          {'date': now, 'weight': 68.3, 'weight_kg': 68.3, 'bmi': 22.0},
        ];
      case 'Weekly':
        return [
          {
            'date': now.subtract(Duration(days: 6)),
            'weight': 68.5,
            'weight_kg': 68.5,
            'bmi': 22.1,
          },
          {
            'date': now.subtract(Duration(days: 4)),
            'weight': 68.2,
            'weight_kg': 68.2,
            'bmi': 22.0,
          },
          {
            'date': now.subtract(Duration(days: 2)),
            'weight': 67.8,
            'weight_kg': 67.8,
            'bmi': 21.9,
          },
          {
            'date': now.subtract(Duration(days: 1)),
            'weight': 68.0,
            'weight_kg': 68.0,
            'bmi': 21.9,
          },
          {'date': now, 'weight': 68.3, 'weight_kg': 68.3, 'bmi': 22.0},
        ];
      case 'Monthly':
        return List.generate(
          5,
          (index) => {
            'date': now.subtract(Duration(days: (4 - index) * 7)),
            'weight': 68.5 - (index * 0.1) + (index % 2 == 0 ? 0.2 : -0.1),
            'weight_kg': 68.5 - (index * 0.1) + (index % 2 == 0 ? 0.2 : -0.1),
            'bmi': 22.1 - (index * 0.02) + (index % 2 == 0 ? 0.05 : -0.02),
          },
        );
      case 'Treatment Cycle':
        return List.generate(
          9,
          (index) => {
            'date': now.subtract(Duration(days: (8 - index) * 10)),
            'weight': 69.5 - (index * 0.2) + (index % 2 == 0 ? 0.3 : -0.15),
            'weight_kg': 69.5 - (index * 0.2) + (index % 2 == 0 ? 0.3 : -0.15),
            'bmi': 22.3 - (index * 0.05) + (index % 2 == 0 ? 0.08 : -0.03),
          },
        );
      case 'Yearly':
        return List.generate(
          12,
          (index) => {
            'date': DateTime(now.year, now.month - (11 - index), 1),
            'weight': 70.0 - (index * 0.15) + (index % 3 == 0 ? 0.3 : -0.1),
            'weight_kg': 70.0 - (index * 0.15) + (index % 3 == 0 ? 0.3 : -0.1),
            'bmi': 22.5 - (index * 0.03) + (index % 3 == 0 ? 0.1 : -0.02),
          },
        );
      default:
        return [
          {
            'date': now.subtract(Duration(days: 3)),
            'weight': 68.5,
            'weight_kg': 68.5,
            'bmi': 22.1,
          },
          {
            'date': now.subtract(Duration(days: 2)),
            'weight': 68.2,
            'weight_kg': 68.2,
            'bmi': 22.0,
          },
          {
            'date': now.subtract(Duration(days: 1)),
            'weight': 67.8,
            'weight_kg': 67.8,
            'bmi': 21.9,
          },
          {'date': now, 'weight': 68.3, 'weight_kg': 68.3, 'bmi': 22.0},
        ];
    }
  }

  String _formatDateLabel(DateTime date) {
    switch (widget.dateRange) {
      case 'Daily':
        return DateFormat('HH:mm').format(date);
      case 'Weekly':
        return DateFormat('dd/MM').format(date);
      case 'Monthly':
        return DateFormat('dd/MM').format(date);
      case 'Treatment Cycle':
        return DateFormat('dd/MM').format(date);
      case 'Yearly':
        return DateFormat('MMM').format(date);
      default:
        return DateFormat('dd/MM').format(date);
    }
  }

  // Calculate optimal interval for date display to prevent overlapping
  double _calculateOptimalInterval() {
    final dataLength = _weightData.length;
    if (dataLength <= 1) return 1.0;

    // Estimate available width per label (in pixels)
    const double chartWidthEstimate = 300.0; // Approximate chart width
    const double averageLabelWidth = 40.0; // Approximate width per date label

    // Calculate maximum labels that can fit
    final maxLabels = (chartWidthEstimate / averageLabelWidth).floor();

    // Calculate interval to show optimal number of labels
    if (dataLength <= maxLabels) {
      return 1.0; // Show all if they fit
    } else {
      // Calculate interval to show approximately maxLabels
      return (dataLength / maxLabels).ceil().toDouble();
    }
  }

  // Get reserved size for bottom titles based on date range
  double _getBottomTitlesReservedSize() {
    switch (widget.dateRange) {
      case 'Daily':
        return 35.0; // More space for HH:mm format
      case 'Weekly':
      case 'Monthly':
      case 'Treatment Cycle':
        return 40.0; // More space for dd/MM format
      case 'Yearly':
        return 45.0; // More space for MMM format + potential rotation
      default:
        return 40.0;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                iconName: 'trending_up',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Analisi andamento peso',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.lightTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Text(
                'Variazioni peso corporeo (${widget.dateRange})',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (_hasError) ...[
                SizedBox(width: 2.w),
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 16,
                ),
              ],
            ],
          ),
          if (_errorMessage != null) ...[
            SizedBox(height: 0.5.h),
            Text(
              _errorMessage!,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: Colors.orange,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          SizedBox(height: 3.h),
          Container(
            width: double.infinity,
            height: 25.h,
            child:
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.lightTheme.primaryColor,
                      ),
                    )
                    : _buildChart(),
          ),
          SizedBox(height: 2.h),
          _buildSummaryCards(),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_weightData.isEmpty) {
      return Center(
        child: Text(
          'Nessun dato disponibile per il periodo selezionato',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // Calculate min and max values for better chart scaling
    final weights =
        _weightData.map((item) => item['weight'] as double).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);

    // Add some padding to the range
    final padding = (maxWeight - minWeight) * 0.1;
    final chartMinY = (minWeight - padding).clamp(0, double.infinity);
    final chartMaxY = maxWeight + padding;

    // Calculate optimal interval to prevent date overlapping
    final optimalInterval = _calculateOptimalInterval();

    return Semantics(
      label: "Grafico lineare analisi andamento peso per ${widget.dateRange}",
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (chartMaxY - chartMinY) / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppTheme.lightTheme.colorScheme.outline.withValues(
                  alpha: 0.3,
                ),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: _getBottomTitlesReservedSize(),
                interval: optimalInterval,
                getTitlesWidget: (double value, TitleMeta meta) {
                  // Enhanced text style with better readability
                  final textStyle = TextStyle(
                    fontSize: _weightData.length > 10 ? 8 : 10,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  );

                  final index = value.toInt();
                  if (index >= 0 && index < _weightData.length) {
                    final date = _weightData[index]['date'] as DateTime;
                    final dateLabel = _formatDateLabel(date);

                    // For yearly range with many points, rotate text to save space
                    final shouldRotate =
                        widget.dateRange == 'Yearly' && _weightData.length > 8;

                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      angle:
                          shouldRotate
                              ? -0.5
                              : 0, // Slight rotation for yearly data
                      space: shouldRotate ? 8 : 4,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: shouldRotate ? 50 : 35,
                        ),
                        child: Text(
                          dateLabel,
                          style: textStyle,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: shouldRotate ? 2 : 1,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (chartMaxY - chartMinY) / 4,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      '${value.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
                reservedSize: 42,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline.withValues(
                alpha: 0.3,
              ),
            ),
          ),
          minX: 0,
          maxX: (_weightData.length - 1).toDouble(),
          minY: chartMinY.toDouble(),
          maxY: chartMaxY,
          lineBarsData: [
            LineChartBarData(
              spots:
                  _weightData.asMap().entries.map((entry) {
                    return FlSpot(
                      entry.key.toDouble(),
                      (entry.value['weight'] as double),
                    );
                  }).toList(),
              isCurved: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF27AE60),
                  const Color(0xFF27AE60).withValues(alpha: 0.7),
                ],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 2.5,
                    color: const Color(0xFF27AE60),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF27AE60).withValues(alpha: 0.3),
                    const Color(0xFF27AE60).withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: AppTheme.lightTheme.colorScheme.surface,
              tooltipRoundedRadius: 8,
              tooltipPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final flSpot = barSpot;
                  final index = flSpot.x.toInt();
                  if (index >= 0 && index < _weightData.length) {
                    final data = _weightData[index];
                    final date = data['date'] as DateTime;
                    final weight = data['weight'] as double;
                    final bmi = data['bmi'] as double;

                    // Format date for tooltip with full date information
                    final fullDateFormat = DateFormat('dd/MM/yyyy HH:mm');
                    final tooltipDate =
                        widget.dateRange == 'Daily'
                            ? DateFormat('dd/MM/yyyy HH:mm').format(date)
                            : DateFormat('dd/MM/yyyy').format(date);

                    return LineTooltipItem(
                      '$tooltipDate\n${weight.toStringAsFixed(1)}kg\nBMI: ${bmi.toStringAsFixed(1)}',
                      TextStyle(
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                        fontSize: 10.sp,
                      ),
                    );
                  }
                  return null;
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (_weightData.isEmpty) {
      return SizedBox.shrink();
    }

    final currentWeight = _weightData.last['weight'] as double;
    final currentBmi = _weightData.last['bmi'] as double;
    final bmiCategory =
        currentBmi > 0
            ? BodyMetricsService.instance.getBMICategory(currentBmi)
            : 'N/A';

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: const Color(0xFF27AE60).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Peso attuale',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF27AE60),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '${currentWeight.toStringAsFixed(1)} kg',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF27AE60),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stato IMC',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  currentBmi > 0
                      ? '$bmiCategory (${currentBmi.toStringAsFixed(1)})'
                      : 'Non disponibile',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.lightTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
