import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../widgets/custom_icon_widget.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearchChanged;
  final String hintText;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onSearchChanged,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(77)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onSearchChanged,
        style: TextStyle(fontSize: 16.sp),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
          prefixIcon: Padding(
            padding: EdgeInsets.all(3.w),
            child: const CustomIconWidget(
              iconName: 'search',
              color: Colors.grey,
              size: 20,
            ),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    controller.clear();
                    onSearchChanged('');
                  },
                  icon: const CustomIconWidget(
                    iconName: 'clear',
                    color: Colors.grey,
                    size: 18,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        ),
      ),
    );
  }
}
