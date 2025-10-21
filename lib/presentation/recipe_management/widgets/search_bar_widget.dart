import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onFilterTap;
  final VoidCallback? onVoiceSearch;
  final VoidCallback? onBarcodeSearch;
  final Function(String)? onChanged;

  const SearchBarWidget({
    Key? key,
    required this.controller,
    this.onFilterTap,
    this.onVoiceSearch,
    this.onBarcodeSearch,
    this.onChanged,
  }) : super(key: key);

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  bool _isVoiceActive = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          // Search Input Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: widget.controller,
                onChanged: widget.onChanged,
                decoration: InputDecoration(
                  hintText: 'Cerca ricette, ingredienti...',
                  hintStyle: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.neutralLight,
                    fontSize: 16.sp,
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'search',
                      color: AppTheme.neutralLight,
                      size: 5.w,
                    ),
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Voice Search Button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isVoiceActive = !_isVoiceActive;
                          });
                          widget.onVoiceSearch?.call();
                          // Simulate voice search activation
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) {
                              setState(() {
                                _isVoiceActive = false;
                              });
                            }
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(2.w),
                          child: CustomIconWidget(
                            iconName: _isVoiceActive ? 'mic' : 'mic_none',
                            color:
                                _isVoiceActive
                                    ? AppTheme.primaryLight
                                    : AppTheme.neutralLight,
                            size: 5.w,
                          ),
                        ),
                      ),
                      // Barcode Scanner Button
                      GestureDetector(
                        onTap: widget.onBarcodeSearch,
                        child: Container(
                          padding: EdgeInsets.all(2.w),
                          margin: EdgeInsets.only(right: 2.w),
                          child: CustomIconWidget(
                            iconName: 'qr_code_scanner',
                            color: AppTheme.neutralLight,
                            size: 5.w,
                          ),
                        ),
                      ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 3.w,
                  ),
                ),
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryLight,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          // Filter Button
          GestureDetector(
            onTap: widget.onFilterTap,
            child: Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryLight.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CustomIconWidget(
                iconName: 'tune',
                color: Colors.white,
                size: 6.w,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
