import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/onboarding_page_widget.dart';
import './widgets/page_indicator_widget.dart';
import './widgets/privacy_consent_modal.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({Key? key}) : super(key: key);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int _currentPage = 0;
  bool _showPrivacyModal = false;
  bool _hasAcceptedPrivacy = false;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      "title": "Traccia il tuo percorso nutrizionale",
      "description":
          "Cattura i pasti con la fotocamera. Monitora le calorie e costruisci abitudini alimentari sane.",
      "imageUrl":
          "https://images.unsplash.com/photo-1490645935967-10de6ba17061?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
    },
    {
      "title": "Personalizzato per il tuo trattamento",
      "description":
          "Ricevi consigli dietetici personalizzati. Traccia i progressi e condividi report con il tuo medico.",
      "imageUrl":
          "https://images.pexels.com/photos/6823568/pexels-photo-6823568.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2",
    },
    {
      "title": "La tua salute, i tuoi dati",
      "description":
          "Mantieni il controllo della tua privacy. I tuoi dati rimangono sicuri e protetti.",
      "imageUrl":
          "https://images.unsplash.com/photo-1559757148-5c350d0d3c56?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    _checkPrivacyConsentStatus();
  }

  Future<void> _checkPrivacyConsentStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAccepted = prefs.getBool('privacy_consent_accepted') ?? false;
    setState(() {
      _hasAcceptedPrivacy = hasAccepted;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      // Haptic feedback for iOS
      HapticFeedback.lightImpact();
    } else {
      _handleOnboardingComplete();
    }
  }

  void _skipOnboarding() {
    _handleOnboardingComplete();
  }

  void _handleOnboardingComplete() {
    if (_hasAcceptedPrivacy) {
      // User has already accepted privacy consent, navigate directly to dashboard
      _navigateToDashboard();
    } else {
      // Show privacy consent modal for first time
      _showPrivacyConsentModal();
    }
  }

  void _showPrivacyConsentModal() {
    setState(() {
      _showPrivacyModal = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PrivacyConsentModal(
        onAccept: () async {
          // Save privacy consent acceptance to device storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('privacy_consent_accepted', true);

          setState(() {
            _hasAcceptedPrivacy = true;
          });

          Navigator.of(context).pop();
          _navigateToDashboard();
        },
        onDecline: () {
          Navigator.of(context).pop();
          setState(() {
            _showPrivacyModal = false;
          });
        },
      ),
    );
  }

  void _navigateToDashboard() {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    // Haptic feedback for page changes
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Top bar with skip button
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo matching dashboard size and position
                    Container(
                      height: 50,
                      width: 160,
                      child: Image.asset(
                        'assets/images/NUTRI_VITA_-_REV_3-1758673531220.png',
                        height: 50,
                        width: 160,
                        fit: BoxFit.fitWidth,
                        filterQuality: FilterQuality.high,
                      ),
                    ),

                    // Skip button
                    _currentPage < _onboardingData.length - 1
                        ? TextButton(
                            onPressed: _skipOnboarding,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4.w,
                                vertical: 1.h,
                              ),
                            ),
                            child: Text(
                              'Salta',
                              style: AppTheme.lightTheme.textTheme.labelLarge
                                  ?.copyWith(
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),

              // Main content area
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _onboardingData.length,
                  itemBuilder: (context, index) {
                    final data = _onboardingData[index];
                    return OnboardingPageWidget(
                      title: data["title"] as String,
                      description: data["description"] as String,
                      imageUrl: data["imageUrl"] as String,
                      isLastPage: index == _onboardingData.length - 1,
                    );
                  },
                ),
              ),

              // Bottom navigation area
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                child: Column(
                  children: [
                    // Page indicators
                    PageIndicatorWidget(
                      currentPage: _currentPage,
                      totalPages: _onboardingData.length,
                    ),

                    SizedBox(height: 2.h),

                    // Action button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _currentPage == _onboardingData.length - 1
                                  ? AppTheme.lightTheme.primaryColor
                                  : AppTheme.lightTheme.colorScheme.secondary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == _onboardingData.length - 1
                                  ? 'Inizia'
                                  : 'Avanti',
                              style: AppTheme.lightTheme.textTheme.labelLarge
                                  ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            CustomIconWidget(
                              iconName:
                                  _currentPage == _onboardingData.length - 1
                                      ? 'rocket_launch'
                                      : 'arrow_forward',
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 1.5.h),

                    // Medical disclaimer
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.lightTheme.colorScheme.outline
                              .withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'info_outline',
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            size: 16,
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Text(
                              'NutriVita è progettata per supportare il tuo percorso nutrizionale. Consulta sempre il tuo medico di famiglia per indicazioni cliniche.',
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: Color(0XFF6C757D),
                                fontFamily: 'Inter_regular',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                height: 1.3,
                                letterSpacing: 0.4,
                                wordSpacing: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
