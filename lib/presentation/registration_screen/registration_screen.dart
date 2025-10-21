import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import './widgets/medical_fields_section.dart';
import './widgets/password_strength_indicator.dart';
import './widgets/terms_privacy_section.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _showDateValidationError = false;

  // Form Controllers - All fields accessible for both required and optional
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _birthplaceController = TextEditingController();
  final _codiceFiscaleController = TextEditingController();
  final _comuneResidenzaController = TextEditingController();
  final _regionTreatmentController = TextEditingController();
  final _birthDateController = TextEditingController();

  // Form State
  DateTime? _selectedBirthDate;
  String? _selectedGender;

  // Updated consent state - three separate checkboxes
  bool _acceptTerms = false;
  bool _acceptPrivacy = false;
  bool _acceptDataProcessing = false;

  // Password visibility
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _telephoneController.dispose();
    _birthplaceController.dispose();
    _codiceFiscaleController.dispose();
    _comuneResidenzaController.dispose();
    _regionTreatmentController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  String _getPasswordStrength(String password) {
    if (password.length < 6) return 'Debole';
    if (password.length < 8) return 'Medio';
    if (password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Forte';
    }
    return 'Medio';
  }

  void _clearMessages() {
    if (_errorMessage != null || _successMessage != null) {
      setState(() {
        _errorMessage = null;
        _successMessage = null;
        _showDateValidationError = false; // Clear date validation error
      });
    }
  }

  void _handleRegistration() async {
    // Clear any existing messages
    _clearMessages();

    // Validate birth date first
    if (_selectedBirthDate == null) {
      setState(() {
        _showDateValidationError = true;
        _errorMessage = 'Seleziona la tua data di nascita per continuare.';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Updated validation - all three consents required
    if (!_acceptTerms || !_acceptPrivacy || !_acceptDataProcessing) {
      setState(() {
        _errorMessage = 'È necessario accettare tutti i termini per procedere';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await AuthService.instance.registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        birthDate: _selectedBirthDate!,
        genderAtBirth: _selectedGender ?? '',
        name:
            _nameController.text.trim().isEmpty
                ? null
                : _nameController.text.trim(),
        surname:
            _surnameController.text.trim().isEmpty
                ? null
                : _surnameController.text.trim(),
        telephone:
            _telephoneController.text.trim().isEmpty
                ? null
                : _telephoneController.text.trim(),
        birthplace:
            _birthplaceController.text.trim().isEmpty
                ? null
                : _birthplaceController.text.trim(),
        codiceFiscale:
            _codiceFiscaleController.text.trim().isEmpty
                ? null
                : _codiceFiscaleController.text.trim(),
        comuneResidenza:
            _comuneResidenzaController.text.trim().isEmpty
                ? null
                : _comuneResidenzaController.text.trim(),
        // Add consent flags
        acceptedTermsOfService: _acceptTerms,
        acceptedPrivacyPolicy: _acceptPrivacy,
        acceptedDataProcessing: _acceptDataProcessing,
      );

      if (result['success'] == true && result['immediate_login'] == true) {
        HapticFeedback.lightImpact();

        setState(() {
          _successMessage =
              result['message'] ??
              'Registrazione completata! Credenziali salvate e accessibili.';
        });

        // Show success message briefly
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Registrazione completata con successo! Le tue credenziali sono state salvate e saranno disponibili anche dopo il logout.',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );

          // Navigate directly to dashboard since user is already logged in
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/dashboard',
            (route) => false,
          );
        }
      } else {
        // Fallback for unexpected response structure
        setState(() {
          _errorMessage = 'Risposta del server non valida. Riprova.';
        });
      }
    } catch (error) {
      HapticFeedback.heavyImpact();
      String errorMessage = error.toString().replaceAll('Exception: ', '');

      // Enhanced error handling
      if (errorMessage.contains('Utente con questa email esiste già')) {
        errorMessage =
            'Esiste già un account con questa email. Le credenziali sono già salvate - prova ad accedere.';
      } else if (errorMessage.contains('Formato email non valido')) {
        errorMessage = 'Inserisci un indirizzo email valido.';
      } else if (errorMessage.contains('Password deve essere di almeno')) {
        errorMessage = 'La password deve essere di almeno 8 caratteri.';
      } else if (errorMessage.contains(
        'È necessario accettare tutti i termini',
      )) {
        errorMessage = 'È necessario accettare tutti i termini per procedere';
      }

      setState(() {
        _errorMessage = errorMessage;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 4.h),

                // Header with Back Button
                _buildHeader(),

                SizedBox(height: 4.h),

                // Success Message
                if (_successMessage != null) ...[
                  Container(
                    padding: EdgeInsets.all(4.w),
                    margin: EdgeInsets.only(bottom: 3.h),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(3.w),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified_user,
                          color: Colors.green.shade700,
                          size: 6.w,
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _successMessage!,
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                'Le tue credenziali saranno disponibili anche dopo il logout.',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Error Message
                if (_errorMessage != null) ...[
                  Container(
                    padding: EdgeInsets.all(4.w),
                    margin: EdgeInsets.only(bottom: 3.h),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(3.w),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade700,
                          size: 6.w,
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _clearMessages,
                          icon: Icon(
                            Icons.close,
                            color: Colors.red.shade700,
                            size: 5.w,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: 8.w,
                            minHeight: 8.w,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Info Card
                Container(
                  padding: EdgeInsets.all(4.w),
                  margin: EdgeInsets.only(bottom: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(3.w),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 5.w,
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          'I tuoi dati verranno salvati permanentemente nel database e saranno accessibili anche dopo il logout.',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Required Fields Section
                _buildRequiredFields(),

                SizedBox(height: 4.h),

                // Optional Fields Section
                MedicalFieldsSection(
                  nameController: _nameController,
                  surnameController: _surnameController,
                  phoneController: _telephoneController,
                  birthPlaceController: _birthplaceController,
                  fiscalCodeController: _codiceFiscaleController,
                  residenceController: _comuneResidenzaController,
                  selectedGender: _selectedGender,
                  onGenderChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                    _clearMessages();
                  },
                ),

                SizedBox(height: 4.h),

                // Terms and Privacy Section - Updated with three checkboxes
                TermsPrivacySection(
                  termsAccepted: _acceptTerms,
                  privacyAccepted: _acceptPrivacy,
                  dataProcessingAccepted: _acceptDataProcessing,
                  onTermsChanged: (value) {
                    setState(() {
                      _acceptTerms = value ?? false;
                    });
                    _clearMessages();
                  },
                  onPrivacyChanged: (value) {
                    setState(() {
                      _acceptPrivacy = value ?? false;
                    });
                    _clearMessages();
                  },
                  onDataProcessingChanged: (value) {
                    setState(() {
                      _acceptDataProcessing = value ?? false;
                    });
                    _clearMessages();
                  },
                  onTermsPressed: () {
                    // Handle terms press - could navigate to terms page
                  },
                  onPrivacyPressed: () {
                    // Handle privacy press - could navigate to privacy page
                  },
                ),

                SizedBox(height: 4.h),

                // Register Button - Updated to check all three consents
                SizedBox(
                  width: double.infinity,
                  height: 6.h,
                  child: ElevatedButton(
                    onPressed:
                        (!_acceptTerms ||
                                !_acceptPrivacy ||
                                !_acceptDataProcessing ||
                                _isLoading)
                            ? null
                            : _handleRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          (_acceptTerms &&
                                  _acceptPrivacy &&
                                  _acceptDataProcessing &&
                                  !_isLoading)
                              ? AppTheme.lightTheme.colorScheme.primary
                              : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3.w),
                      ),
                      elevation: 0,
                    ),
                    child:
                        _isLoading
                            ? SizedBox(
                              height: 3.h,
                              width: 3.h,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              'Registrati',
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                  ),
                ),

                SizedBox(height: 4.h),

                // Login Link
                Center(
                  child: TextButton(
                    onPressed:
                        _isLoading
                            ? null
                            : () {
                              Navigator.pop(context);
                            },
                    child: RichText(
                      text: TextSpan(
                        text: 'Hai già un account? ',
                        style: AppTheme.lightTheme.textTheme.bodyMedium
                            ?.copyWith(color: AppTheme.textMediumEmphasisLight),
                        children: [
                          TextSpan(
                            text: 'Accedi',
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Back Button
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 7.w,
          ),
          padding: EdgeInsets.all(2.w),
          constraints: BoxConstraints(minWidth: 12.w, minHeight: 6.h),
        ),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Crea Account',
                style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                  color: AppTheme.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                'I tuoi dati vengono salvati permanentemente',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textMediumEmphasisLight,
                ),
              ),
            ],
          ),
        ),

        SizedBox(width: 12.w),
      ],
    );
  }

  Widget _buildRequiredFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informazioni Obbligatorie *',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),

        SizedBox(height: 3.h),

        // Email Field
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email *',
            hintText: 'esempio@email.com',
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: 'email',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3.w),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Email è obbligatoria';
            }
            if (!RegExp(
              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
            ).hasMatch(value.trim())) {
              return 'Inserisci un indirizzo email valido';
            }
            return null;
          },
          onChanged: (value) => _clearMessages(),
        ),

        SizedBox(height: 3.h),

        // Password Field
        TextFormField(
          controller: _passwordController,
          obscureText: !_showPassword,
          decoration: InputDecoration(
            labelText: 'Password *',
            hintText: 'Minimo 8 caratteri',
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: 'lock',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility : Icons.visibility_off,
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              onPressed: () {
                setState(() {
                  _showPassword = !_showPassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3.w),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password è obbligatoria';
            }
            if (value.length < 8) {
              return 'Password deve essere di almeno 8 caratteri';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {});
            _clearMessages();
          },
        ),

        // Password Strength Indicator
        if (_passwordController.text.isNotEmpty) ...[
          SizedBox(height: 1.h),
          PasswordStrengthIndicator(password: _passwordController.text),
        ],

        SizedBox(height: 3.h),

        // Confirm Password Field
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_showConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Conferma Password *',
            hintText: 'Ripeti la password',
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: 'lock',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              onPressed: () {
                setState(() {
                  _showConfirmPassword = !_showConfirmPassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3.w),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Conferma password è obbligatoria';
            }
            if (value != _passwordController.text) {
              return 'Le password non coincidono';
            }
            return null;
          },
          onChanged: (value) => _clearMessages(),
        ),

        SizedBox(height: 3.h),

        // Birth Date Field - CUSTOM DATE PICKER IMPLEMENTATION
        InkWell(
          onTap: () => _showCustomDatePicker(),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 4.w),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(3.w),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'calendar',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data di Nascita *',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        _selectedBirthDate != null
                            ? _formatDate(_selectedBirthDate)
                            : 'Seleziona data',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color:
                              _selectedBirthDate != null
                                  ? AppTheme.lightTheme.colorScheme.onSurface
                                  : AppTheme
                                      .lightTheme
                                      .colorScheme
                                      .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        // Date validation message
        if (_selectedBirthDate == null && _showDateValidationError) ...[
          SizedBox(height: 1.h),
          Padding(
            padding: EdgeInsets.only(left: 3.w),
            child: Text(
              'Data di nascita è obbligatoria',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.lightTheme.colorScheme.error,
              ),
            ),
          ),
        ],

        SizedBox(height: 3.h),

        // Gender Field - MADE OPTIONAL (no validator) - REMOVED FROM REQUIRED SECTION
        // DropdownButtonFormField<String>(
        //   value: _selectedGender,
        //   decoration: InputDecoration(
        //     labelText: 'Sesso alla Nascita (Opzionale)',
        //     prefixIcon: Padding(
        //       padding: EdgeInsets.all(3.w),
        //       child: CustomIconWidget(
        //         iconName: 'person',
        //         color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        //         size: 20,
        //       ),
        //     ),
        //     border: OutlineInputBorder(
        //       borderRadius: BorderRadius.circular(3.w),
        //     ),
        //   ),
        //   items: const [
        //     DropdownMenuItem(value: 'male', child: Text('Maschio')),
        //     DropdownMenuItem(value: 'female', child: Text('Femmina')),
        //     DropdownMenuItem(value: 'other', child: Text('Altro')),
        //     DropdownMenuItem(
        //       value: 'prefer_not_to_say',
        //       child: Text('Preferisco non specificare'),
        //     ),
        //   ],
        //   onChanged: (value) {
        //     setState(() {
        //       _selectedGender = value;
        //     });
        //     _clearMessages();
        //   },
        // ),
      ],
    );
  }

  void _showCustomDatePicker() {
    setState(() {
      _showDateValidationError = false;
    });

    final DateTime now = DateTime.now();
    final DateTime initialDate = _selectedBirthDate ?? DateTime(now.year - 25);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        DateTime selectedYear = DateTime(initialDate.year);
        DateTime selectedMonth = DateTime(initialDate.year, initialDate.month);
        DateTime selectedDay = initialDate;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.w),
              ),
              child: Container(
                padding: EdgeInsets.all(6.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Text(
                      'Seleziona Data di Nascita',
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    SizedBox(height: 4.h),

                    // Year Selection
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 3.w,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.lightTheme.colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Anno',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color:
                                  AppTheme
                                      .lightTheme
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          SizedBox(
                            height: 20.h,
                            child: ListWheelScrollView.useDelegate(
                              itemExtent: 50,
                              controller: FixedExtentScrollController(
                                initialItem: now.year - selectedYear.year,
                              ),
                              onSelectedItemChanged: (index) {
                                setDialogState(() {
                                  selectedYear = DateTime(now.year - index);
                                  selectedMonth = DateTime(
                                    selectedYear.year,
                                    selectedMonth.month,
                                  );
                                  selectedDay = DateTime(
                                    selectedYear.year,
                                    selectedMonth.month,
                                    selectedDay.day >
                                            DateTime(
                                              selectedYear.year,
                                              selectedMonth.month + 1,
                                              0,
                                            ).day
                                        ? DateTime(
                                          selectedYear.year,
                                          selectedMonth.month + 1,
                                          0,
                                        ).day
                                        : selectedDay.day,
                                  );
                                });
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: 100,
                                builder: (context, index) {
                                  final year = now.year - index;
                                  return Container(
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$year',
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        color:
                                            year == selectedYear.year
                                                ? AppTheme
                                                    .lightTheme
                                                    .colorScheme
                                                    .primary
                                                : AppTheme
                                                    .lightTheme
                                                    .colorScheme
                                                    .onSurface,
                                        fontWeight:
                                            year == selectedYear.year
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // Month and Day Selection Row
                    Row(
                      children: [
                        // Month Selection
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 3.w,
                              vertical: 2.w,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppTheme.lightTheme.colorScheme.outline,
                              ),
                              borderRadius: BorderRadius.circular(2.w),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mese',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color:
                                        AppTheme
                                            .lightTheme
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                                ),
                                SizedBox(height: 1.h),
                                SizedBox(
                                  height: 15.h,
                                  child: ListWheelScrollView.useDelegate(
                                    itemExtent: 40,
                                    controller: FixedExtentScrollController(
                                      initialItem: selectedMonth.month - 1,
                                    ),
                                    onSelectedItemChanged: (index) {
                                      setDialogState(() {
                                        selectedMonth = DateTime(
                                          selectedYear.year,
                                          index + 1,
                                        );
                                        final maxDay =
                                            DateTime(
                                              selectedYear.year,
                                              index + 2,
                                              0,
                                            ).day;
                                        if (selectedDay.day > maxDay) {
                                          selectedDay = DateTime(
                                            selectedYear.year,
                                            index + 1,
                                            maxDay,
                                          );
                                        } else {
                                          selectedDay = DateTime(
                                            selectedYear.year,
                                            index + 1,
                                            selectedDay.day,
                                          );
                                        }
                                      });
                                    },
                                    childDelegate:
                                        ListWheelChildBuilderDelegate(
                                          childCount: 12,
                                          builder: (context, index) {
                                            final months = [
                                              'Gen',
                                              'Feb',
                                              'Mar',
                                              'Apr',
                                              'Mag',
                                              'Giu',
                                              'Lug',
                                              'Ago',
                                              'Set',
                                              'Ott',
                                              'Nov',
                                              'Dic',
                                            ];
                                            return Container(
                                              alignment: Alignment.center,
                                              child: Text(
                                                months[index],
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  color:
                                                      (index + 1) ==
                                                              selectedMonth
                                                                  .month
                                                          ? AppTheme
                                                              .lightTheme
                                                              .colorScheme
                                                              .primary
                                                          : AppTheme
                                                              .lightTheme
                                                              .colorScheme
                                                              .onSurface,
                                                  fontWeight:
                                                      (index + 1) ==
                                                              selectedMonth
                                                                  .month
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(width: 3.w),

                        // Day Selection
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 3.w,
                              vertical: 2.w,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppTheme.lightTheme.colorScheme.outline,
                              ),
                              borderRadius: BorderRadius.circular(2.w),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Giorno',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color:
                                        AppTheme
                                            .lightTheme
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                                ),
                                SizedBox(height: 1.h),
                                SizedBox(
                                  height: 15.h,
                                  child: ListWheelScrollView.useDelegate(
                                    itemExtent: 40,
                                    controller: FixedExtentScrollController(
                                      initialItem: selectedDay.day - 1,
                                    ),
                                    onSelectedItemChanged: (index) {
                                      setDialogState(() {
                                        selectedDay = DateTime(
                                          selectedYear.year,
                                          selectedMonth.month,
                                          index + 1,
                                        );
                                      });
                                    },
                                    childDelegate:
                                        ListWheelChildBuilderDelegate(
                                          childCount:
                                              DateTime(
                                                selectedYear.year,
                                                selectedMonth.month + 1,
                                                0,
                                              ).day,
                                          builder: (context, index) {
                                            final day = index + 1;
                                            return Container(
                                              alignment: Alignment.center,
                                              child: Text(
                                                '$day',
                                                style: TextStyle(
                                                  fontSize: 16.sp,
                                                  color:
                                                      day == selectedDay.day
                                                          ? AppTheme
                                                              .lightTheme
                                                              .colorScheme
                                                              .primary
                                                          : AppTheme
                                                              .lightTheme
                                                              .colorScheme
                                                              .onSurface,
                                                  fontWeight:
                                                      day == selectedDay.day
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 4.h),

                    // Selected Date Display
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: AppTheme.lightTheme.colorScheme.primary,
                            size: 5.w,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'Data selezionata: ${_formatDate(selectedDay)}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppTheme.lightTheme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 4.h),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 3.w),
                            ),
                            child: Text(
                              'Annulla',
                              style: TextStyle(
                                color:
                                    AppTheme
                                        .lightTheme
                                        .colorScheme
                                        .onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Validate age (must be at least 13 and not more than 120 years old)
                              final age = now.year - selectedDay.year;
                              if (age < 13) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Devi avere almeno 13 anni per registrarti.',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              if (age > 120) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Inserisci una data di nascita valida.',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                _selectedBirthDate = selectedDay;
                                _birthDateController.text = _formatDate(
                                  selectedDay,
                                );
                                _showDateValidationError = false;
                              });
                              _clearMessages();
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppTheme.lightTheme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 3.w),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2.w),
                              ),
                            ),
                            child: Text(
                              'Conferma',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    try {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}
