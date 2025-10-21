import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AchievementBadgeWidget extends StatelessWidget {
  final Map<String, dynamic> achievementData;
  final VoidCallback? onTap;

  const AchievementBadgeWidget({
    Key? key,
    required this.achievementData,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = achievementData['title'] as String? ?? 'Achievement';
    final description = achievementData['description'] as String? ?? '';
    final iconName = achievementData['iconName'] as String? ?? 'emoji_events';
    final isUnlocked = achievementData['isUnlocked'] as bool? ?? false;
    final progress = achievementData['progress'] as double? ?? 0.0;
    final category = achievementData['category'] as String? ?? 'general';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32.w,
        margin: EdgeInsets.only(right: 3.w),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: isUnlocked
              ? _getCategoryColor(category).withValues(alpha: 0.1)
              : AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: isUnlocked
              ? Border.all(color: _getCategoryColor(category), width: 1.5)
              : Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3)),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: _getCategoryColor(category).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 16.w,
                  height: 16.w,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? _getCategoryColor(category)
                        : AppTheme.lightTheme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: iconName,
                      color: isUnlocked
                          ? Colors.white
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                ),
                if (!isUnlocked && progress > 0)
                  Positioned(
                    bottom: -1,
                    right: -1,
                    child: Container(
                      width: 5.w,
                      height: 5.w,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(category),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Center(
                        child: Text(
                          '${(progress * 100).toInt()}%',
                          style: AppTheme.lightTheme.textTheme.labelSmall
                              ?.copyWith(
                            fontSize: 7.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 2.5.h),
            Text(
              title,
              style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isUnlocked
                    ? _getCategoryColor(category)
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (description.isNotEmpty) ...[
              SizedBox(height: 1.h),
              Text(
                description,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  fontSize: 10.sp,
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'nutrition':
        return Colors.green;
      case 'consistency':
        return Colors.blue;
      case 'milestone':
        return Colors.orange;
      case 'social':
        return Colors.purple;
      case 'health':
        return Colors.red;
      default:
        return AppTheme.lightTheme.colorScheme.primary;
    }
  }
}
