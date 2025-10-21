import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class TermsPrivacySection extends StatelessWidget {
  final bool termsAccepted;
  final bool privacyAccepted;
  final bool dataProcessingAccepted;
  final Function(bool?) onTermsChanged;
  final Function(bool?) onPrivacyChanged;
  final Function(bool?) onDataProcessingChanged;
  final VoidCallback onTermsPressed;
  final VoidCallback onPrivacyPressed;

  const TermsPrivacySection({
    Key? key,
    required this.termsAccepted,
    required this.privacyAccepted,
    required this.dataProcessingAccepted,
    required this.onTermsChanged,
    required this.onPrivacyChanged,
    required this.onDataProcessingChanged,
    required this.onTermsPressed,
    required this.onPrivacyPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Text(
          'Consensi Obbligatori *',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),

        SizedBox(height: 2.h),

        // Terms of Service Checkbox
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: termsAccepted,
              onChanged: onTermsChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: AppTheme.lightTheme.colorScheme.primary,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 2.w),
                child: RichText(
                  text: TextSpan(
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textPrimaryLight,
                    ),
                    children: [
                      const TextSpan(text: 'Accetto i '),
                      TextSpan(
                        text: 'Termini di Servizio',
                        style: AppTheme.lightTheme.textTheme.bodySmall
                            ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                        recognizer:
                            TapGestureRecognizer()..onTap = onTermsPressed,
                      ),
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 2.h),

        // Privacy Policy Checkbox
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: privacyAccepted,
              onChanged: onPrivacyChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: AppTheme.lightTheme.colorScheme.primary,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 2.w),
                child: RichText(
                  text: TextSpan(
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textPrimaryLight,
                    ),
                    children: [
                      const TextSpan(text: 'Accetto l\''),
                      TextSpan(
                        text: 'Informativa sulla Privacy',
                        style: AppTheme.lightTheme.textTheme.bodySmall
                            ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                        recognizer:
                            TapGestureRecognizer()..onTap = onPrivacyPressed,
                      ),
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 2.h),

        // Data Processing Checkbox
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: dataProcessingAccepted,
              onChanged: onDataProcessingChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: AppTheme.lightTheme.colorScheme.primary,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 2.w),
                child: RichText(
                  text: TextSpan(
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textPrimaryLight,
                    ),
                    children: [
                      const TextSpan(text: 'Accetto il '),
                      TextSpan(
                        text: 'trattamento dei dati personali',
                        style: AppTheme.lightTheme.textTheme.bodySmall
                            ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                        recognizer:
                            TapGestureRecognizer()
                              ..onTap = () {
                                // Navigate to data processing policy
                              },
                      ),
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 2.h),

        // Info text
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(2.w),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 4.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Tutti i consensi sono obbligatori per completare la registrazione in conformità alle normative DPO.',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
