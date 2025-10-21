import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SettingsSectionWidget extends StatelessWidget {
  final String title;
  final List<SettingsItemData> items;

  const SettingsSectionWidget({
    Key? key,
    required this.title,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Text(
            title,
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
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
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.h,
                    ),
                    leading: Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: BoxDecoration(
                        color: item.iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIconWidget(
                        iconName: item.iconName,
                        color: item.iconColor,
                        size: 5.w,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: item.subtitle != null
                        ? Text(
                            item.subtitle!,
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        : null,
                    trailing: item.hasSwitch
                        ? Switch(
                            value: item.switchValue ?? false,
                            onChanged: item.onSwitchChanged,
                          )
                        : item.trailingText != null
                            ? Text(
                                item.trailingText!,
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                ),
                              )
                            : CustomIconWidget(
                                iconName: 'chevron_right',
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                                size: 5.w,
                              ),
                    onTap: item.onTap,
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.2),
                      indent: 18.w,
                      endIndent: 4.w,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class SettingsItemData {
  final String title;
  final String? subtitle;
  final String iconName;
  final Color iconColor;
  final VoidCallback? onTap;
  final bool hasSwitch;
  final bool? switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final String? trailingText;

  SettingsItemData({
    required this.title,
    this.subtitle,
    required this.iconName,
    required this.iconColor,
    this.onTap,
    this.hasSwitch = false,
    this.switchValue,
    this.onSwitchChanged,
    this.trailingText,
  });
}
