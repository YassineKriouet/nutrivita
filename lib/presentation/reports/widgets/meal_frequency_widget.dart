import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MealFrequencyWidget extends StatelessWidget {
  final String dateRange;

  const MealFrequencyWidget({
    Key? key,
    required this.dateRange,
  }) : super(key: key);

  List<Map<String, dynamic>> get _mealFrequencyData {
    return [
      {'meal': 'Colazione', 'frequency': 85, 'color': const Color(0xFF2E7D6A)},
      {'meal': 'Pranzo', 'frequency': 92, 'color': const Color(0xFFF28C38)},
      {'meal': 'Cena', 'frequency': 88, 'color': const Color(0xFF27AE60)},
      {'meal': 'Spuntini', 'frequency': 65, 'color': const Color(0xFFF39C12)},
    ];
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
                iconName: 'restaurant',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Analisi frequenza pasti',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.lightTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Consistenza registrazione pasti ($dateRange)',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),
          Container(
            width: double.infinity,
            height: 25.h,
            child: Semantics(
              label: "Grafico a barre analisi frequenza pasti",
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: AppTheme.lightTheme.colorScheme.surface,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final mealData = _mealFrequencyData[group.x.toInt()];
                        return BarTooltipItem(
                          '${mealData['meal']}\n${rod.toY.toInt()}%',
                          TextStyle(
                            color: AppTheme.lightTheme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                            fontSize: 10.sp,
                          ),
                        );
                      },
                    ),
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
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _mealFrequencyData.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Padding(
                                padding: EdgeInsets.only(top: 1.h),
                                child: Text(
                                  _mealFrequencyData[index]['meal'] as String,
                                  style: TextStyle(
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 25,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              '${value.toInt()}%',
                              style: TextStyle(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  barGroups: _mealFrequencyData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: (data['frequency'] as int).toDouble(),
                          color: data['color'] as Color,
                          width: 8.w,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 100,
                            color: AppTheme.lightTheme.colorScheme.outline
                                .withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppTheme.lightTheme.colorScheme.outline
                            .withValues(alpha: 0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'info',
                  color: AppTheme.lightTheme.primaryColor,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'La registrazione consistente dei pasti aiuta a tracciare i modelli nutrizionali durante il trattamento',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.primaryColor,
                      fontWeight: FontWeight.w500,
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
}
