import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PrivacyConsentModal extends StatefulWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const PrivacyConsentModal({
    Key? key,
    required this.onAccept,
    required this.onDecline,
  }) : super(key: key);

  @override
  State<PrivacyConsentModal> createState() => _PrivacyConsentModalState();
}

class _PrivacyConsentModalState extends State<PrivacyConsentModal> {
  bool _acceptTerms = false;
  bool _acceptPrivacy = false;
  bool _acceptHealthData = false;

  bool get _allAccepted => _acceptTerms && _acceptPrivacy && _acceptHealthData;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 90.w,
        constraints: BoxConstraints(maxHeight: 80.h),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  CustomIconWidget(
                    iconName: 'health_and_safety',
                    color: AppTheme.lightTheme.primaryColor,
                    size: 32,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Privacy e Consenso Dati Sanitari',
                    textAlign: TextAlign.center,
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      color: AppTheme.lightTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'La privacy dei tuoi dati sanitari è la nostra priorità',
                    textAlign: TextAlign.center,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Per fornirti un monitoraggio nutrizionale personalizzato e l\'integrazione con i fornitori sanitari, abbiamo bisogno del tuo consenso per:',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // Terms of Service
                    _buildConsentItem(
                      icon: 'description',
                      title: 'Termini di Servizio',
                      description:
                          'Accordo per utilizzare NutriVita secondo i nostri termini e condizioni',
                      value: _acceptTerms,
                      onChanged: (value) =>
                          setState(() => _acceptTerms = value ?? false),
                    ),

                    SizedBox(height: 2.h),

                    // Privacy Policy
                    _buildConsentItem(
                      icon: 'privacy_tip',
                      title: 'Informativa sulla Privacy',
                      description:
                          'Come raccogliamo, utilizziamo e proteggiamo le tue informazioni personali',
                      value: _acceptPrivacy,
                      onChanged: (value) =>
                          setState(() => _acceptPrivacy = value ?? false),
                    ),

                    SizedBox(height: 2.h),

                    // Health Data Processing
                    _buildConsentItem(
                      icon: 'medical_information',
                      title: 'Elaborazione',
                      description:
                          'Elaborazione di dati nutrizionali e sanitari per supporto terapeutico e supervisione dei fornitori sanitari',
                      value: _acceptHealthData,
                      onChanged: (value) =>
                          setState(() => _acceptHealthData = value ?? false),
                      isRequired: true,
                    ),

                    SizedBox(height: 3.h),

                    // HIPAA Compliance Notice
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.tertiary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.lightTheme.colorScheme.tertiary
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'verified_user',
                            color: AppTheme.lightTheme.colorScheme.tertiary,
                            size: 20,
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Text(
                              'NutriVita è conforme HIPAA e segue standard di sicurezza medici per la protezione dei tuoi dati sanitari.',
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.tertiary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  // Accept button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _allAccepted ? widget.onAccept : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _allAccepted
                            ? AppTheme.lightTheme.primaryColor
                            : AppTheme.lightTheme.colorScheme.outline
                                .withValues(alpha: 0.3),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Accetta e Continua',
                        style:
                            AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // Decline button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: widget.onDecline,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      ),
                      child: Text(
                        'Rifiuta',
                        style:
                            AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentItem({
    required String icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool?> onChanged,
    bool isRequired = false,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.lightTheme.primaryColor,
          ),
          SizedBox(width: 2.w),
          CustomIconWidget(
            iconName: icon,
            color: AppTheme.lightTheme.primaryColor,
            size: 20,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style:
                            AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    isRequired
                        ? Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 2.w, vertical: 0.5.h),
                            decoration: BoxDecoration(
                              color: AppTheme.lightTheme.colorScheme.error
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Obbligatorio',
                              style: AppTheme.lightTheme.textTheme.labelSmall
                                  ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
                SizedBox(height: 1.h),
                Text(
                  description,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
