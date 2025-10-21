import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class RecipeCardWidget extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onShare;
  final VoidCallback? onLongPress;

  const RecipeCardWidget({
    Key? key,
    required this.recipe,
    this.onTap,
    this.onFavorite,
    this.onShare,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String title = recipe['title'] ?? 'Ricetta Senza Nome';
    final int prepTime = recipe['prep_time_minutes'] ?? recipe['prepTime'] ?? 0;
    final int servings = recipe['servings'] ?? 1;
    final String difficulty = recipe['difficulty'] ?? 'Easy';
    final bool isFavorite = recipe['isFavorite'] ?? false;
    final List<String> tags = (recipe['tags'] as List?)?.cast<String>() ?? [];

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3.w),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Placeholder - No Images
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(3.w),
                  ),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(3.w),
                      ),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primaryLight.withValues(alpha: 0.1),
                              AppTheme.secondaryLight.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomIconWidget(
                                iconName: 'restaurant_menu',
                                size: 8.w,
                                color: AppTheme.primaryLight
                                    .withValues(alpha: 0.4),
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                title,
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme.primaryLight
                                      .withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16.sp,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Favorite Button
                    if (onFavorite != null)
                      Positioned(
                        top: 2.w,
                        right: 2.w,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: IconButton(
                            padding: EdgeInsets.all(1.w),
                            constraints: const BoxConstraints(),
                            onPressed: onFavorite,
                            icon: CustomIconWidget(
                              iconName:
                                  isFavorite ? 'favorite' : 'favorite_border',
                              size: 5.w,
                              color: isFavorite
                                  ? AppTheme.errorLight
                                  : AppTheme.neutralLight,
                            ),
                          ),
                        ),
                      ),
                    // Difficulty Badge
                    Positioned(
                      top: 2.w,
                      left: 2.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.5.w, // Slightly increased padding
                          vertical: 0.8.h, // Increased vertical padding
                        ),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(difficulty),
                          borderRadius: BorderRadius.circular(1.w),
                        ),
                        child: Text(
                          difficulty,
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.sp, // Increased from 10.sp to 13.sp
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Recipe Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(2.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title (smaller since it's also in the placeholder)
                    Text(
                      title,
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryLight,
                        fontSize: 18.sp,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: 1.5.h),

                    // Tags
                    if (tags.isNotEmpty)
                      Container(
                        height: 3.h, // Increased from 2.5.h to 3.h
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: tags.take(2).length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: EdgeInsets.only(right: 1.w),
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.5.w, // Increased padding
                                vertical: 0.8.h, // Increased padding
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(1.w),
                              ),
                              child: Text(
                                tags[index],
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme.primaryLight,
                                  fontSize:
                                      14.sp, // Increased from 11.sp to 14.sp
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    SizedBox(height: 1.5.h),

                    // Recipe Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Time
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'access_time',
                              size: 6.w, // Increased from 4.w to 6.w
                              color: AppTheme.neutralLight,
                            ),
                            SizedBox(
                                width: 1.5.w), // Slightly increased spacing
                            Text(
                              '${prepTime}m',
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.neutralLight,
                                fontSize:
                                    15.sp, // Increased from 12.sp to 15.sp
                                fontWeight: FontWeight.w500, // Added weight
                              ),
                            ),
                          ],
                        ),

                        // Servings
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'person',
                              size: 6.w, // Increased from 4.w to 6.w
                              color: AppTheme.neutralLight,
                            ),
                            SizedBox(
                                width: 1.5.w), // Slightly increased spacing
                            Text(
                              '$servings',
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.neutralLight,
                                fontSize:
                                    15.sp, // Increased from 12.sp to 15.sp
                                fontWeight: FontWeight.w500, // Added weight
                              ),
                            ),
                          ],
                        ),

                        // Share Button
                        if (onShare != null)
                          GestureDetector(
                            onTap: onShare,
                            child: Container(
                              padding: EdgeInsets.all(1.5.w),
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryLight
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: CustomIconWidget(
                                iconName: 'share',
                                size: 4.w,
                                color: AppTheme.secondaryLight,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppTheme.successLight;
      case 'medium':
        return AppTheme.warningLight;
      case 'hard':
        return AppTheme.errorLight;
      default:
        return AppTheme.neutralLight;
    }
  }
}
