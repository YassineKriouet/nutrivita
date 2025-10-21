import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class WeightTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> weightData;
  final String dateRange;

  const WeightTrendChart({
    Key? key,
    required this.weightData,
    this.dateRange = 'Ultimi 30 giorni',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline,
          width: 1,
        ),
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
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color:
                      AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'trending_up',
                  color: AppTheme.lightTheme.primaryColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Andamento del Peso',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dateRange,
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.lightTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            height: 35.h,
            padding: EdgeInsets.only(
              left: 2.w,
              right: 3.w,
              top: 2.h,
              bottom: 1.h,
            ),
            child: weightData.isEmpty
                ? _buildEmptyState()
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        drawHorizontalLine: true,
                        horizontalInterval: _calculateWeightInterval(),
                        verticalInterval: _calculateVerticalInterval(),
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppTheme.lightTheme.colorScheme.outline
                                .withValues(alpha: 0.2),
                            strokeWidth: 0.8,
                            dashArray: [5, 5],
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: AppTheme.lightTheme.colorScheme.outline
                                .withValues(alpha: 0.1),
                            strokeWidth: 0.8,
                            dashArray: [5, 5],
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
                            reservedSize: 50,
                            interval: max(1.0, _calculateOptimalInterval()),
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return _buildBottomTitle(value, meta);
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: _calculateWeightInterval(),
                            reservedSize: 55,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return _buildLeftTitle(value, meta);
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          left: BorderSide(
                            color: AppTheme.lightTheme.colorScheme.outline
                                .withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                          bottom: BorderSide(
                            color: AppTheme.lightTheme.colorScheme.outline
                                .withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                          right: BorderSide.none,
                          top: BorderSide.none,
                        ),
                      ),
                      minX: 0,
                      maxX: (weightData.length - 1).toDouble(),
                      minY: _getChartMinY(),
                      maxY: _getChartMaxY(),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _getSpots(),
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: AppTheme.lightTheme.primaryColor,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: AppTheme.lightTheme.primaryColor,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.lightTheme.primaryColor
                                    .withValues(alpha: 0.2),
                                AppTheme.lightTheme.primaryColor
                                    .withValues(alpha: 0.02),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: _buildTouchData(),
                    ),
                  ),
          ),
          SizedBox(height: 2.h),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'insert_chart',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 32,
          ),
          SizedBox(height: 1.h),
          Text(
            'Nessun dato peso disponibile',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Inizia a registrare il tuo peso per vedere le tendenze',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomTitle(double value, TitleMeta meta) {
    final index = value.toInt();
    if (index < 0 || index >= weightData.length) {
      return const SizedBox.shrink();
    }

    try {
      final date = DateTime.parse(
        weightData[index]['recorded_at'] ?? weightData[index]['date'] as String,
      );

      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Padding(
          padding: EdgeInsets.only(top: 1.w),
          child: Text(
            _getDateLabel(date),
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildLeftTitle(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Padding(
        padding: EdgeInsets.only(right: 1.w),
        child: Text(
          '${value.toInt()}kg',
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  LineTouchData _buildTouchData() {
    return LineTouchData(
      enabled: true,
      touchTooltipData: LineTouchTooltipData(
        tooltipBgColor: AppTheme.lightTheme.colorScheme.inverseSurface,
        tooltipRoundedRadius: 8,
        tooltipPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
          return touchedBarSpots.map((barSpot) {
            final index = barSpot.x.toInt();
            if (index >= 0 && index < weightData.length) {
              try {
                final data = weightData[index];
                final date = DateTime.parse(
                  data['recorded_at'] ?? data['date'] as String,
                );
                return LineTooltipItem(
                  '${date.day}/${date.month}/${date.year}\n${barSpot.y.toStringAsFixed(1)} kg',
                  AppTheme.lightTheme.textTheme.bodySmall!.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w600,
                  ),
                );
              } catch (e) {
                return null;
              }
            }
            return null;
          }).toList();
        },
      ),
    );
  }

  List<FlSpot> _getSpots() {
    return weightData.asMap().entries.map((entry) {
      final weight = (entry.value['weight_kg'] as num?)?.toDouble() ??
          (entry.value['weight'] as num?)?.toDouble() ??
          0.0;
      return FlSpot(entry.key.toDouble(), weight);
    }).toList();
  }

  double _getMinWeight() {
    if (weightData.isEmpty) return 0;
    return weightData
        .map((data) =>
            (data['weight_kg'] as num?)?.toDouble() ??
            (data['weight'] as num?)?.toDouble() ??
            0.0)
        .reduce((a, b) => a < b ? a : b);
  }

  double _getMaxWeight() {
    if (weightData.isEmpty) return 100;
    return weightData
        .map((data) =>
            (data['weight_kg'] as num?)?.toDouble() ??
            (data['weight'] as num?)?.toDouble() ??
            0.0)
        .reduce((a, b) => a > b ? a : b);
  }

  double _getChartMinY() {
    if (weightData.isEmpty) return 0;
    final minWeight = _getMinWeight();
    final padding = max(5.0, minWeight * 0.1);
    return max(0.0, minWeight - padding);
  }

  double _getChartMaxY() {
    if (weightData.isEmpty) return 100;
    final maxWeight = _getMaxWeight();
    final padding = max(5.0, maxWeight * 0.1);
    return maxWeight + padding;
  }

  double _calculateOptimalInterval() {
    if (weightData.isEmpty) return 1;

    final dataLength = weightData.length;
    if (dataLength <= 7) return 1;
    if (dataLength <= 14) return 2;
    if (dataLength <= 30) return max(1, (dataLength / 6).ceil()).toDouble();
    return max(1, (dataLength / 8).ceil()).toDouble();
  }

  double _calculateVerticalInterval() {
    if (weightData.isEmpty) return 1;
    return max(1.0, _calculateOptimalInterval());
  }

  double _calculateWeightInterval() {
    if (weightData.isEmpty) return 10;

    final range = _getMaxWeight() - _getMinWeight();
    if (range <= 5) return 1;
    if (range <= 15) return 2;
    if (range <= 30) return 5;
    if (range <= 60) return 10;
    return 20;
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference <= 7) {
      // Show day/month for recent data
      return '${date.day}/${date.month}';
    } else if (difference <= 30) {
      // Show day/month for monthly data
      return '${date.day}/${date.month}';
    } else {
      // Show abbreviated format for older data
      return '${date.day}/${date.month}';
    }
  }

  Widget _buildLegend() {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          _buildLegendItem('Range Salutare', const Color(0xFF27AE60)),
          SizedBox(width: 4.w),
          _buildLegendItem('Preoccupante', const Color(0xFFF39C12)),
          SizedBox(width: 4.w),
          _buildLegendItem('Critico', const Color(0xFFE74C3C)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 3.w,
          height: 3.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
        ),
        SizedBox(width: 1.5.w),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
