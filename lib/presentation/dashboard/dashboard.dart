import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/medical_service.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/achievement_badge_widget.dart';
import './widgets/body_card_widget.dart';
import './widgets/kpi_card_widget.dart';
import './widgets/meal_card_widget.dart';
import './widgets/quick_action_sheet_widget.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final _authService = AuthService.instance;
  final _medicalService = MedicalService.instance;
  final _dashboardService = DashboardService.instance;

  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _medicalProfile;
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _dashboardConfig;
  List<dynamic> _dashboardWidgets = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _dashboardService.unsubscribeFromDataChanges();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    _dashboardService.subscribeToDataChanges((updatedData) {
      if (mounted) {
        setState(() {
          _dashboardData = updatedData;
        });
        print(
            'Dashboard UI updated with new data: ${updatedData['nutrition_summary']}');
      }
    });
  }

  Future<void> _loadDashboardData() async {
    if (!_authService.isAuthenticated) {
      Navigator.pushReplacementNamed(context, AppRoutes.loginScreen);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load all dashboard data from database
      final futures = await Future.wait([
        _authService.getCurrentUserProfile(),
        _medicalService.getMedicalProfile(),
        _dashboardService.getDashboardData(),
        _dashboardService.getDashboardConfiguration(),
        _dashboardService.getDashboardWidgets(),
      ]);

      _userProfile = futures[0] as Map<String, dynamic>?;
      _medicalProfile = futures[1] as Map<String, dynamic>?;
      _dashboardData = futures[2] as Map<String, dynamic>;
      _dashboardConfig = futures[3] as Map<String, dynamic>?;
      _dashboardWidgets = futures[4] as List<dynamic>;
    } catch (error) {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    // Show confirmation dialog first
    final bool? shouldSignOut = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const CustomIconWidget(
                iconName: 'logout',
                color: Color(0xFFFF9800),
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Conferma logout',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Text(
            'Sei sicuro di voler uscire dall\'applicazione?',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Annulla',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              ),
              child: Text(
                'Esci',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    // Only proceed with logout if user confirmed
    if (shouldSignOut == true) {
      try {
        await _authService.signOut();
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.loginScreen);
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore durante il logout: $error')),
          );
        }
      }
    }
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => QuickActionSheetWidget(
        onLogMeal: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, AppRoutes.addMeal);
        },
        onAddRecipe: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, AppRoutes.bodyMetrics);
        },
        onTakePhoto: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, AppRoutes.profileSettings);
        },
      ),
    );
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Dashboard - stay on current screen
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.mealDiary);
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.addMeal);
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.reports);
        break;
      case 4:
        Navigator.pushNamed(context, AppRoutes.profileSettings);
        break;
    }
  }

  List<BottomNavigationBarItem> _getBottomNavItems() {
    // Simplified navigation - all users are patients now
    return const [
      BottomNavigationBarItem(
        icon: CustomIconWidget(iconName: 'dashboard', size: 24),
        activeIcon: CustomIconWidget(
          iconName: 'dashboard',
          size: 24,
          color: Color(0xFF4CAF50),
        ),
        label: 'Dashboard',
      ),
      BottomNavigationBarItem(
        icon: CustomIconWidget(iconName: 'book', size: 24),
        activeIcon: CustomIconWidget(
          iconName: 'book',
          size: 24,
          color: Color(0xFF4CAF50),
        ),
        label: 'Diario pasti',
      ),
      BottomNavigationBarItem(
        icon: CustomIconWidget(iconName: 'add_circle_outline', size: 24),
        activeIcon: CustomIconWidget(
          iconName: 'add_circle_outline',
          size: 24,
          color: Color(0xFF4CAF50),
        ),
        label: 'Aggiungi pasto',
      ),
      BottomNavigationBarItem(
        icon: CustomIconWidget(iconName: 'bar_chart', size: 24),
        activeIcon: CustomIconWidget(
          iconName: 'bar_chart',
          size: 24,
          color: Color(0xFF4CAF50),
        ),
        label: 'Report',
      ),
      BottomNavigationBarItem(
        icon: CustomIconWidget(iconName: 'person', size: 24),
        activeIcon: CustomIconWidget(
          iconName: 'person',
          size: 24,
          color: Color(0xFF4CAF50),
        ),
        label: 'Profilo',
      ),
    ];
  }

  void _onRoleSpecificNavTap(int index) {
    // Simplified navigation handler - all users have same navigation
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        break; // Dashboard - stay on current screen
      case 1:
        Navigator.pushNamed(context, AppRoutes.mealDiary);
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.addMeal);
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.reports);
        break;
      case 4:
        Navigator.pushNamed(context, AppRoutes.profileSettings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Container(
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
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await _dashboardService.refreshDashboardData((updatedData) {
                if (mounted) {
                  setState(() {
                    _dashboardData = updatedData;
                  });
                }
              });
            },
            icon: const CustomIconWidget(
              iconName: 'refresh',
              color: Colors.grey,
              size: 24,
            ),
          ),
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.profileSettings),
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF4CAF50),
              child: Text(
                (_userProfile?['full_name'] as String?)?.isNotEmpty == true
                    ? (_userProfile!['full_name'] as String)
                        .substring(0, 1)
                        .toUpperCase()
                    : 'U',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _handleSignOut,
            icon: const CustomIconWidget(
              iconName: 'logout',
              color: Colors.grey,
            ),
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Errore nel caricamento dati dashboard',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14.sp, color: Colors.red),
                      ),
                      SizedBox(height: 2.h),
                      ElevatedButton(
                        onPressed: _loadDashboardData,
                        child: const Text('Riprova'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(2.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Section
                        _buildWelcomeSection(),
                        SizedBox(height: 3.h),

                        // KPI Cards - Data from database
                        _buildKPISection(),
                        SizedBox(height: 3.h),

                        // Quick Actions
                        _buildQuickActionsSection(),
                        SizedBox(height: 3.h),

                        // Body Metrics - From database
                        _buildBodyMetricsSection(),
                        SizedBox(height: 3.h),

                        // Recent Meals - From database
                        _buildRecentMealsSection(),
                        SizedBox(height: 3.h),

                        // Achievements - From database
                        _buildAchievementsSection(),

                        // Add bottom padding to prevent content being hidden by bottom nav
                        SizedBox(height: 10.h),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onRoleSpecificNavTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF4CAF50),
          unselectedItemColor: Colors.grey,
          selectedFontSize: 14.sp,
          unselectedFontSize: 14.sp,
          elevation: 0,
          items: _getBottomNavItems(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickActions,
        backgroundColor: const Color(0xFF4CAF50),
        child: const CustomIconWidget(iconName: 'add', color: Colors.white),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final userName = (_userProfile?['full_name'] as String?)?.isNotEmpty == true
        ? _userProfile!['full_name'] as String
        : 'Utente';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(2.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bentornato, $userName!',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPISection() {
    final nutritionSummary = _dashboardData?['nutrition_summary'] ?? {};
    final todayCalories = (nutritionSummary['total_calories'] ?? 0).toDouble();
    final targetCalories =
        _medicalProfile?['target_daily_calories']?.toDouble() ?? 2000.0;

    // FIXED: Get weight from dashboard data with correct field mapping
    final weightProgress = _dashboardData?['weight_progress'] ?? [];
    final currentWeight = weightProgress.isNotEmpty
        ? (weightProgress.first['weight_kg'] ??
                weightProgress.first['weight'] ??
                0)
            .toDouble()
        : _medicalProfile?['current_weight_kg']?.toDouble() ?? 0.0;
    final targetWeight =
        _medicalProfile?['target_weight_kg']?.toDouble() ?? currentWeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progresso di oggi',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: KpiCardWidget(
                title: 'Calorie',
                value: '${todayCalories.toInt()}',
                target: '${targetCalories.toInt()}',
                unit: 'kcal',
                progress: targetCalories > 0
                    ? (todayCalories / targetCalories).clamp(0.0, 1.0)
                    : 0.0,
                progressColor: const Color(0xFF4CAF50),
                icon: CustomIconWidget(
                  iconName: 'local_fire_department',
                  color: const Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: KpiCardWidget(
                title: 'Peso',
                value: '${currentWeight.toStringAsFixed(1)}',
                target: '${targetWeight.toStringAsFixed(1)}',
                unit: 'kg',
                progress: targetWeight > 0
                    ? (currentWeight / targetWeight).clamp(0.0, 1.0)
                    : 0.0,
                progressColor: const Color(0xFF2196F3),
                icon: CustomIconWidget(
                  iconName: 'monitor_weight',
                  color: const Color(0xFF2196F3),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Azioni rapide',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        // First row - 2 columns
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                'Aggiungi pasto',
                'restaurant',
                const Color(0xFF4CAF50),
                () => Navigator.pushNamed(context, AppRoutes.addMeal),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildQuickActionButton(
                'Registra peso',
                'monitor_weight',
                const Color(0xFF2196F3),
                () => Navigator.pushNamed(context, AppRoutes.bodyMetrics),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.5.h),
        // Second row - 2 columns
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                'Valutazione',
                'quiz',
                const Color(0xFFFF9800),
                () => Navigator.pushNamed(context, AppRoutes.assessmentScreen),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildQuickActionButton(
                'Approfondimenti',
                'school',
                const Color(0xFF673AB7),
                () => Navigator.pushNamed(context, AppRoutes.patientEducation),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.5.h),
        // Third row - 2 columns
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                'Visualizza report',
                'bar_chart',
                const Color(0xFF9C27B0),
                () => Navigator.pushNamed(context, AppRoutes.reports),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildQuickActionButton(
                'Ricette',
                'restaurant_menu',
                const Color(0xFFE91E63),
                () => Navigator.pushNamed(context, AppRoutes.recipeManagement),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    String title,
    String iconName,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: () {
        // Track dashboard interaction
        _dashboardService.trackDashboardInteraction(
          widgetId: 'quick_action_$iconName',
          interactionType: 'click',
          interactionData: {'action': title},
        );
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(iconName: iconName, color: color, size: 36),
            SizedBox(height: 1.5.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyMetricsSection() {
    final height = _medicalProfile?['height_cm']?.toDouble() ?? 175.0;
    final weightProgress = _dashboardData?['weight_progress'] ?? [];
    final currentWeight = weightProgress.isNotEmpty
        ? (weightProgress.first['weight'] ?? 0).toDouble()
        : _medicalProfile?['current_weight_kg']?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Metriche corporee',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.bodyMetrics),
              child: Text(
                'Visualizza tutto',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF4CAF50),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        BodyCardWidget(),
      ],
    );
  }

  Widget _buildRecentMealsSection() {
    final nutritionSummary = _dashboardData?['nutrition_summary'] ?? {};
    final todaysMeals = _dashboardData?['todays_meals'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pasti di oggi',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.mealDiary),
              child: Text(
                'Visualizza tutto',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF4CAF50),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),

        // Check if user has meals today
        todaysMeals.isEmpty
            ? _buildEmptyMealsState(nutritionSummary)
            : _buildMealsList(todaysMeals),
      ],
    );
  }

  Widget _buildEmptyMealsState(Map<String, dynamic> nutritionSummary) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(77)),
      ),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'restaurant',
            color: Colors.grey[400]!,
            size: 40,
          ),
          SizedBox(height: 1.h),
          Text(
            'Nessun pasto registrato oggi',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Aggiungi i tuoi pasti per tracciare le calorie',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.addMeal),
            icon: const CustomIconWidget(
              iconName: 'add',
              color: Colors.white,
              size: 20,
            ),
            label: Text(
              'Aggiungi primo pasto',
              style: TextStyle(fontSize: 14.sp),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsList(List<dynamic> meals) {
    return Column(
      children: [
        // Summary card at the top
        _buildNutritionSummaryCard(),
        SizedBox(height: 2.h),

        // Individual meal cards
        SizedBox(
          height: 28.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: meals.length,
            itemBuilder: (context, index) {
              final meal = meals[index];
              return MealCardWidget(
                mealData: meal,
                onTap: () => Navigator.pushNamed(context, AppRoutes.mealDiary),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionSummaryCard() {
    final nutritionSummary = _dashboardData?['nutrition_summary'] ?? {};
    final todaysMeals = _dashboardData?['todays_meals'] as List<dynamic>? ?? [];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF50).withAlpha(26),
            const Color(0xFF66BB6A).withAlpha(26),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4CAF50).withAlpha(77)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Riepilogo nutrizionale',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4CAF50),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withAlpha(26),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${todaysMeals.length} past${todaysMeals.length != 1 ? 'i' : 'o'}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Calorie',
                '${(nutritionSummary['total_calories'] ?? 0).toInt()}',
                'kcal',
                const Color(0xFFFF9800),
              ),
              Container(
                height: 4.h,
                width: 1,
                color: Colors.grey.withAlpha(77),
              ),
              _buildSummaryItem(
                'Proteine',
                '${(nutritionSummary['total_protein'] ?? 0.0).toStringAsFixed(1)}',
                'g',
                const Color(0xFF2196F3),
              ),
              Container(
                height: 4.h,
                width: 1,
                color: Colors.grey.withAlpha(77),
              ),
              _buildSummaryItem(
                'Carboidrati',
                '${(nutritionSummary['total_carbs'] ?? 0.0).toStringAsFixed(1)}',
                'g',
                const Color(0xFF4CAF50),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          '$value$unit',
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(label, style: TextStyle(fontSize: 13.sp, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    // Get achievements data from database
    final nutritionSummary = _dashboardData?['nutrition_summary'] ?? {};
    final weightProgress = _dashboardData?['weight_progress'] ?? [];
    final assessmentStatus = _dashboardData?['assessment_status'] ?? {};

    final mealsLogged = (nutritionSummary['meals_logged'] ?? 0).toInt();
    final caloriesLogged = (nutritionSummary['total_calories'] ?? 0).toInt();
    final daysTracked = weightProgress.length;
    final hasProfile = _medicalProfile != null;
    final assessmentRate = (assessmentStatus['completion_rate'] ?? 0).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Risultati',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            if (hasProfile)
              AchievementBadgeWidget(
                achievementData: {
                  'title': 'Profilo completo',
                  'description': 'Profilo medico configurato',
                  'iconName': 'person',
                  'isUnlocked': true,
                  'category': 'milestone',
                },
              ),
            if (daysTracked >= 3) ...[
              SizedBox(width: 2.w),
              AchievementBadgeWidget(
                achievementData: {
                  'title': 'Tracker peso',
                  'description': '$daysTracked giorni registrati',
                  'iconName': 'track_changes',
                  'isUnlocked': true,
                  'category': 'consistency',
                },
              ),
            ],
            if (mealsLogged > 0) ...[
              SizedBox(width: 2.w),
              AchievementBadgeWidget(
                achievementData: {
                  'title': 'Registratore pasti',
                  'description': '$mealsLogged pasti tracciati oggi',
                  'iconName': 'restaurant',
                  'isUnlocked': true,
                  'category': 'nutrition',
                },
              ),
            ],
            if (assessmentRate >= 50) ...[
              SizedBox(width: 2.w),
              AchievementBadgeWidget(
                achievementData: {
                  'title': 'Esperto valutazioni',
                  'description': '$assessmentRate% tasso completamento',
                  'iconName': 'quiz',
                  'isUnlocked': true,
                  'category': 'assessment',
                },
              ),
            ],
          ],
        ),
      ],
    );
  }
}
