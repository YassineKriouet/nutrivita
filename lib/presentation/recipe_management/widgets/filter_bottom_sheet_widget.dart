import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FilterBottomSheetWidget extends StatefulWidget {
  final List<String> selectedFilters;
  final Function(List<String>) onFiltersChanged;

  const FilterBottomSheetWidget({
    Key? key,
    required this.selectedFilters,
    required this.onFiltersChanged,
  }) : super(key: key);

  @override
  State<FilterBottomSheetWidget> createState() =>
      _FilterBottomSheetWidgetState();
}

class _FilterBottomSheetWidgetState extends State<FilterBottomSheetWidget> {
  late List<String> _selectedFilters;

  final List<Map<String, dynamic>> _filterCategories = [
    {
      'title': 'Fonte Ricetta',
      'options': [
        'Le Mie Ricette',
        'Preferiti',
        'Biblioteca Pubblica',
        'Usate di Recente',
      ],
      'icon': 'folder',
    },
    {
      'title': 'Restrizioni Dietetiche',
      'options': [
        'Poco Sodio',
        'Ricche di Proteine',
        'Cibi Morbidi',
        'Anti-Nausea',
        'Senza Latticini',
        'Senza Glutine',
      ],
      'icon': 'health_and_safety',
    },
    {
      'title': 'Tipo Pasto',
      'options': [
        'Colazione',
        'Pranzo',
        'Cena',
        'Spuntino',
        'Frullato',
        'Integratore',
      ],
      'icon': 'restaurant',
    },
    {
      'title': 'Tempo di Preparazione',
      'options': ['Sotto i 15 min', '15-30 min', '30-60 min', 'Oltre 1 ora'],
      'icon': 'schedule',
    },
    {
      'title': 'Livello di Difficoltà',
      'options': ['Facile', 'Medio', 'Difficile'],
      'icon': 'star',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedFilters = List.from(widget.selectedFilters);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          Container(
            margin: EdgeInsets.only(top: 2.h),
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: AppTheme.neutralLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtra Ricette',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedFilters.clear();
                        });
                      },
                      child: Text(
                        'Cancella Tutto',
                        style: AppTheme.lightTheme.textTheme.labelLarge
                            ?.copyWith(color: AppTheme.neutralLight),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: CustomIconWidget(
                        iconName: 'close',
                        color: AppTheme.neutralLight,
                        size: 6.w,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Filter Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._filterCategories.map(
                    (category) => _buildFilterCategory(category),
                  ),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),
          // Apply Button
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppTheme.borderLight, width: 1),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onFiltersChanged(_selectedFilters);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 4.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Applica Filtri (${_selectedFilters.length})',
                    style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCategory(Map<String, dynamic> category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          child: Row(
            children: [
              CustomIconWidget(
                iconName: category['icon'],
                color: AppTheme.primaryLight,
                size: 5.w,
              ),
              SizedBox(width: 3.w),
              Text(
                category['title'],
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
        // Filter Options
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children:
              (category['options'] as List<String>).map((option) {
                final bool isSelected = _selectedFilters.contains(option);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedFilters.remove(option);
                      } else {
                        _selectedFilters.add(option);
                      }
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.w,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppTheme.primaryLight.withValues(alpha: 0.1)
                              : AppTheme.lightTheme.colorScheme.surface,
                      border: Border.all(
                        color:
                            isSelected
                                ? AppTheme.primaryLight
                                : AppTheme.borderLight,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          CustomIconWidget(
                            iconName: 'check',
                            color: AppTheme.primaryLight,
                            size: 4.w,
                          ),
                          SizedBox(width: 1.w),
                        ],
                        Text(
                          option,
                          style: AppTheme.lightTheme.textTheme.bodySmall
                              ?.copyWith(
                                color:
                                    isSelected
                                        ? AppTheme.primaryLight
                                        : AppTheme.textSecondaryLight,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
        SizedBox(height: 2.h),
      ],
    );
  }
}
