import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MetricInputCard extends StatelessWidget {
  final String title;
  final String iconName;
  final String value;
  final String unit;
  final VoidCallback onTap;
  final bool showUnitToggle;
  final String? alternateUnit;
  final VoidCallback? onUnitToggle;

  const MetricInputCard({
    Key? key,
    required this.title,
    required this.iconName,
    required this.value,
    required this.unit,
    required this.onTap,
    this.showUnitToggle = false,
    this.alternateUnit,
    this.onUnitToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIconWidget(
                        iconName: iconName,
                        color: AppTheme.lightTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTheme.lightTheme.textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    if (showUnitToggle && alternateUnit != null)
                      GestureDetector(
                        onTap: onUnitToggle,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 1.w,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.outline
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppTheme.lightTheme.colorScheme.outline
                                  .withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                alternateUnit!,
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                      color:
                                          AppTheme
                                              .lightTheme
                                              .colorScheme
                                              .onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              SizedBox(width: 1.w),
                              CustomIconWidget(
                                iconName: 'swap_horiz',
                                color:
                                    AppTheme
                                        .lightTheme
                                        .colorScheme
                                        .onSurfaceVariant,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 3.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          value.isEmpty ? '--' : value,
                          style: AppTheme.lightTheme.textTheme.headlineMedium
                              ?.copyWith(
                                color: AppTheme.lightTheme.primaryColor,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        SizedBox(width: 1.w),
                        Padding(
                          padding: EdgeInsets.only(bottom: 0.5.h),
                          child: Text(
                            unit,
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                                  color:
                                      AppTheme
                                          .lightTheme
                                          .colorScheme
                                          .onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CustomIconWidget(
                          iconName: 'edit',
                          color: AppTheme.lightTheme.colorScheme.outline,
                          size: 20,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Tocca per aggiornare',
                          style: AppTheme.lightTheme.textTheme.bodySmall
                              ?.copyWith(
                                color:
                                    AppTheme
                                        .lightTheme
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
