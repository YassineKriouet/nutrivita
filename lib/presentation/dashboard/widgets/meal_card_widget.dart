import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MealCardWidget extends StatelessWidget {
  final Map<String, dynamic> mealData;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const MealCardWidget({
    Key? key,
    required this.mealData,
    required this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mealName = mealData['name'] as String? ?? 'Unknown Meal';
    final mealType = mealData['type'] as String? ?? 'Meal';
    final calories = mealData['calories'] as int? ?? 0;
    final protein = mealData['protein'] as double? ?? 0.0;
    final carbs = mealData['carbs'] as double? ?? 0.0;
    final imageUrl = mealData['imageUrl'] as String? ?? '';
    final timestamp = mealData['timestamp'] as DateTime? ?? DateTime.now();

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 70.w,
        margin: EdgeInsets.only(right: 3.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
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
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: imageUrl.isNotEmpty
                  ? CustomImageWidget(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      height: 20.h,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: double.infinity,
                      height: 20.h,
                      color: AppTheme.lightTheme.colorScheme.primaryContainer,
                      child: Center(
                        child: CustomIconWidget(
                          iconName: 'restaurant',
                          color: AppTheme.lightTheme.colorScheme.primary,
                          size: 40,
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          mealName,
                          style: AppTheme.lightTheme.textTheme.titleSmall
                              ?.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.lightTheme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                          color: _getMealTypeColor(mealType)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          mealType,
                          style: AppTheme.lightTheme.textTheme.labelSmall
                              ?.copyWith(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w500,
                            color: _getMealTypeColor(mealType),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    _formatTimestamp(timestamp),
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      fontSize: 10.sp,
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 1.5.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNutrientInfo(
                          'Calories', '$calories kcal', Colors.orange),
                      _buildNutrientInfo('Protein',
                          '${protein.toStringAsFixed(1)}g', Colors.blue),
                      _buildNutrientInfo('Carbs',
                          '${carbs.toStringAsFixed(1)}g', Colors.green),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            fontSize: 9.sp,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Color _getMealTypeColor(String mealType) {
    // Handle both Italian and English meal type labels
    switch (mealType.toLowerCase()) {
      // Italian labels (primary)
      case 'colazione':
      case 'breakfast':
        return Colors.orange;
      case 'pranzo':
      case 'lunch':
        return Colors.green;
      case 'cena':
      case 'dinner':
        return Colors.blue;
      case 'spuntino':
      case 'snack':
        return Colors.purple;
      default:
        return AppTheme.lightTheme.colorScheme.primary;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}
