import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NutritionalSummaryWidget extends StatelessWidget {
  final String dateRange;
  final Map<String, dynamic>? summaryData;

  const NutritionalSummaryWidget({
    Key? key,
    required this.dateRange,
    this.summaryData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = summaryData ?? {};

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
                'Riassunto nutrizionale - $dateRange',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.lightTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              Expanded(
                child: _buildNutrientCard(
                  'Calorie',
                  '${(data['total_calories'] ?? 0.0).toStringAsFixed(0)}',
                  'kcal',
                  const Color(0xFF4CAF50),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildNutrientCard(
                  'Proteine',
                  '${(data['total_protein'] ?? 0.0).toStringAsFixed(1)}',
                  'g',
                  const Color(0xFF2196F3),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildNutrientCard(
                  'Carboidrati',
                  '${(data['total_carbs'] ?? 0.0).toStringAsFixed(1)}',
                  'g',
                  const Color(0xFFFF9800),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildNutrientCard(
                  'Grassi',
                  '${(data['total_fat'] ?? 0.0).toStringAsFixed(1)}',
                  'g',
                  const Color(0xFFE91E63),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildSummaryStats(),
        ],
      ),
    );
  }

  Widget _buildNutrientCard(
      String label, String value, String unit, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats() {
    final data = summaryData ?? {};
    final avgCalories =
        (data['avg_calories_per_day'] ?? 0.0).toStringAsFixed(0);
    final mealCount = data['meal_count'] ?? 0;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(2.w),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                avgCalories,
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'kcal/giorno',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 8.w,
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          Column(
            children: [
              Text(
                '$mealCount',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'pasti totali',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
