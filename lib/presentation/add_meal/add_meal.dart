import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/meal_diary_service.dart';
import '../../widgets/custom_date_picker_widget.dart';
import './widgets/camera_preview_widget.dart';
import './widgets/food_search_widget.dart';
import './widgets/meal_type_selector_widget.dart';
import './widgets/notes_section_widget.dart';
import './widgets/nutrition_summary_widget.dart';

class AddMeal extends StatefulWidget {
  const AddMeal({Key? key}) : super(key: key);

  @override
  State<AddMeal> createState() => _AddMealState();
}

class _AddMealState extends State<AddMeal> {
  String _selectedMealType = 'breakfast';
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime _selectedDate = DateTime.now(); // Add date selection
  XFile? _capturedImage;
  List<Map<String, dynamic>> _selectedFoods = [];
  String _notes = '';
  bool _saveAsFavorite = false;
  bool _shareWithProvider = true;
  bool _isLoading = false;
  int _selectedNavIndex = 2; // Add Meal is index 2

  @override
  void initState() {
    super.initState();
    // Check if we received arguments (for editing or pre-filled data)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null) {
        _handleArguments(args);
      }
    });
  }

  void _handleArguments(dynamic args) {
    if (args is Map<String, dynamic>) {
      setState(() {
        // Handle recipe data from recipe detail screen
        if (args.containsKey('recipe_data')) {
          final recipeData = args['recipe_data'] as Map<String, dynamic>?;
          if (recipeData != null) {
            _addRecipeToSelectedFoods(recipeData);
          }
        }

        // If editing an existing meal
        if (args.containsKey('meal_type')) {
          _selectedMealType = _mapMealTypeFromDB(args['meal_type'] as String);
        }
        if (args.containsKey('meal_time') && args['meal_time'] != null) {
          final timeString = args['meal_time'] as String;
          final timeParts = timeString.split(':');
          _selectedTime = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );
        }
        if (args.containsKey('notes')) {
          _notes = args['notes'] as String? ?? '';
        }
        // Handle photo from camera
        if (args.containsKey('photo')) {
          _capturedImage = args['photo'] as XFile?;
        }
        // Handle selected date from meal diary
        if (args.containsKey('selected_date')) {
          _selectedDate = args['selected_date'] as DateTime;
        }
        // Handle meal date from existing meal
        if (args.containsKey('date')) {
          final dateStr = args['date'] as String?;
          if (dateStr != null) {
            _selectedDate = DateTime.parse(dateStr);
          }
        }
      });
    }
  }

  /// Add recipe to selected foods list
  void _addRecipeToSelectedFoods(Map<String, dynamic> recipeData) {
    try {
      final servings = (recipeData['servings'] as num?)?.toInt() ?? 1;
      final totalCalories =
          (recipeData['total_calories'] as num?)?.toInt() ?? 0;
      final totalProtein =
          (recipeData['total_protein_g'] as num?)?.toDouble() ?? 0.0;
      final totalCarbs =
          (recipeData['total_carbs_g'] as num?)?.toDouble() ?? 0.0;
      final totalFat = (recipeData['total_fat_g'] as num?)?.toDouble() ?? 0.0;

      // Calculate nutritional values per serving
      final caloriesPerServing =
          servings > 0 ? (totalCalories / servings).round() : totalCalories;
      final proteinPerServing =
          servings > 0 ? (totalProtein / servings) : totalProtein;
      final carbsPerServing =
          servings > 0 ? (totalCarbs / servings) : totalCarbs;
      final fatPerServing = servings > 0 ? (totalFat / servings) : totalFat;

      // Create food item from recipe
      final recipeFood = {
        'id': recipeData['id'],
        'name': recipeData['title'] ?? 'Ricetta',
        'type': 'recipe',
        'brand': 'Ricetta personalizzata',
        'calories_per_100g': caloriesPerServing,
        'protein': proteinPerServing,
        'carbs': carbsPerServing,
        'fats': fatPerServing,
        'total_calories': totalCalories,
        'servings_count': servings,
        'quantity': 1.0,
        'selected_serving': '1 porzione',
        'image_url': recipeData['image_url'] ?? recipeData['imageUrl'],
      };

      _selectedFoods.add(recipeFood);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ricetta "${recipeData['title']}" aggiunta al pasto'),
            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error adding recipe to selected foods: $e');
    }
  }

  String _mapMealTypeFromDB(String dbMealType) {
    switch (dbMealType) {
      case 'breakfast':
        return 'breakfast';
      case 'lunch':
        return 'lunch';
      case 'dinner':
        return 'dinner';
      case 'snack':
        return 'snack';
      default:
        return 'breakfast';
    }
  }

  String _mapMealTypeToDB(String displayMealType) {
    switch (displayMealType) {
      case 'Colazione':
      case 'breakfast':
        return 'breakfast';
      case 'Pranzo':
      case 'lunch':
        return 'lunch';
      case 'Cena':
      case 'dinner':
        return 'dinner';
      case 'Spuntino':
      case 'snack':
        return 'snack';
      default:
        return 'breakfast';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigation(),
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
        Navigator.pushReplacementNamed(context, AppRoutes.mealDiary);
        break;
      case 2:
        // Already on Add Meal - stay on current screen
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.reports);
        break;
      case 4:
        Navigator.pushReplacementNamed(context, AppRoutes.profileSettings);
        break;
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => _handleCancel(),
        child: Container(
          margin: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline.withValues(
                alpha: 0.3,
              ),
            ),
          ),
          child: Center(
            child: CustomIconWidget(
              iconName: 'close',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 20,
            ),
          ),
        ),
      ),
      title: Text(
        'Aggiungi pasto',
        style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
          color: AppTheme.lightTheme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        GestureDetector(
          onTap: _isLoading ? null : _handleSave,
          child: Container(
            margin: EdgeInsets.all(2.w),
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: _canSave()
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.outline.withAlpha(77),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Salva',
                    style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                      color: _canSave()
                          ? Colors.white
                          : AppTheme.lightTheme.colorScheme.outline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Selector - New section
            _buildDateSelector(),

            SizedBox(height: 3.h),

            // Meal Type and Time Selector
            MealTypeSelectorWidget(
              selectedMealType: _selectedMealType,
              onMealTypeChanged: (type) {
                setState(() {
                  _selectedMealType = type;
                });
              },
              selectedTime: _selectedTime,
              onTimeChanged: (time) {
                setState(() {
                  _selectedTime = time;
                });
              },
            ),

            SizedBox(height: 3.h),

            // Food Search and Selection - Moved above camera section
            Container(
              child: FoodSearchWidget(
                selectedFoods: _selectedFoods,
                onFoodAdded: (food) {
                  try {
                    print(
                        'Received food to add: ${food['name']} (ID: ${food['id']})');
                    setState(() {
                      _selectedFoods.add(food);
                    });
                    print(
                        'Food added to _selectedFoods. New count: ${_selectedFoods.length}');

                    // Immediately check if save button should be enabled
                    final canSave = _canSave();
                    print('Can save after adding food: $canSave');
                    if (!canSave) {
                      print(
                          'Warning: Food was added but _canSave() returns false');
                      // Try to understand why by checking each food
                      for (int i = 0; i < _selectedFoods.length; i++) {
                        final foodData =
                            _prepareFoodDataForDB(_selectedFoods[i]);
                        print(
                            'Food $i validation result: ${foodData != null ? 'VALID' : 'INVALID'}');
                      }
                    }
                  } catch (e) {
                    print('Error adding food: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Errore nell\'aggiunta del cibo: $e'),
                          backgroundColor:
                              AppTheme.lightTheme.colorScheme.error,
                        ),
                      );
                    }
                  }
                },
                onFoodRemoved: (index) {
                  try {
                    if (index >= 0 && index < _selectedFoods.length) {
                      final removedFood = _selectedFoods[index];
                      print(
                          'Removing food: ${removedFood['name']} at index $index');
                      setState(() {
                        _selectedFoods.removeAt(index);
                      });
                      print(
                          'Food removed. New count: ${_selectedFoods.length}');
                    }
                  } catch (e) {
                    print('Error removing food: $e');
                  }
                },
                onFoodUpdated: (index, field, value) {
                  try {
                    if (index >= 0 &&
                        index < _selectedFoods.length &&
                        value != null) {
                      print('Updating food at index $index: $field = $value');
                      setState(() {
                        _selectedFoods[index][field] = value;
                      });

                      // Check validation after update
                      final foodData =
                          _prepareFoodDataForDB(_selectedFoods[index]);
                      print(
                          'Food validation after update: ${foodData != null ? 'VALID' : 'INVALID'}');
                    }
                  } catch (e) {
                    print('Error updating food: $e');
                  }
                },
              ),
            ),

            SizedBox(height: 3.h),

            // Camera Preview Section - Moved below food search
            CameraPreviewWidget(
              capturedImage: _capturedImage,
              onImageCaptured: (image) {
                setState(() {
                  _capturedImage = image;
                });
              },
            ),

            SizedBox(height: 3.h),

            // Only show nutrition summary if there are valid selected foods
            if (_selectedFoods.isNotEmpty) ...[
              Container(
                child: NutritionSummaryWidget(selectedFoods: _selectedFoods),
              ),
              SizedBox(height: 3.h),
            ],

            // Notes and Options Section
            NotesSectionWidget(
              notes: _notes,
              onNotesChanged: (notes) {
                setState(() {
                  _notes = notes ?? '';
                });
              },
              saveAsFavorite: _saveAsFavorite,
              onSaveAsFavoriteChanged: (value) {
                setState(() {
                  _saveAsFavorite = value ?? false;
                });
              },
              shareWithProvider: _shareWithProvider,
              onShareWithProviderChanged: (value) {
                setState(() {
                  _shareWithProvider = value ?? true;
                });
              },
            ),

            SizedBox(height: 4.h),

            // Log Meal Button
            _buildLogMealButton(),

            SizedBox(height: 10.h), // Extra padding for bottom navigation
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return CustomDatePickerWidget(
      selectedDate: _selectedDate,
      title: 'Data del pasto',
      helpText: 'Seleziona data del pasto',
      onDateSelected: (DateTime pickedDate) {
        setState(() {
          _selectedDate = pickedDate;
        });

        // Show confirmation message
        final isToday = pickedDate.year == DateTime.now().year &&
            pickedDate.month == DateTime.now().month &&
            pickedDate.day == DateTime.now().day;

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
                Expanded(
                  child: Text(
                    isToday
                        ? 'Data impostata per oggi'
                        : 'Data impostata: ${_formatSelectedDate()}',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.all(4.w),
            duration: Duration(seconds: 2),
          ),
        );
      },
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 7)),
      showPastIndicator: true,
    );
  }

  String _formatSelectedDate() {
    final now = DateTime.now();
    if (_selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day) {
      return 'Oggi';
    }

    final yesterday = now.subtract(Duration(days: 1));
    if (_selectedDate.year == yesterday.year &&
        _selectedDate.month == yesterday.month &&
        _selectedDate.day == yesterday.day) {
      return 'Ieri';
    }

    final weekdays = ['', 'Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
    final months = [
      '',
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

    return '${weekdays[_selectedDate.weekday]} ${_selectedDate.day} ${months[_selectedDate.month]}';
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(
        Duration(days: 365),
      ), // Allow up to 1 year ago
      lastDate: DateTime.now().add(
        Duration(days: 7),
      ), // Allow up to 1 week in future
      locale: const Locale('it', 'IT'),
      builder: (context, child) {
        return Theme(
          data: AppTheme.lightTheme.copyWith(
            colorScheme: AppTheme.lightTheme.colorScheme.copyWith(
              primary: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
      helpText: 'Seleziona data del pasto',
      cancelText: 'Annulla',
      confirmText: 'Conferma',
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Widget _buildLogMealButton() {
    return Container(
      width: double.infinity,
      height: 6.h,
      child: ElevatedButton(
        onPressed: _canSave() && !_isLoading ? _handleLogMeal : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _canSave()
              ? AppTheme.lightTheme.colorScheme.primary
              : AppTheme.lightTheme.colorScheme.outline.withAlpha(77),
          foregroundColor: Colors.white,
          elevation: _canSave() ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'Salvataggio pasto...',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'restaurant',
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Registra pasto',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  bool _canSave() {
    // Enhanced validation: check not just for non-empty list, but for valid foods
    if (_selectedFoods.isEmpty) return false;

    // Check if at least one food item is valid
    for (final food in _selectedFoods) {
      final preparedFood = _prepareFoodDataForDB(food);
      if (preparedFood != null) {
        return true; // Found at least one valid food
      }
    }

    return false; // No valid foods found
  }

  void _handleCancel() {
    if (_selectedFoods.isNotEmpty ||
        _capturedImage != null ||
        _notes.isNotEmpty) {
      _showDiscardDialog();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.lightTheme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Scartare le modifiche?',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Hai modifiche non salvate. Sei sicuro di volerle scartare?',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                alpha: 0.8,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Continua modifica',
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text(
                'Scarta',
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSave() async {
    if (!_canSave() || _isLoading) return;

    // Check authentication
    if (!AuthService.instance.isAuthenticated) {
      _showAuthRequiredDialog();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Validate that we have valid foods to save
      if (_selectedFoods.isEmpty) {
        throw Exception('Nessun cibo selezionato per il pasto');
      }

      // Prepare meal foods data for database with improved validation
      final mealFoods = <Map<String, dynamic>>[];

      for (final food in _selectedFoods) {
        final foodData = _prepareFoodDataForDB(food);
        if (foodData != null) {
          mealFoods.add(foodData);
        }
      }

      // Critical validation: ensure we have valid meal foods before proceeding
      if (mealFoods.isEmpty) {
        throw Exception(
            'Nessun cibo valido da salvare. Controlla che tutti i cibi selezionati siano validi.');
      }

      // Create meal entry using MealDiaryService with selected date
      final mealEntry = await MealDiaryService.instance.addMealEntry(
        mealDate: _selectedDate, // Use selected date instead of DateTime.now()
        mealType: _mapMealTypeToDB(_selectedMealType),
        mealTime: _selectedTime,
        notes: _notes.isNotEmpty ? _notes : null,
        foods: mealFoods,
        imageFile: _capturedImage, // Pass captured image to be saved
      );

      // Verify the meal was saved successfully and has foods
      if (mealFoods.isNotEmpty) {
        // Clear the form after successful save
        if (mounted) {
          setState(() {
            _selectedFoods.clear();
            _notes = '';
            _capturedImage = null;
            _selectedTime = TimeOfDay.now();
            // Keep the selected date for potential additional meals
          });
        }

        // Show success message with date confirmation
        if (mounted) {
          final hasImage = _capturedImage != null;
          final dateText = _formatSelectedDate();

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
                  Expanded(
                    child: Text(
                      hasImage
                          ? 'Pasto e foto salvati per $dateText!'
                          : 'Pasto registrato per $dateText!',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: EdgeInsets.all(4.w),
              duration: Duration(seconds: 3),
              action: hasImage
                  ? SnackBarAction(
                      label: 'Visualizza',
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.mealDiary,
                          arguments: {
                            'selected_date': _selectedDate,
                            'show_saved_meal': true,
                          },
                        );
                      },
                    )
                  : null,
            ),
          );

          // Navigate to meal diary with selected date
          Future.delayed(Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.mealDiary,
                arguments: {
                  'selected_date': _selectedDate,
                  'highlight_new_meal': true,
                }, // Pass selected date back
              );
            }
          });
        }
      } else {
        throw Exception(
            'Il pasto è stato salvato ma potrebbe essere incompleto');
      }
    } catch (e) {
      print('Error saving meal: $e');

      // Show specific error messages based on the error type
      if (mounted) {
        String errorMessage;

        if (e.toString().contains('Nessun cibo selezionato')) {
          errorMessage =
              'Devi selezionare almeno un cibo prima di salvare il pasto.';
        } else if (e.toString().contains('Nessun cibo valido')) {
          errorMessage =
              'I cibi selezionati non sono validi. Riprova ad aggiungere gli alimenti.';
        } else if (e.toString().contains('User not authenticated')) {
          errorMessage = 'Devi effettuare l\'accesso per salvare il pasto.';
        } else if (e.toString().contains('Failed to upload image')) {
          errorMessage =
              'Errore nel caricamento dell\'immagine. Il pasto è stato salvato senza foto.';
        } else if (e.toString().contains('violates foreign key constraint') ||
            e.toString().contains('constraint violation')) {
          errorMessage =
              'Errore nella struttura dati. Riprova o contatta il supporto.';
        } else {
          errorMessage =
              'Errore nel salvare il pasto. Controlla la tua connessione e riprova.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                CustomIconWidget(
                  iconName: 'error',
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.all(4.w),
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Riprova',
              textColor: Colors.white,
              onPressed: () {
                // Allow user to retry saving
                _handleSave();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic>? _prepareFoodDataForDB(Map<String, dynamic> food) {
    try {
      final foodId = food['id'];
      final foodName = food['name'];

      // Enhanced validation for essential data
      if (foodId == null) {
        print('Food item missing ID: $food');
        return null;
      }

      if (foodName == null || foodName.toString().trim().isEmpty) {
        print('Food item missing name: $food');
        return null;
      }

      final foodType = (food['type'] as String?) ?? 'food_item';
      final quantity =
          (food['quantity'] as num?)?.toDouble() ?? 100.0; // Default to 100g
      final selectedServing = "100g"; // Always 100g now

      // Validate quantity - updated for grams-only system
      if (quantity <= 0 || quantity > 10000) {
        print('Invalid quantity for food: $food, quantity: $quantity');
        // Instead of returning null, set a default valid quantity
        food['quantity'] = 100.0;
      }

      double finalCalories = 0.0;
      double finalProtein = 0.0;
      double finalCarbs = 0.0;
      double finalFat = 0.0;
      final finalQuantityGrams = quantity; // Direct grams value

      if (foodType == 'recipe') {
        // For recipes, use the pre-calculated calories_per_100g
        final caloriesPer100g = (food['calories_per_100g'] as int?) ?? 0;
        final proteinPer100g = ((food['protein'] as num?) ?? 0).toDouble();
        final carbsPer100g = ((food['carbs'] as num?) ?? 0).toDouble();
        final fatPer100g = ((food['fats'] as num?) ?? 0).toDouble();

        // Fixed calculation: (grams / 100g) × nutrition per 100g
        final multiplier = quantity / 100.0;
        finalCalories = caloriesPer100g * multiplier;
        finalProtein = proteinPer100g * multiplier;
        finalCarbs = carbsPer100g * multiplier;
        finalFat = fatPer100g * multiplier;
      } else {
        // For food items, use direct nutritional values per 100g
        final caloriesPer100g = (food['calories_per_100g'] as int?) ?? 0;
        final proteinPer100g = ((food['protein'] as num?) ?? 0).toDouble();
        final carbsPer100g = ((food['carbs'] as num?) ?? 0).toDouble();
        final fatPer100g = ((food['fats'] as num?) ?? 0).toDouble();

        // Fixed calculation: (grams / 100g) × nutrition per 100g
        final multiplier = quantity / 100.0;
        finalCalories = caloriesPer100g * multiplier;
        finalProtein = proteinPer100g * multiplier;
        finalCarbs = carbsPer100g * multiplier;
        finalFat = fatPer100g * multiplier;
      }

      // Clamp values to reasonable ranges
      finalCalories = finalCalories.clamp(0.0, 50000.0);
      finalProtein = finalProtein.clamp(0.0, 1000.0);
      finalCarbs = finalCarbs.clamp(0.0, 1000.0);
      finalFat = finalFat.clamp(0.0, 1000.0);

      // Ensure we have either food_item_id or recipe_id, but not both
      final Map<String, dynamic> result;
      if (foodType == 'recipe') {
        result = {
          'food_item_id': null,
          'recipe_id': foodId,
          'quantity_grams': finalQuantityGrams,
          'calories': finalCalories,
          'protein_g': finalProtein,
          'carbs_g': finalCarbs,
          'fat_g': finalFat,
        };
      } else {
        result = {
          'food_item_id': foodId,
          'recipe_id': null,
          'quantity_grams': finalQuantityGrams,
          'calories': finalCalories,
          'protein_g': finalProtein,
          'carbs_g': finalCarbs,
          'fat_g': finalFat,
        };
      }

      // Final validation: ensure all required fields are present and valid
      if ((result['food_item_id'] == null && result['recipe_id'] == null) ||
          (result['food_item_id'] != null && result['recipe_id'] != null)) {
        print('Invalid food/recipe ID configuration: $result');
        return null;
      }

      // Debug log successful preparation
      print(
          'Successfully prepared food data for DB: ${result['food_item_id'] ?? result['recipe_id']} with ${result['calories'].toStringAsFixed(1)} calories from ${result['quantity_grams']}g');

      return result;
    } catch (e) {
      print('Error preparing food data for DB: $e');
      print('Food data that caused error: $food');
      return null;
    }
  }

  void _showAuthRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Accesso richiesto',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Devi effettuare l\'accesso per salvare i pasti.',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
              alpha: 0.8,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annulla',
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
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

  Future<void> _handleLogMeal() async {
    await _handleSave();
  }
}
