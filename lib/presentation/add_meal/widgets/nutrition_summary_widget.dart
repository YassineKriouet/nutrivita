import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NutritionSummaryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> selectedFoods;

  const NutritionSummaryWidget({Key? key, required this.selectedFoods})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nutritionTotals = _calculateNutritionTotals();
    final dailyTargets = _getDailyTargets();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'analytics',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'Riepilogo Nutrizionale',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          _buildCaloriesCard(
            nutritionTotals['calories'] ?? 0.0,
            dailyTargets['calories'] ?? 2000.0,
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMacroCard(
                  'Proteine',
                  nutritionTotals['protein'] ?? 0.0,
                  dailyTargets['protein'] ?? 150.0,
                  'g',
                  AppTheme.lightTheme.colorScheme.secondary,
                  'fitness_center',
                ),
              ),
              SizedBox(width: 1.5.w),
              Expanded(
                child: _buildMacroCard(
                  'Carboidrati',
                  nutritionTotals['carbs'] ?? 0.0,
                  dailyTargets['carbs'] ?? 250.0,
                  'g',
                  AppTheme.lightTheme.colorScheme.primary,
                  'grain',
                ),
              ),
              SizedBox(width: 1.5.w),
              Expanded(
                child: _buildMacroCard(
                  'Grassi',
                  nutritionTotals['fats'] ?? 0.0,
                  dailyTargets['fats'] ?? 65.0,
                  'g',
                  const Color(0xFFF39C12),
                  'opacity',
                ),
              ),
              SizedBox(width: 1.5.w),
              Expanded(
                child: _buildMacroCard(
                  'Fibre',
                  nutritionTotals['fiber'] ?? 0.0,
                  dailyTargets['fiber'] ?? 25.0,
                  'g',
                  const Color(0xFF27AE60),
                  'eco',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesCard(double current, double target) {
    final percentage = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final remaining = (target - current).clamp(0.0, double.infinity);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
            AppTheme.lightTheme.colorScheme.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calories',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    '${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)}',
                    style:
                        AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(percentage * 100).toStringAsFixed(0)}%',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    '${remaining.toStringAsFixed(0)} remaining',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage < 0.8
                    ? AppTheme.lightTheme.colorScheme.primary
                    : percentage < 1.0
                        ? AppTheme.lightTheme.colorScheme.secondary
                        : AppTheme.lightTheme.colorScheme.error,
              ),
              minHeight: 1.h,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard(
    String name,
    double current,
    double target,
    String unit,
    Color color,
    String iconName,
  ) {
    final percentage = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: EdgeInsets.all(2.5.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          CustomIconWidget(iconName: iconName, color: color, size: 18),
          SizedBox(height: 0.8.h),
          Text(
            name,
            style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10.sp,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 0.4.h),
          Text(
            '${current.toStringAsFixed(1)}$unit',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 11.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 0.8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 0.4.h,
            ),
          ),
          SizedBox(height: 0.4.h),
          Text(
            '${(percentage * 100).toStringAsFixed(0)}%',
            style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                alpha: 0.7,
              ),
              fontSize: 9.sp,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> _calculateNutritionTotals() {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFats = 0;
    double totalFiber = 0;

    try {
      for (final food in selectedFoods) {
        // Enhanced null safety for all food data access
        final quantity = (food["quantity"] as num?)?.toDouble() ?? 100.0;

        // Validate food data before processing
        if (quantity <= 0) continue;

        // Fixed gram-only calculation: (grams / 100g) × nutrition per 100g
        final multiplier = quantity / 100.0;

        // Safe data extraction with null checks and defaults
        final caloriesPer100g = (food["calories_per_100g"] as int?) ?? 0;
        final protein = ((food["protein"] as num?) ?? 0).toDouble();
        final carbs = ((food["carbs"] as num?) ?? 0).toDouble();
        final fats = ((food["fats"] as num?) ?? 0).toDouble();
        final fiber = ((food["fiber"] as num?) ?? 0).toDouble();

        // Accumulate totals with correct gram-based calculation
        totalCalories += caloriesPer100g * multiplier;
        totalProtein += protein * multiplier;
        totalCarbs += carbs * multiplier;
        totalFats += fats * multiplier;
        totalFiber += fiber * multiplier;
      }
    } catch (e) {
      print('Error calculating nutrition totals: $e');
      // Return safe defaults if calculation fails
      return {
        'calories': 0.0,
        'protein': 0.0,
        'carbs': 0.0,
        'fats': 0.0,
        'fiber': 0.0,
      };
    }

    // Ensure all values are non-negative
    return {
      'calories': totalCalories.clamp(0.0, double.infinity),
      'protein': totalProtein.clamp(0.0, double.infinity),
      'carbs': totalCarbs.clamp(0.0, double.infinity),
      'fats': totalFats.clamp(0.0, double.infinity),
      'fiber': totalFiber.clamp(0.0, double.infinity),
    };
  }

  Map<String, double> _getDailyTargets() {
    // Sample daily targets for an average adult (can be personalized)
    return {
      'calories': 2000.0,
      'protein': 150.0,
      'carbs': 250.0,
      'fats': 65.0,
      'fiber': 25.0,
      'sugar': 50.0,
      'sodium': 2300.0,
    };
  }
}
