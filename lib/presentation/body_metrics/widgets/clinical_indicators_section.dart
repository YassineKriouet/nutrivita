import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import './metric_input_card.dart';

class ClinicalIndicatorsSection extends StatefulWidget {
  final String currentWaistCircumference;
  final String currentHipCircumference;
  final String currentLeanMass;
  final String currentFatMass;
  final String currentCellularMass;
  final String currentPhaseAngle;
  final String currentHandGrip;
  final VoidCallback onWaistCircumferenceTap;
  final VoidCallback onHipCircumferenceTap;
  final VoidCallback onLeanMassTap;
  final VoidCallback onFatMassTap;
  final VoidCallback onCellularMassTap;
  final VoidCallback onPhaseAngleTap;
  final VoidCallback onHandGripTap;

  const ClinicalIndicatorsSection({
    Key? key,
    required this.currentWaistCircumference,
    required this.currentHipCircumference,
    required this.currentLeanMass,
    required this.currentFatMass,
    required this.currentCellularMass,
    required this.currentPhaseAngle,
    required this.currentHandGrip,
    required this.onWaistCircumferenceTap,
    required this.onHipCircumferenceTap,
    required this.onLeanMassTap,
    required this.onFatMassTap,
    required this.onCellularMassTap,
    required this.onPhaseAngleTap,
    required this.onHandGripTap,
  }) : super(key: key);

  @override
  State<ClinicalIndicatorsSection> createState() =>
      _ClinicalIndicatorsSectionState();
}

class _ClinicalIndicatorsSectionState extends State<ClinicalIndicatorsSection>
    with TickerProviderStateMixin {
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

    // Haptic feedback for better user experience
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with title and dropdown arrow
          InkWell(
            onTap: _toggleExpansion,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.primaryColor.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CustomIconWidget(
                      iconName: 'biotech',
                      color: AppTheme.lightTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 3.w),

                  // Title and subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Indicatori Nutrizionali Clinici',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          _isExpanded
                              ? 'Tocca per nascondere i parametri clinici'
                              : 'Tocca per visualizzare i parametri clinici avanzati',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dropdown arrow with animation
                  AnimatedBuilder(
                    animation: _expandAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _expandAnimation.value *
                            3.14159, // 180 degrees in radians
                        child: CustomIconWidget(
                          iconName: 'keyboard_arrow_down',
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Expandable content with animation
          SizeTransition(
            sizeFactor: _expandAnimation,
            axisAlignment: -1.0,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppTheme.lightTheme.colorScheme.outline.withValues(
                      alpha: 0.2,
                    ),
                    width: 1,
                  ),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 4.w,
                  right: 4.w,
                  bottom: 2.h,
                  top: 2.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NEW: User requested descriptive text
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.primaryColor
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'medical_services',
                            color: AppTheme.lightTheme.primaryColor,
                            size: 20,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              'Inserisci questi dati se li hai a disposizione in seguito a una visita nutrizionistica',
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.lightTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // Section description
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27AE60).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'info',
                            color: const Color(0xFF27AE60),
                            size: 20,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              'Questi parametri sono solitamente forniti dopo una visita nutrizionale specialistica.',
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: const Color(0xFF27AE60),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // Clinical indicators
                    MetricInputCard(
                      title: 'Circonferenza vita [cm]',
                      iconName: 'straighten',
                      value: widget.currentWaistCircumference,
                      unit: 'cm',
                      onTap: widget.onWaistCircumferenceTap,
                    ),
                    MetricInputCard(
                      title: 'Circonferenza fianchi [cm]',
                      iconName: 'straighten',
                      value: widget.currentHipCircumference,
                      unit: 'cm',
                      onTap: widget.onHipCircumferenceTap,
                    ),
                    MetricInputCard(
                      title: 'Massa magra',
                      iconName: 'fitness_center',
                      value: widget.currentLeanMass,
                      unit: 'kg',
                      onTap: widget.onLeanMassTap,
                    ),
                    MetricInputCard(
                      title: 'Massa grassa',
                      iconName: 'monitor_weight',
                      value: widget.currentFatMass,
                      unit: 'kg',
                      onTap: widget.onFatMassTap,
                    ),
                    MetricInputCard(
                      title: 'Massa cellulare',
                      iconName: 'biotech',
                      value: widget.currentCellularMass,
                      unit: 'kg',
                      onTap: widget.onCellularMassTap,
                    ),
                    MetricInputCard(
                      title: 'Angolo di fase',
                      iconName: 'show_chart',
                      value: widget.currentPhaseAngle,
                      unit: '°',
                      onTap: widget.onPhaseAngleTap,
                    ),
                    MetricInputCard(
                      title: 'Hand Grip',
                      iconName: 'pan_tool',
                      value: widget.currentHandGrip,
                      unit: 'kg',
                      onTap: widget.onHandGripTap,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
