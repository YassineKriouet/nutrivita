import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import '../../../core/app_export.dart';
import '../../../services/body_metrics_service.dart';

class BodyCardWidget extends StatefulWidget {
  const BodyCardWidget({Key? key}) : super(key: key);

  @override
  State<BodyCardWidget> createState() => _BodyCardWidgetState();
}

class _BodyCardWidgetState extends State<BodyCardWidget> {
  final BodyMetricsService _bodyMetricsService = BodyMetricsService.instance;

  // Data state
  Map<String, dynamic>? _bodyMetrics;
  bool _isLoading = true;
  String? _error;

  // Real-time subscription
  late RealtimeChannel? _weightEntriesChannel;
  late RealtimeChannel? _medicalProfilesChannel;

  @override
  void initState() {
    super.initState();
    _loadBodyMetrics();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _weightEntriesChannel?.unsubscribe();
    _medicalProfilesChannel?.unsubscribe();
    super.dispose();
  }

  // Setup proper real-time subscriptions for weight entries
  void _setupRealtimeSubscription() {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Subscribe to weight_entries changes for current user
      _weightEntriesChannel = Supabase.instance.client
          .channel('body_card_weight_changes')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'weight_entries',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              if (mounted) {
                print(
                    'Weight entries changed in body card, refreshing data...');
                _loadBodyMetrics();
              }
            },
          )
          .subscribe();

      // Subscribe to medical_profiles changes for current user
      _medicalProfilesChannel = Supabase.instance.client
          .channel('body_card_medical_changes')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'medical_profiles',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              if (mounted) {
                print(
                    'Medical profile changed in body card, refreshing data...');
                _loadBodyMetrics();
              }
            },
          )
          .subscribe();
    } catch (e) {
      print('Failed to setup real-time subscription in body card: $e');
    }
  }

  Future<void> _loadBodyMetrics() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final summary = await _bodyMetricsService.getBodyMetricsSummary();

      if (mounted) {
        setState(() {
          _bodyMetrics = summary;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.bodyMetrics);
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(5.w),
        margin: EdgeInsets.only(bottom: 3.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Metriche corporee',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontSize: 20.sp,
                    color: AppTheme.lightTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                CustomIconWidget(
                  iconName: 'monitor_weight',
                  size: 32,
                  color: AppTheme.lightTheme.primaryColor,
                ),
              ],
            ),
            SizedBox(height: 2.5.h),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null || _bodyMetrics == null) {
      return _buildErrorState();
    }

    return _buildDataState();
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Caricamento metriche corporee...',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        CustomIconWidget(
          iconName: 'error_outline',
          size: 48,
          color: AppTheme.lightTheme.colorScheme.error,
        ),
        SizedBox(height: 1.h),
        Text(
          'Errore nel caricamento',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          'Tocca per riprovare',
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDataState() {
    final medicalProfile =
        _bodyMetrics?['medical_profile'] as Map<String, dynamic>?;
    final latestWeight =
        _bodyMetrics?['latest_weight'] as Map<String, dynamic>?;

    // Extract values
    final weight = latestWeight?['weight_kg']?.toDouble() ??
        medicalProfile?['current_weight_kg']?.toDouble();
    final height = medicalProfile?['height_cm']?.toDouble();
    final lastUpdated =
        latestWeight?['recorded_at'] ?? latestWeight?['created_at'];

    // Calculate BMI if we have both weight and height
    double? bmi;
    if (weight != null && height != null && height > 0) {
      bmi =
          _bodyMetricsService.calculateBMI(weightKg: weight, heightCm: height);
    }

    // Format last updated date
    String lastUpdateText = 'Ultimo aggiornamento: ';
    if (lastUpdated != null) {
      try {
        final DateTime updateDate = DateTime.parse(lastUpdated.toString());
        final DateTime now = DateTime.now();
        final difference = now.difference(updateDate);

        if (difference.inDays == 0) {
          lastUpdateText += 'Oggi';
        } else if (difference.inDays == 1) {
          lastUpdateText += 'Ieri';
        } else if (difference.inDays < 7) {
          lastUpdateText += '${difference.inDays} giorni fa';
        } else {
          lastUpdateText +=
              '${updateDate.day}/${updateDate.month}/${updateDate.year}';
        }
      } catch (e) {
        lastUpdateText += 'Data non disponibile';
      }
    } else {
      lastUpdateText += 'Non disponibile';
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetricItem(
              'Peso',
              weight != null ? '${weight.toStringAsFixed(1)} kg' : 'N/A',
              'monitor_weight',
            ),
            _buildMetricItem(
              'Altezza',
              height != null ? '${height.toStringAsFixed(0)} cm' : 'N/A',
              'height',
            ),
            _buildMetricItem(
              'BMI',
              bmi != null ? bmi.toStringAsFixed(1) : 'N/A',
              'fitness_center',
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Divider(
          color: AppTheme.lightTheme.colorScheme.outline.withAlpha(51),
          thickness: 1,
        ),
        SizedBox(height: 1.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                lastUpdateText,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Row(
              children: [
                Text(
                  'Tocca per gestire',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 1.w),
                CustomIconWidget(
                  iconName: 'arrow_forward',
                  size: 16,
                  color: AppTheme.lightTheme.primaryColor,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricItem(String label, String value, String iconName) {
    return Column(
      children: [
        CustomIconWidget(
          iconName: iconName,
          size: 32,
          color: AppTheme.lightTheme.primaryColor,
        ),
        SizedBox(height: 1.h),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontSize: 18.sp,
            color: AppTheme.lightTheme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            fontSize: 12.sp,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}