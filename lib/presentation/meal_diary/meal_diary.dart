import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/meal_diary_service.dart';
import './widgets/camera_overlay_widget.dart';
import './widgets/date_picker_widget.dart';
import './widgets/meal_timeline_widget.dart';
import './widgets/search_filter_widget.dart';

class MealDiary extends StatefulWidget {
  const MealDiary({Key? key}) : super(key: key);

  @override
  State<MealDiary> createState() => _MealDiaryState();
}

class _MealDiaryState extends State<MealDiary> with TickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _isSearchExpanded = false;
  bool _isLoading = false;
  XFile? _capturedImage;
  int _selectedNavIndex = 1; // Meal Diary is index 1

  // Real user data from Supabase
  List<Map<String, dynamic>> _userMeals = [];
  bool _hasUserMeals = false;

  @override
  void initState() {
    super.initState();
    _loadUserMeals();

    // Listen for navigation to refresh meals when returning from add meal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null) {
        _handleArguments(args);
      }
    });
  }

  void _handleArguments(dynamic args) {
    if (args is Map<String, dynamic>) {
      // Handle return from add meal with specific date
      if (args.containsKey('selected_date')) {
        final returnedDate = args['selected_date'] as DateTime?;
        if (returnedDate != null) {
          setState(() {
            _selectedDate = returnedDate;
          });
          _loadUserMeals();
        }
      }

      // Handle meal added confirmation
      if (args.containsKey('meal_added')) {
        _refreshData();
      }
    }
  }

  Future<void> _loadUserMeals() async {
    if (!AuthService.instance.isAuthenticated) {
      setState(() {
        _userMeals = [];
        _hasUserMeals = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final meals = await MealDiaryService.instance.getUserMeals(
        specificDate: _selectedDate,
      );

      final hasAnyMeals = await MealDiaryService.instance.hasUserMeals();

      setState(() {
        _userMeals = meals;
        _hasUserMeals = hasAnyMeals;
        _isLoading = false;
      });
    } catch (error) {
      print('Error loading meals: $error');
      setState(() {
        _userMeals = [];
        _hasUserMeals = false;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredMeals {
    List<Map<String, dynamic>> filtered = _userMeals.where((meal) {
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final notes = (meal['notes'] ?? '').toString().toLowerCase();
        final name = (meal['name'] ?? '')
            .toString()
            .toLowerCase(); // Fixed: was using meal_type instead of name
        final mealType = (meal['type'] ?? '')
            .toString()
            .toLowerCase(); // Fixed: correct field name
        if (!notes.contains(_searchQuery.toLowerCase()) &&
            !name.contains(_searchQuery.toLowerCase()) &&
            !mealType.contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }

      // Apply category filter - Fixed: using correct transformed meal type field
      switch (_selectedFilter) {
        case 'breakfast':
          return meal['type'] ==
              'Colazione'; // Fixed: using Italian labels from service
        case 'lunch':
          return meal['type'] == 'Pranzo';
        case 'dinner':
          return meal['type'] == 'Cena';
        case 'snack':
          return meal['type'] == 'Spuntino';
        default:
          return true;
      }
    }).toList();

    // Sort by meal time - Fixed: using correct field name
    filtered.sort((a, b) {
      final timeA = a['time'] ?? '00:00'; // Fixed: correct field name
      final timeB = b['time'] ?? '00:00'; // Fixed: correct field name
      return timeA.compareTo(timeB);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppTheme.lightTheme.colorScheme.primary,
        child: Column(
          children: [
            DatePickerWidget(
              selectedDate: _selectedDate,
              onDateChanged: _onDateChanged,
              onTodayPressed: _onTodayPressed,
            ),
            SearchFilterWidget(
              searchQuery: _searchQuery,
              selectedFilter: _selectedFilter,
              onSearchChanged: _onSearchChanged,
              onFilterChanged: _onFilterChanged,
              isExpanded: _isSearchExpanded,
              onToggleExpanded: _toggleSearchExpanded,
            ),
            Expanded(
              child: _isLoading ? _buildLoadingState() : _buildMealContent(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildMealContent() {
    if (!AuthService.instance.isAuthenticated) {
      return _buildAuthRequiredState();
    }

    if (!_hasUserMeals) {
      return _buildEmptyFirstTimeState();
    }

    if (_filteredMeals.isEmpty) {
      return _buildEmptyDateState();
    }

    return Column(children: [Expanded(child: _buildMealTimeline())]);
  }

  Widget _buildAuthRequiredState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'login',
            size: 15.w,
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
          SizedBox(height: 3.h),
          Text(
            'Accedi per visualizzare il tuo diario pasti',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Text(
            'Tieni traccia dei tuoi pasti quotidiani e monitora i tuoi progressi nutrizionali',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          ElevatedButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.loginScreen),
            child: Text('Accedi'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFirstTimeState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'restaurant_menu',
              size: 20.w,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
            SizedBox(height: 4.h),
            Text(
              'Benvenuto nel tuo Diario Pasti!',
              style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              'Inizia a tracciare i tuoi pasti per monitorare la tua alimentazione e raggiungere i tuoi obiettivi nutrizionali.',
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            ElevatedButton.icon(
              onPressed: _onAddMeal,
              icon: CustomIconWidget(
                iconName: 'add',
                color: Colors.white,
                size: 6.w,
              ),
              label: Text(
                'Aggiungi il tuo primo pasto',
                style: TextStyle(fontSize: 16.sp),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3.w),
                ),
              ),
            ),
            SizedBox(height: 3.h),
            OutlinedButton.icon(
              onPressed: _openCamera,
              icon: CustomIconWidget(
                iconName: 'camera_alt',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
              label: Text(
                'Scatta foto del pasto',
                style: TextStyle(fontSize: 16.sp),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3.w),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDateState() {
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'event_available',
              size: 15.w,
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 3.h),
            Text(
              isToday
                  ? 'Nessun pasto registrato oggi'
                  : 'Nessun pasto in questa data',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              isToday
                  ? 'Inizia a tracciare i tuoi pasti di oggi per monitorare la tua alimentazione'
                  : 'Cambia data o aggiungi un pasto per iniziare',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            if (isToday) ...[
              ElevatedButton.icon(
                onPressed: _onAddMeal,
                icon: CustomIconWidget(
                  iconName: 'add',
                  color: Colors.white,
                  size: 5.w,
                ),
                label: Text('Aggiungi pasto'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 1.5.h,
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              TextButton.icon(
                onPressed: _openCamera,
                icon: CustomIconWidget(
                  iconName: 'camera_alt',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 5.w,
                ),
                label: Text('Scatta foto'),
              ),
            ] else ...[
              TextButton(onPressed: _onTodayPressed, child: Text('Vai a oggi')),
            ],
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Diario pasti',
        style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.lightTheme.colorScheme.primary,
        ),
      ),
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: _showMealSummary,
          icon: CustomIconWidget(
            iconName: 'analytics',
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 6.w,
          ),
        ),
        IconButton(
          onPressed: _showSettings,
          icon: CustomIconWidget(
            iconName: 'more_vert',
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 6.w,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
          SizedBox(height: 2.h),
          Text(
            'Caricamento pasti...',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTimeline() {
    return Slidable(
      groupTag: 'meal_timeline',
      child: MealTimelineWidget(
        meals: _filteredMeals,
        onMealTap: _onMealTap,
        onDuplicateMeal: _onDuplicateMeal,
        onShareMeal: _onShareMeal,
        onAddToFavorites: _onAddToFavorites,
        onAddMeal: _onAddMeal,
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _openCamera,
      backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
      child: CustomIconWidget(
        iconName: 'camera_alt',
        color: AppTheme.lightTheme.colorScheme.onSecondary,
        size: 7.w,
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
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
        currentIndex: _selectedNavIndex,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12.sp,
        unselectedFontSize: 12.sp,
        elevation: 0,
        items: const [
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
        ],
      ),
    );
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedNavIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        break;
      case 1:
        // Already on Meal Diary - stay on current screen
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

  void _onDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadUserMeals();
  }

  void _onTodayPressed() {
    setState(() {
      _selectedDate = DateTime.now();
    });
    _loadUserMeals();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  void _toggleSearchExpanded() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
    });
  }

  Future<void> _refreshData() async {
    await _loadUserMeals();

    // Show confirmation if we just added a meal
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args.containsKey('meal_added')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                CustomIconWidget(
                  iconName: 'check_circle',
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Pasto aggiunto al diario!',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      });
    }
  }

  void _onMealTap(Map<String, dynamic> meal) {
    // Refresh the meal data after potential updates
    _loadUserMeals();
  }

  void _onDuplicateMeal(Map<String, dynamic> meal) {
    // TODO: Implement meal duplication using MealDiaryService
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Funzione in sviluppo'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      ),
    );
  }

  void _onShareMeal(Map<String, dynamic> meal) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pasto condiviso con il medico'),
        backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
      ),
    );
  }

  void _onAddToFavorites(Map<String, dynamic> meal) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pasto aggiunto ai preferiti'),
        backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
      ),
    );
  }

  void _onAddMeal() {
    Navigator.pushNamed(
      context,
      AppRoutes.addMeal,
      arguments: {'selected_date': _selectedDate}, // Pass current selected date
    );
  }

  void _openCamera() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CameraOverlayWidget(
          onPhotoTaken: _onPhotoTaken,
          onClose: () => Navigator.of(context).pop(),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _onPhotoTaken(XFile photo) {
    setState(() {
      _capturedImage = photo;
    });

    Navigator.of(context).pop();
    Navigator.pushNamed(
      context,
      AppRoutes.addMeal,
      arguments: {
        'photo': photo,
        'timestamp': DateTime.now(),
        'selected_date': _selectedDate, // Pass current selected date
      },
    );
  }

  void _showMealSummary() async {
    if (!AuthService.instance.isAuthenticated) {
      _showAuthRequiredDialog();
      return;
    }

    try {
      final summary = await MealDiaryService.instance.getNutritionalSummary(
        specificDate: _selectedDate,
      );

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Riassunto giornaliero',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSummaryRow(
                'Calorie totali',
                '${summary['total_calories']?.toStringAsFixed(0) ?? '0'} kcal',
              ),
              _buildSummaryRow(
                'Proteine',
                '${summary['total_protein']?.toStringAsFixed(1) ?? '0'}g',
              ),
              _buildSummaryRow(
                'Carboidrati',
                '${summary['total_carbs']?.toStringAsFixed(1) ?? '0'}g',
              ),
              _buildSummaryRow(
                'Grassi',
                '${summary['total_fat']?.toStringAsFixed(1) ?? '0'}g',
              ),
              _buildSummaryRow(
                'Fibre',
                '${summary['total_fiber']?.toStringAsFixed(1) ?? '0'}g',
              ),
              _buildSummaryRow(
                'Pasti registrati',
                '${summary['meal_count'] ?? 0}',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Chiudi',
                style: TextStyle(
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, AppRoutes.reports);
              },
              child: const Text('Visualizza report'),
            ),
          ],
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nel caricamento del riassunto: $error')),
      );
    }
  }

  void _showAuthRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Accesso richiesto'),
        content: Text(
          'Devi effettuare l\'accesso per utilizzare questa funzione.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, AppRoutes.loginScreen);
            },
            child: Text('Accedi'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.lightTheme.textTheme.bodyMedium),
          Text(
            value,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(5.w)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 1.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(0.5.h),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Opzioni diario pasti',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3.h),
            _buildSettingsOption('Esporta dati', 'download', () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, AppRoutes.reports);
            }),
            _buildSettingsOption('Sincronizza con medico', 'sync', () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sincronizzazione con il medico...'),
                ),
              );
            }),
            _buildSettingsOption('Impostazioni', 'settings', () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, AppRoutes.profileSettings);
            }),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption(
    String title,
    String iconName,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: CustomIconWidget(
        iconName: iconName,
        color: AppTheme.lightTheme.colorScheme.primary,
        size: 6.w,
      ),
      title: Text(title, style: AppTheme.lightTheme.textTheme.bodyLarge),
      trailing: CustomIconWidget(
        iconName: 'chevron_right',
        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        size: 5.w,
      ),
      onTap: onTap,
    );
  }
}
