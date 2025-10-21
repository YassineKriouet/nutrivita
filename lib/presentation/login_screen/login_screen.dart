import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import './widgets/biometric_prompt_widget.dart';
import './widgets/error_message_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _showBiometricPrompt = false;
  String? _errorMessage;
  String? _prefilledEmail;
  final FocusNode _focusNode = FocusNode();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ensureDemoUserExists();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['email'] != null) {
        _prefilledEmail = args['email'];
        _emailController.text = _prefilledEmail!;
      }
    });
  }

  // Ensure demo user exists for testing
  void _ensureDemoUserExists() async {
    try {
      await AuthService.instance.ensureDemoUserExists();
    } catch (error) {
      print('Demo user setup error: $error');
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Inserisci email e password per continuare.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AuthService.instance.signIn(
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        HapticFeedback.lightImpact();

        String successMessage =
            'Benvenuto, ${result['user_name'] ?? 'Utente'}!';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                successMessage,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Navigate to dashboard
          _navigateToDashboard();
        }
      }
    } catch (error) {
      HapticFeedback.heavyImpact();
      String errorMessage = error.toString().replaceAll('Exception: ', '');

      // Enhanced error handling for specific cases
      if (errorMessage.contains('Account non trovato')) {
        errorMessage = 'Account non trovato. Verifica l\'email o registrati.';
      } else if (errorMessage.contains('Email o password non corretti') ||
          errorMessage.contains('Invalid login credentials')) {
        errorMessage = 'Email o password non corretti. Riprova.';
      } else if (errorMessage.contains('Account disattivato')) {
        errorMessage = 'Account disattivato. Contatta il supporto tecnico.';
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

  void _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Inserisci la tua email per recuperare la password.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AuthService.instance.forgotPassword(email);

      if (result['success'] == true) {
        HapticFeedback.lightImpact();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Email di reset password inviata!',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (error) {
      setState(() {
        _errorMessage = error.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleBiometricSetup() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate biometric setup
    await Future.delayed(Duration(milliseconds: 1000));

    HapticFeedback.lightImpact();
    _navigateToDashboard();
  }

  void _skipBiometric() {
    HapticFeedback.selectionClick();
    _navigateToDashboard();
  }

  void _navigateToDashboard() {
    Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: GestureDetector(
        onTap: _dismissKeyboard,
        child: SafeArea(
          child: Stack(
            children: [
              // Main Content
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 8.h),

                        // Back Button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/splash-screen',
                                (route) => false,
                              );
                            },
                            icon: CustomIconWidget(
                              iconName: 'arrow_back',
                              color: AppTheme.lightTheme.colorScheme.primary,
                              size: 7.w,
                            ),
                            padding: EdgeInsets.all(2.w),
                            constraints: BoxConstraints(
                              minWidth: 12.w,
                              minHeight: 6.h,
                            ),
                          ),
                        ),

                        SizedBox(height: 2.h),

                        // NutriVita Logo
                        Center(
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4.w),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.lightTheme.colorScheme.primary
                                      .withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: 32.w,
                              height: 20.w,
                              child: Image.asset(
                                'assets/images/NUTRI_VITA_-_REV_3-1758668863375.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 4.h),

                        // Welcome Text
                        Text(
                          'Ciao',
                          style: AppTheme.lightTheme.textTheme.headlineMedium
                              ?.copyWith(
                                color: AppTheme.textPrimaryLight,
                                fontWeight: FontWeight.w600,
                              ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: 1.h),

                        Text(
                          'Accedi al tuo percorso nutrizionale',
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.textMediumEmphasisLight,
                              ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: 4.h),

                        // Error Message
                        if (_errorMessage != null) ...[
                          ErrorMessageWidget(
                            message: _errorMessage!,
                            onRetry: _clearError,
                          ),
                          SizedBox(height: 3.h),
                        ],

                        // Login Form
                        _buildLoginForm(),

                        SizedBox(height: 4.h),

                        // Demo Credentials Section
                        _buildDemoCredentials(),

                        SizedBox(height: 4.h),

                        // Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: AppTheme.borderLight,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              child: Text(
                                'oppure',
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textMediumEmphasisLight,
                                    ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: AppTheme.borderLight,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 4.h),

                        // Register Link
                        Center(
                          child: TextButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : () {
                                      Navigator.pushNamed(
                                        context,
                                        '/registration_screen',
                                      );
                                    },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 1.5.h,
                              ),
                            ),
                            child: RichText(
                              text: TextSpan(
                                text: 'Nuovo paziente? ',
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.textMediumEmphasisLight,
                                    ),
                                children: [
                                  TextSpan(
                                    text: 'Registrati',
                                    style: AppTheme
                                        .lightTheme
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color:
                                              AppTheme
                                                  .lightTheme
                                                  .colorScheme
                                                  .primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 2.h),
                      ],
                    ),
                  ),
                ),
              ),

              // Biometric Prompt Overlay
              if (_showBiometricPrompt)
                Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: Center(
                    child: BiometricPromptWidget(
                      onSuccess: _handleBiometricSetup,
                      onCancel: _skipBiometric,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoCredentials() {
    return Container(
      padding: EdgeInsets.all(4.w),
      margin: EdgeInsets.symmetric(horizontal: 2.w),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user,
                color: Colors.green.shade700,
                size: 5.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Credenziali Test Verificate',
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2.w),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Utente Demo:',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 0.5.h),
                GestureDetector(
                  onTap: () {
                    _emailController.text = 'yassine00kriouet@gmail.com';
                    HapticFeedback.lightImpact();
                  },
                  child: Text(
                    '📧 yassine00kriouet@gmail.com',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: Colors.green.shade800,
                      fontFamily: 'monospace',
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _passwordController.text = 'Test123456!';
                    HapticFeedback.lightImpact();
                  },
                  child: Text(
                    '🔐 Test123456!',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: Colors.green.shade800,
                      fontFamily: 'monospace',
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  '💡 Tocca per compilare automaticamente',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.green.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email Field
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'inserisci@email.com',
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
          onChanged: (value) => _clearError(),
        ),

        SizedBox(height: 3.h),

        // Password Field
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Inserisci la tua password',
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: 'lock',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3.w),
            ),
          ),
          onChanged: (value) => _clearError(),
          onFieldSubmitted: (value) => _handleLogin(),
        ),

        SizedBox(height: 2.h),

        // Forgot Password Link
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _isLoading ? null : _handleForgotPassword,
            child: Text(
              'Password dimenticata?',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        SizedBox(height: 4.h),

        // Login Button
        SizedBox(
          width: double.infinity,
          height: 6.h,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
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
                      'Accedi',
                      style: AppTheme.lightTheme.textTheme.titleMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
          ),
        ),
      ],
    );
  }
}
