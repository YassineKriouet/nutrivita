import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MacroDistributionWidget extends StatelessWidget {
  final String dateRange;

  const MacroDistributionWidget({
    Key? key,
    required this.dateRange,
  }) : super(key: key);

  List<Map<String, dynamic>> get _macroData {
    return [
      {
        'name': 'Proteine',
        'value': 25.0,
        'color': AppTheme.lightTheme.primaryColor,
        'grams': 87.5,
      },
      {
        'name': 'Carboidrati',
        'value': 50.0,
        'color': AppTheme.lightTheme.colorScheme.secondary,
        'grams': 175.0,
      },
      {
        'name': 'Grassi',
        'value': 25.0,
        'color': const Color(0xFF27AE60),
        'grams': 61.3,
      },
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
                iconName: 'pie_chart',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Distribuzione macronutrienti',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.lightTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Distribuzione media ($dateRange)',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  height: 25.h,
                  child: Semantics(
                    label: "Grafico a torta distribuzione macronutrienti",
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 8.w,
                        sections: _macroData.map((data) {
                          return PieChartSectionData(
                            color: data['color'] as Color,
                            value: data['value'] as double,
                            title: '${(data['value'] as double).toInt()}%',
                            radius: 12.w,
                            titleStyle: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
                            // Handle touch interactions with haptic feedback
                            if (event is FlTapUpEvent &&
                                pieTouchResponse?.touchedSection != null) {
                              // Add haptic feedback here if needed
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _macroData.map((data) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 2.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4.w,
                                height: 4.w,
                                decoration: BoxDecoration(
                                  color: data['color'] as Color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                data['name'] as String,
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 0.5.h),
                          Padding(
                            padding: EdgeInsets.only(left: 6.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${(data['value'] as double).toInt()}%',
                                  style: AppTheme
                                      .lightTheme.textTheme.titleMedium
                                      ?.copyWith(
                                    color: AppTheme.lightTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${(data['grams'] as double).toStringAsFixed(1)}g avg/day',
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
