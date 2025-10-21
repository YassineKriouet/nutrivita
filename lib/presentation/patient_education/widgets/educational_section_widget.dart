import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../widgets/custom_icon_widget.dart';

class EducationalSectionWidget extends StatefulWidget {
  final Map<String, dynamic> section;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;

  const EducationalSectionWidget({
    super.key,
    required this.section,
    required this.isBookmarked,
    required this.onBookmarkToggle,
  });

  @override
  State<EducationalSectionWidget> createState() =>
      _EducationalSectionWidgetState();
}

class _EducationalSectionWidgetState extends State<EducationalSectionWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: _toggleExpansion,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: (widget.section['color'] as Color).withAlpha(26),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(_isExpanded ? 0 : 16),
                  bottomRight: Radius.circular(_isExpanded ? 0 : 16),
                ),
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: widget.section['color'],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: widget.section['icon'],
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 4.w),

                  // Title
                  Expanded(
                    child: Text(
                      widget.section['title'],
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  // Bookmark button
                  IconButton(
                    onPressed: widget.onBookmarkToggle,
                    icon: CustomIconWidget(
                      iconName:
                          widget.isBookmarked ? 'bookmark' : 'bookmark_border',
                      color: widget.isBookmarked
                          ? const Color(0xFF4CAF50)
                          : Colors.grey[600]!,
                      size: 22,
                    ),
                  ),

                  // Expand/Collapse icon
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: CustomIconWidget(
                      iconName: 'keyboard_arrow_down',
                      color: Colors.grey[600]!,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContent(widget.section['content']),
                  SizedBox(height: 2.h),

                  // Actions row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          _showFullContentModal(context);
                        },
                        icon: const CustomIconWidget(
                          iconName: 'fullscreen',
                          color: Color(0xFF4CAF50),
                          size: 18,
                        ),
                        label: Text(
                          'Visualizzazione completa',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: const Color(0xFF4CAF50),
                            fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildContent(String content) {
    // Parse content for better formatting
    final lines = content.split('\n');
    List<Widget> contentWidgets = [];

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) {
        contentWidgets.add(SizedBox(height: 1.h));
        continue;
      }

      // Bold text (between **)
      if (line.startsWith('**') && line.endsWith('**')) {
        contentWidgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: 1.h, top: 0.5.h),
            child: Text(
              line.replaceAll('**', ''),
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        );
      }
      // Bullet points
      else if (line.startsWith('•')) {
        contentWidgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: 0.5.h, left: 2.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 1.h, right: 2.w),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: widget.section['color'],
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    line.substring(1).trim(),
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      // Regular text
      else {
        contentWidgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: 1.h),
            child: Text(
              line,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[700],
                height: 1.4,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: contentWidgets,
    );
  }

  void _showFullContentModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: EdgeInsets.only(top: 1.h),
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: (widget.section['color'] as Color).withAlpha(
                    26,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: widget.section['color'],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIconWidget(
                        iconName: widget.section['icon'],
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        widget.section['title'],
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const CustomIconWidget(
                        iconName: 'close',
                        color: Colors.grey,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              // Full content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(4.w),
                  child: _buildContent(widget.section['content']),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
