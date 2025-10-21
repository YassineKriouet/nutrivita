import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_export.dart';
import '../../../services/recipe_service.dart';

class FoodSearchWidget extends StatefulWidget {
  final List<Map<String, dynamic>> selectedFoods;
  final Function(Map<String, dynamic>) onFoodAdded;
  final Function(int) onFoodRemoved;
  final Function(int, String, dynamic) onFoodUpdated;

  const FoodSearchWidget({
    Key? key,
    required this.selectedFoods,
    required this.onFoodAdded,
    required this.onFoodRemoved,
    required this.onFoodUpdated,
  }) : super(key: key);

  @override
  State<FoodSearchWidget> createState() => _FoodSearchWidgetState();
}

class _FoodSearchWidgetState extends State<FoodSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSuggestions = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _filteredFoods = [];
  List<Map<String, dynamic>> _recentFoods = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _showSuggestions = _searchFocusNode.hasFocus &&
              (_searchController.text.isNotEmpty || _recentFoods.isNotEmpty);
        });
      }
    });
    _loadRecentFoods();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecentFoods() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final foodItemsResponse = await Supabase.instance.client
          .from('food_items')
          .select(
            'id, name, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, is_verified, brand',
          )
          .eq('is_verified', true)
          .order('created_at', ascending: false)
          .limit(5);

      final recipesResponse = await RecipeService.instance.getRecentRecipes(
        limit: 5,
      );

      final recentFoods = <Map<String, dynamic>>[];

      // Add food items with comprehensive null safety - only grams servings
      for (final item in foodItemsResponse) {
        if (item['id'] != null &&
            item['name'] != null &&
            item['name'].toString().trim().isNotEmpty) {
          recentFoods.add({
            'id': item['id'],
            'name': item['name'].toString().trim(),
            'type': 'food_item',
            'category': 'Alimento',
            'calories_per_100g': (item['calories_per_100g'] as int?) ?? 0,
            'protein': ((item['protein_per_100g'] as num?) ?? 0).toDouble(),
            'carbs': ((item['carbs_per_100g'] as num?) ?? 0).toDouble(),
            'fats': ((item['fat_per_100g'] as num?) ?? 0).toDouble(),
            'fiber': ((item['fiber_per_100g'] as num?) ?? 0).toDouble(),
            'brand': (item['brand'] as String?) ?? '',
            'servings': ['100g'], // Only allow grams
            'recent': true,
            'favorite': false,
          });
        }
      }

      // Add recipes with comprehensive null safety - only grams servings
      for (final recipe in recipesResponse) {
        if (recipe['id'] != null &&
            recipe['title'] != null &&
            recipe['title'].toString().trim().isNotEmpty) {
          recentFoods.add({
            'id': recipe['id'],
            'name': recipe['title'].toString().trim(),
            'type': 'recipe',
            'category': _translateCategory(
              (recipe['category'] as String?) ?? 'snack',
            ),
            'calories_per_100g': _calculateRecipeCaloriesPer100g(recipe),
            'protein': ((recipe['total_protein_g'] as num?) ?? 0).toDouble(),
            'carbs': ((recipe['total_carbs_g'] as num?) ?? 0).toDouble(),
            'fats': ((recipe['total_fat_g'] as num?) ?? 0).toDouble(),
            'fiber': ((recipe['total_fiber_g'] as num?) ?? 0).toDouble(),
            'servings': ['100g'], // Only allow grams for recipes too
            'servings_count': (recipe['servings'] as int?) ?? 1,
            'total_calories': (recipe['total_calories'] as int?) ?? 0,
            'recent': true,
            'favorite': false,
          });
        }
      }

      if (mounted) {
        setState(() {
          _recentFoods = recentFoods;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _recentFoods = [];
          _errorMessage = 'Errore nel caricamento degli alimenti recenti';
        });
      }
      print('Error loading recent foods: $e');
    }
  }

  int _calculateRecipeCaloriesPer100g(Map<String, dynamic> recipe) {
    final totalCalories = (recipe['total_calories'] as int?) ?? 0;
    final servings = (recipe['servings'] as int?) ?? 1;
    if (servings == 0) return 0;

    final averageServingWeight = 250.0;
    final totalWeight = averageServingWeight * servings;
    return totalWeight > 0 ? ((totalCalories / totalWeight) * 100).round() : 0;
  }

  String _translateCategory(String category) {
    switch (category.toLowerCase()) {
      case 'breakfast':
        return 'Colazione';
      case 'lunch':
        return 'Pranzo';
      case 'dinner':
        return 'Cena';
      case 'snack':
        return 'Spuntino';
      case 'dessert':
        return 'Dolce';
      case 'beverage':
        return 'Bevanda';
      default:
        return 'Ricetta';
    }
  }

  Future<void> _searchFoods(String query) async {
    if (!mounted) return;

    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _filteredFoods = [];
          _showSuggestions =
              _searchFocusNode.hasFocus && _recentFoods.isNotEmpty;
          _errorMessage = null;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _showSuggestions = true;
      _errorMessage = null;
    });

    try {
      final searchResults = <Map<String, dynamic>>[];

      // Search food items with comprehensive null safety - only grams servings
      final foodItemsResponse = await Supabase.instance.client
          .from('food_items')
          .select(
            'id, name, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, brand',
          )
          .ilike('name', '%$query%')
          .limit(10);

      for (final item in foodItemsResponse) {
        if (item['id'] != null &&
            item['name'] != null &&
            item['name'].toString().trim().isNotEmpty) {
          searchResults.add({
            'id': item['id'],
            'name': item['name'].toString().trim(),
            'type': 'food_item',
            'category': 'Alimento',
            'calories_per_100g': (item['calories_per_100g'] as int?) ?? 0,
            'protein': ((item['protein_per_100g'] as num?) ?? 0).toDouble(),
            'carbs': ((item['carbs_per_100g'] as num?) ?? 0).toDouble(),
            'fats': ((item['fat_per_100g'] as num?) ?? 0).toDouble(),
            'fiber': ((item['fiber_per_100g'] as num?) ?? 0).toDouble(),
            'brand': (item['brand'] as String?) ?? '',
            'servings': ['100g'], // Only allow grams
            'recent': false,
            'favorite': false,
          });
        }
      }

      // Search recipes with comprehensive null safety - only grams servings
      final recipesResponse =
          await RecipeService.instance.searchRecipesForMeals(query);

      for (final recipe in recipesResponse) {
        if (recipe['id'] != null &&
            recipe['title'] != null &&
            recipe['title'].toString().trim().isNotEmpty) {
          searchResults.add({
            'id': recipe['id'],
            'name': recipe['title'].toString().trim(),
            'type': 'recipe',
            'category': _translateCategory(
              (recipe['category'] as String?) ?? 'snack',
            ),
            'calories_per_100g': _calculateRecipeCaloriesPer100g(recipe),
            'protein': ((recipe['total_protein_g'] as num?) ?? 0).toDouble(),
            'carbs': ((recipe['total_carbs_g'] as num?) ?? 0).toDouble(),
            'fats': ((recipe['total_fat_g'] as num?) ?? 0).toDouble(),
            'fiber': ((recipe['total_fiber_g'] as num?) ?? 0).toDouble(),
            'servings': ['100g'], // Only allow grams for recipes too
            'servings_count': (recipe['servings'] as int?) ?? 1,
            'total_calories': (recipe['total_calories'] as int?) ?? 0,
            'recipe_ingredients': recipe['recipe_ingredients'],
            'recent': false,
            'favorite': false,
          });
        }
      }

      if (mounted) {
        setState(() {
          _filteredFoods = searchResults.take(8).toList();
          _showSuggestions = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _filteredFoods = [];
          _showSuggestions = _searchFocusNode.hasFocus;
          _errorMessage = 'Errore durante la ricerca degli alimenti';
        });
      }
      print('Error searching foods: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Errore durante la ricerca. Controlla la tua connessione.',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(4.w),
          ),
        );
      }
    }
  }

  void _addFood(Map<String, dynamic> food) {
    if (food['id'] == null ||
        food['name'] == null ||
        food['name'].toString().trim().isEmpty) {
      _showErrorToast('Dati dell\'alimento non disponibili');
      return;
    }

    final foodWithDefaults = Map<String, dynamic>.from(food);
    final servings = food["servings"] as List?;

    if (servings != null && servings.isNotEmpty) {
      foodWithDefaults["selected_serving"] = servings.first;
    } else {
      foodWithDefaults["selected_serving"] = "100g";
      foodWithDefaults["servings"] = ["100g"];
    }

    foodWithDefaults["quantity"] = 1.0;

    // Add debug logging
    print(
        'Adding food to meal: ${foodWithDefaults['name']} (ID: ${foodWithDefaults['id']}, Type: ${foodWithDefaults['type'] ?? 'food_item'})');

    try {
      widget.onFoodAdded(foodWithDefaults);
      _searchController.clear();

      if (mounted) {
        setState(() {
          _showSuggestions = false;
          _filteredFoods = [];
          _errorMessage = null;
        });
      }

      _searchFocusNode.unfocus();

      // Enhanced success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Aggiunto: ${food["name"]} (Quantità: ${foodWithDefaults["quantity"]}, Porzione: ${foodWithDefaults["selected_serving"]})',
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
          duration: Duration(seconds: 3), // Longer duration for more detail
          margin: EdgeInsets.all(4.w),
        ),
      );

      // Add verification log
      print(
          'Food successfully added to selectedFoods list. Current count: ${widget.selectedFoods.length}');
    } catch (e) {
      print('Error adding food: $e');
      _showErrorToast('Errore nell\'aggiunta dell\'alimento');
    }
  }

  void _showErrorToast(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(4.w),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aggiungi cibi',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          _buildSearchField(),
          // Only show suggestions when there's actual content to display
          if (_showSuggestions && _searchFocusNode.hasFocus)
            _buildSuggestionsList(),
          if (widget.selectedFoods.isNotEmpty) ...[
            SizedBox(height: 3.h),
            _buildSelectedFoodsList(),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _searchFoods,
        decoration: InputDecoration(
          hintText: 'Cerca cibi e ricette...',
          prefixIcon: Padding(
            padding: EdgeInsets.all(3.w),
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                  )
                : CustomIconWidget(
                    iconName: 'search',
                    color: AppTheme.lightTheme.colorScheme.outline,
                    size: 20,
                  ),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    if (mounted) {
                      setState(() {
                        _showSuggestions = _recentFoods.isNotEmpty;
                        _filteredFoods = [];
                        _errorMessage = null;
                      });
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'clear',
                      color: AppTheme.lightTheme.colorScheme.outline,
                      size: 20,
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 4.w,
            vertical: 1.5.h,
          ),
        ),
        style: AppTheme.lightTheme.textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildSuggestionsList() {
    final itemsToShow =
        _searchController.text.isNotEmpty ? _filteredFoods : _recentFoods;

    // Show loading state
    if (_isLoading) {
      return Container(
        margin: EdgeInsets.only(top: 1.h),
        padding: EdgeInsets.all(4.w),
        constraints: BoxConstraints(
          maxHeight: 30.h, // Reduced height to prevent overflow
        ),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.lightTheme.colorScheme.outline.withValues(
              alpha: 0.3,
            ),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Ricerca in corso...',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show error state if there's an error message
    if (_errorMessage != null) {
      return Container(
        margin: EdgeInsets.only(top: 1.h),
        padding: EdgeInsets.all(4.w),
        constraints: BoxConstraints(
          maxHeight: 30.h, // Reduced height to prevent overflow
        ),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: 'error_outline',
              color: AppTheme.lightTheme.colorScheme.error,
              size: 32,
            ),
            SizedBox(height: 2.h),
            Text(
              _errorMessage!,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onErrorContainer,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
                if (_searchController.text.isNotEmpty) {
                  _searchFoods(_searchController.text);
                } else {
                  _loadRecentFoods();
                }
              },
              icon: CustomIconWidget(
                iconName: 'refresh',
                color: Colors.white,
                size: 16,
              ),
              label: Text(
                'Riprova',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              ),
            ),
          ],
        ),
      );
    }

    // Show empty state when no items and user has typed something
    if (itemsToShow.isEmpty && _searchController.text.isNotEmpty) {
      return Container(
        margin: EdgeInsets.only(top: 1.h),
        padding: EdgeInsets.all(4.w),
        constraints: BoxConstraints(
          maxHeight: 25.h, // Reduced height to prevent overflow
        ),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.lightTheme.colorScheme.outline.withValues(
              alpha: 0.3,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: 'search_off',
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                alpha: 0.4,
              ),
              size: 32,
            ),
            SizedBox(height: 2.h),
            Text(
              'Nessun risultato trovato per "${_searchController.text}"',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                  alpha: 0.6,
                ),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                if (mounted) {
                  setState(() {
                    _showSuggestions = _recentFoods.isNotEmpty;
                    _filteredFoods = [];
                    _errorMessage = null;
                  });
                }
              },
              icon: CustomIconWidget(
                iconName: 'clear',
                color: Colors.white,
                size: 16,
              ),
              label: Text(
                'Cancella ricerca',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              ),
            ),
          ],
        ),
      );
    }

    // If no items to show and no search text, don't show suggestions
    if (itemsToShow.isEmpty) {
      return SizedBox.shrink();
    }

    // Show suggestions with proper content and improved height constraints
    return Container(
      margin: EdgeInsets.only(top: 1.h),
      constraints: BoxConstraints(
        maxHeight:
            35.h, // Optimized height to prevent overflow while showing content
        minHeight: 0, // Allow shrinking to content size
      ),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_searchController.text.isEmpty && _recentFoods.isNotEmpty)
            Container(
              padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primaryContainer
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'history',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Suggerimenti recenti',
                    style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: itemsToShow.length,
              padding: EdgeInsets.zero, // Remove default ListView padding
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: AppTheme.lightTheme.colorScheme.outline.withValues(
                  alpha: 0.2,
                ),
                indent: 4.w,
                endIndent: 4.w,
              ),
              itemBuilder: (context, index) {
                final food = itemsToShow[index];

                // Additional safety check to prevent rendering invalid items
                if (food["name"] == null ||
                    food["name"].toString().trim().isEmpty) {
                  return SizedBox.shrink();
                }

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _addFood(food),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 2.5
                            .h, // Increased vertical padding for better name display
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment
                            .start, // Align to top to handle multi-line text
                        children: [
                          Container(
                            width: 10.w,
                            height: 10.w,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(
                                (food["type"] as String?) ?? 'food_item',
                                (food["category"] as String?) ?? 'Alimento',
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: CustomIconWidget(
                                iconName: _getCategoryIcon(
                                  (food["type"] as String?) ?? 'food_item',
                                  (food["category"] as String?) ?? 'Alimento',
                                ),
                                color: _getCategoryColor(
                                  (food["type"] as String?) ?? 'food_item',
                                  (food["category"] as String?) ?? 'Alimento',
                                ),
                                size: 18,
                              ),
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Display full food name with better text handling
                                Text(
                                  food["name"].toString(),
                                  style: AppTheme
                                      .lightTheme.textTheme.bodyMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    height:
                                        1.3, // Better line height for readability
                                  ),
                                  maxLines: 2, // Allow 2 lines for longer names
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(
                                    height: 0.8
                                        .h), // Increased spacing for better readability
                                // Show additional info on separate line
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${(food["calories_per_100g"] as int?) ?? 0} cal/100g • ${(food["category"] as String?) ?? 'Alimento'}',
                                        style: AppTheme
                                            .lightTheme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: AppTheme
                                              .lightTheme.colorScheme.onSurface
                                              .withValues(alpha: 0.7),
                                          fontSize: 11
                                              .sp, // Slightly smaller to fit more info
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                // Show brand info for food items if available
                                if ((food["type"] as String?) != "recipe" &&
                                    (food["brand"] as String?)?.isNotEmpty ==
                                        true) ...[
                                  SizedBox(height: 0.3.h),
                                  Text(
                                    'Marca: ${food["brand"]}',
                                    style: AppTheme
                                        .lightTheme.textTheme.labelSmall
                                        ?.copyWith(
                                      color: AppTheme
                                          .lightTheme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Action buttons column
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if ((food["type"] as String?) == "recipe")
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 2.w,
                                        vertical: 0.5.h,
                                      ),
                                      margin: EdgeInsets.only(right: 1.w),
                                      decoration: BoxDecoration(
                                        color: AppTheme
                                            .lightTheme.colorScheme.secondary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'RICETTA',
                                        style: AppTheme
                                            .lightTheme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: AppTheme
                                              .lightTheme.colorScheme.secondary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 9.sp,
                                        ),
                                      ),
                                    ),
                                  if ((food["recent"] as bool?) == true)
                                    Padding(
                                      padding: EdgeInsets.only(right: 1.w),
                                      child: CustomIconWidget(
                                        iconName: 'history',
                                        color: AppTheme
                                            .lightTheme.colorScheme.primary,
                                        size: 14,
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 1.h),
                              Container(
                                padding: EdgeInsets.all(
                                    1.5.w), // Slightly larger touch area
                                decoration: BoxDecoration(
                                  color: AppTheme.lightTheme.colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: CustomIconWidget(
                                  iconName: 'add_circle_outline',
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                  size:
                                      18, // Slightly larger for better usability
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFoodsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cibi selezionati',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.selectedFoods.length,
          separatorBuilder: (context, index) => SizedBox(height: 2.h),
          itemBuilder: (context, index) {
            final food = widget.selectedFoods[index];
            return _buildSelectedFoodItem(food, index);
          },
        ),
      ],
    );
  }

  Widget _buildSelectedFoodItem(Map<String, dynamic> food, int index) {
    final quantity =
        (food["quantity"] as num?)?.toDouble() ?? 100.0; // Default to 100g
    final selectedServing = (food["selected_serving"] as String?) ?? "100g";
    final servings = (food["servings"] as List?) ?? ["100g"];

    // Ensure name is not null or empty for selected foods
    final foodName = (food["name"] as String?) ?? 'Alimento senza nome';
    if (foodName.trim().isEmpty) {
      food["name"] = 'Alimento senza nome';
    }

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align to top for better text layout
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show full food name with better text handling
                    Text(
                      foodName,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        height: 1.3, // Better line height for readability
                      ),
                      maxLines: 3, // Allow up to 3 lines for very long names
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((food["type"] as String?) == "recipe") ...[
                      SizedBox(height: 0.8.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.secondary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'RICETTA',
                          style: AppTheme.lightTheme.textTheme.labelSmall
                              ?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    // Show brand info for food items if available
                    if ((food["type"] as String?) != "recipe" &&
                        (food["brand"] as String?)?.isNotEmpty == true) ...[
                      SizedBox(height: 0.5.h),
                      Text(
                        'Marca: ${food["brand"]}',
                        style:
                            AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 2.w), // Add spacing between text and button
              GestureDetector(
                onTap: () => widget.onFoodRemoved(index),
                child: Container(
                  padding: EdgeInsets.all(1.5.w), // Slightly larger touch area
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.error.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: CustomIconWidget(
                    iconName: 'close',
                    color: AppTheme.lightTheme.colorScheme.error,
                    size: 18, // Slightly larger for better usability
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          // Only show quantity input - no more portion dropdown
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantità (grammi)',
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    _buildQuantityInput(food, index),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            '${_calculateCalories(food).toStringAsFixed(0)} calorie',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityInput(Map<String, dynamic> food, int index) {
    final quantity =
        (food["quantity"] as num?)?.toDouble() ?? 100.0; // Default to 100g
    final TextEditingController quantityController = TextEditingController(
      text: _formatQuantityDisplay(quantity),
    );

    return Column(
      children: [
        Container(
          height: 5.h,
          child: TextFormField(
            controller: quantityController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.error,
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 2.w,
                vertical: 1.h,
              ),
              suffixText: 'g',
              suffixStyle: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
            onChanged: (value) {
              _handleQuantityChange(value, index);
            },
            validator: (value) {
              return _validateQuantity(value);
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ),
        // Show validation error inline if any
        if (_getQuantityValidationError(quantityController.text) != null)
          Container(
            margin: EdgeInsets.only(top: 0.5.h),
            child: Text(
              _getQuantityValidationError(quantityController.text)!,
              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  String _formatQuantityDisplay(double quantity) {
    // Format to remove unnecessary decimal places
    if (quantity == quantity.toInt()) {
      return quantity.toInt().toString();
    } else {
      return quantity.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    }
  }

  String _extractUnit(String selectedServing) {
    // Extract unit from serving string
    if (selectedServing.contains('(') && selectedServing.contains('g)')) {
      return 'g';
    } else if (selectedServing.contains('(') &&
        selectedServing.contains('ml)')) {
      return 'ml';
    } else if (selectedServing.contains('porzione') ||
        selectedServing.contains('porzioni')) {
      return 'porz.';
    } else if (selectedServing.contains('tazza')) {
      return 'tazza';
    } else if (selectedServing.toLowerCase().contains('g')) {
      return 'g';
    } else if (selectedServing.toLowerCase().contains('ml')) {
      return 'ml';
    }
    return '';
  }

  void _handleQuantityChange(String value, int index) {
    // Remove any non-numeric characters except decimal point and comma
    String cleanValue =
        value.replaceAll(',', '.').replaceAll(RegExp(r'[^\d.]'), '');

    // Parse the value
    double? parsedValue = double.tryParse(cleanValue);

    if (parsedValue != null && parsedValue > 0 && parsedValue <= 10000) {
      // Valid quantity - update immediately for real-time calculation
      widget.onFoodUpdated(index, "quantity", parsedValue);
      // Also update selected_serving to always be 100g
      widget.onFoodUpdated(index, "selected_serving", "100g");
    } else if (cleanValue.isEmpty) {
      // Allow empty field without forcing a value - user might be typing
      // Don't update the model when field is empty, let user complete their input
      return;
    }
    // Invalid values are handled by validation - don't update the model
  }

  String? _validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Allow empty during editing
    }

    // Allow comma as decimal separator
    String cleanValue = value.replaceAll(',', '.');

    // Check for invalid characters
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(cleanValue)) {
      return 'Solo numeri';
    }

    double? parsedValue = double.tryParse(cleanValue);

    if (parsedValue == null) {
      return 'Numero non valido';
    }

    if (parsedValue <= 0) {
      return 'Deve essere > 0';
    }

    if (parsedValue > 10000) {
      return 'Massimo 10000g';
    }

    return null; // Valid
  }

  String? _getQuantityValidationError(String value) {
    return _validateQuantity(value);
  }

  double _calculateCalories(Map<String, dynamic> food) {
    final quantity =
        (food["quantity"] as num?)?.toDouble() ?? 100.0; // Default to 100g
    final foodType = (food["type"] as String?) ?? "food_item";

    try {
      if (foodType == "recipe") {
        // For recipes, use the calories_per_100g that was calculated
        final caloriesPer100g = (food["calories_per_100g"] as int?) ?? 0;
        // Fixed calculation: (grams inserted / 100g) × calories for 100g
        return (quantity / 100.0) * caloriesPer100g;
      } else {
        // For food items, use direct calories_per_100g
        final caloriesPer100g = (food["calories_per_100g"] as int?) ?? 0;
        // Fixed calculation: (grams inserted / 100g) × calories for 100g
        return (quantity / 100.0) * caloriesPer100g;
      }
    } catch (e) {
      print('Error calculating calories: $e');
      return 0.0;
    }
  }

  Color _getCategoryColor(String type, String category) {
    if (type == "recipe") {
      return AppTheme.lightTheme.colorScheme.secondary;
    }

    switch (category.toLowerCase()) {
      case 'alimento':
      case 'food item':
        return AppTheme.lightTheme.colorScheme.primary;
      case 'protein':
        return AppTheme.lightTheme.colorScheme.secondary;
      case 'carbohydrate':
      case 'grain':
        return AppTheme.lightTheme.colorScheme.primary;
      case 'vegetable':
        return const Color(0xFF27AE60);
      case 'dairy':
        return const Color(0xFF3498DB);
      case 'nuts':
        return const Color(0xFF8E44AD);
      default:
        return AppTheme.lightTheme.colorScheme.outline;
    }
  }

  String _getCategoryIcon(String type, String category) {
    if (type == "recipe") {
      return 'restaurant_menu';
    }

    switch (category.toLowerCase()) {
      case 'alimento':
      case 'food item':
        return 'local_dining';
      case 'protein':
        return 'restaurant';
      case 'carbohydrate':
      case 'grain':
        return 'grain';
      case 'vegetable':
        return 'eco';
      case 'dairy':
        return 'local_drink';
      case 'nuts':
        return 'nature';
      default:
        return 'fastfood';
    }
  }
}
