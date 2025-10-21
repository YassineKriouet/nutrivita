import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FilterChipsWidget extends StatelessWidget {
  final List<String> activeFilters;
  final Function(String) onRemoveFilter;
  final VoidCallback? onClearAll;

  const FilterChipsWidget({
    Key? key,
    required this.activeFilters,
    required this.onRemoveFilter,
    this.onClearAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (activeFilters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Clear All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Filters (${activeFilters.length})',
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (activeFilters.isNotEmpty)
                TextButton(
                  onPressed: onClearAll,
                  style: TextButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Clear All',
                    style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.neutralLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 1.h),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: activeFilters.map((filter) {
                return Container(
                  margin: EdgeInsets.only(right: 2.w),
                  child: _buildFilterChip(filter),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter) {
    // Get count badge for specific filters
    final int count = _getFilterCount(filter);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withValues(alpha: 0.1),
        border: Border.all(
          color: AppTheme.primaryLight,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Filter Text
          Text(
            filter,
            style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
              color: AppTheme.primaryLight,
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
            ),
          ),
          // Count Badge (if applicable)
          if (count > 0) ...[
            SizedBox(width: 1.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.5.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ],
          SizedBox(width: 2.w),
          // Remove Button
          GestureDetector(
            onTap: () => onRemoveFilter(filter),
            child: Container(
              padding: EdgeInsets.all(0.5.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: 'close',
                color: AppTheme.primaryLight,
                size: 3.5.w,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getFilterCount(String filter) {
    // Mock count data for demonstration
    final Map<String, int> filterCounts = {
      'My Recipes': 12,
      'Favorites': 8,
      'Public Library': 156,
      'Recently Used': 5,
      'Low Sodium': 23,
      'High Protein': 31,
      'Soft Foods': 18,
      'Anti-Nausea': 14,
      'Dairy-Free': 27,
      'Gluten-Free': 19,
      'Breakfast': 45,
      'Lunch': 38,
      'Dinner': 52,
      'Snack': 29,
      'Smoothie': 16,
      'Supplement': 7,
    };

    return filterCounts[filter] ?? 0;
  }
}
