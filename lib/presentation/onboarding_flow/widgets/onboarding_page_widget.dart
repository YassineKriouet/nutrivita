import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class OnboardingPageWidget extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;
  final bool isLastPage;

  const OnboardingPageWidget({
    Key? key,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.isLastPage = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
      child: Column(
        children: [
          // Top spacing reduced
          SizedBox(height: 0.5.h),

          // Main illustration - Further reduced flex for maximum text space
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CustomImageWidget(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          SizedBox(height: 2.h),

          // Content section - Maximized flex for text content
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // NutriVita branding - more compact
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 0.8.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.primaryColor.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'NutriVita',
                    style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                      color: AppTheme.lightTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      fontSize: 13.sp,
                    ),
                  ),
                ),

                SizedBox(height: 2.h),

                // Main headline - optimized sizing
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                    color: AppTheme.lightTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    fontSize: 20.sp,
                  ),
                ),

                SizedBox(height: 1.5.h),

                // Description text - maximized space with smaller font
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 2.w),
                    child: Text(
                      description,
                      textAlign: TextAlign.center,
                      maxLines: null,
                      overflow: TextOverflow.visible,
                      softWrap: true,
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 1.h),

                // Medical context badge for last page - more compact
                isLastPage
                    ? Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.8.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.tertiary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.lightTheme.colorScheme.tertiary
                              .withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomIconWidget(
                            iconName: 'verified_user',
                            color: AppTheme.lightTheme.colorScheme.tertiary,
                            size: 14,
                          ),
                          SizedBox(width: 1.5.w),
                          Text(
                            'Sicuro & Protetto',
                            style: AppTheme.lightTheme.textTheme.labelSmall
                                ?.copyWith(
                                  color:
                                      AppTheme.lightTheme.colorScheme.tertiary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11.sp,
                                ),
                          ),
                        ],
                      ),
                    )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
