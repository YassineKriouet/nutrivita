import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class BMIDisplayCard extends StatelessWidget {
  final double? bmiValue;
  final String bmiCategory;

  const BMIDisplayCard({Key? key, this.bmiValue, required this.bmiCategory})
    : super(key: key);

  Color _getBMIColor() {
    if (bmiValue == null)
      return AppTheme.lightTheme.colorScheme.onSurfaceVariant;

    if (bmiValue! < 18.5) return AppTheme.lightTheme.colorScheme.tertiary;
    if (bmiValue! < 25) return const Color(0xFF27AE60);
    if (bmiValue! < 30) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBMIColor().withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _getBMIColor().withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: _getBMIColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'monitor_weight',
                  color: _getBMIColor(),
                  size: 20,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Indice di Massa Corporea (IMC)',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bmiValue != null ? bmiValue!.toStringAsFixed(1) : '--',
                    style: AppTheme.lightTheme.textTheme.headlineLarge
                        ?.copyWith(
                          color: _getBMIColor(),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Valore IMC',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.w,
                    ),
                    decoration: BoxDecoration(
                      color: _getBMIColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      bmiCategory,
                      style: AppTheme.lightTheme.textTheme.labelMedium
                          ?.copyWith(
                            color: _getBMIColor(),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Categoria',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
