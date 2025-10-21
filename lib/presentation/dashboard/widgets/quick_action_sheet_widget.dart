import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class QuickActionSheetWidget extends StatelessWidget {
  final VoidCallback onLogMeal;
  final VoidCallback onAddRecipe;
  final VoidCallback onTakePhoto;

  const QuickActionSheetWidget({
    Key? key,
    required this.onLogMeal,
    required this.onAddRecipe,
    required this.onTakePhoto,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'Azioni Rapide',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 3.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                'Registra Pasto',
                CustomIconWidget(
                  iconName: 'restaurant_menu',
                  color: Colors.white,
                  size: 24,
                ),
                Colors.green,
                onLogMeal,
              ),
              _buildActionButton(
                'Aggiungi Ricetta',
                CustomIconWidget(
                  iconName: 'menu_book',
                  color: Colors.white,
                  size: 24,
                ),
                Colors.blue,
                onAddRecipe,
              ),
              _buildActionButton(
                'Scatta Foto',
                CustomIconWidget(
                  iconName: 'camera_alt',
                  color: Colors.white,
                  size: 24,
                ),
                Colors.orange,
                onTakePhoto,
              ),
            ],
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    CustomIconWidget icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 18.w,
            height: 18.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(child: icon),
          ),
        ),
        SizedBox(height: 1.5.h),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
