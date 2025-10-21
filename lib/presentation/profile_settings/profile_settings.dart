import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/user_settings_service.dart';
import './widgets/notification_settings_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/settings_section_widget.dart';

class ProfileSettings extends StatefulWidget {
  const ProfileSettings({Key? key}) : super(key: key);

  @override
  State<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  final ProfileService _profileService = ProfileService.instance;
  final AuthService _authService = AuthService.instance;
  final UserSettingsService _userSettingsService = UserSettingsService.instance;

  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _medicalProfile;
  Map<String, dynamic>? _userSettings;
  Map<String, dynamic>? _notificationPreferences;
  bool _isLoading = true;
  String? _error;

  int _selectedNavIndex = 4; // Profile is index 4

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Check if user is authenticated first
      if (!_authService.isAuthenticated) {
        setState(() {
          _error = 'Utente non autenticato';
          _isLoading = false;
        });
        return;
      }

      // Load profile and settings in parallel
      final results = await Future.wait([
        _profileService.getCompleteProfile(),
        _userSettingsService.getUserSettings(),
        _userSettingsService.getNotificationPreferences(),
      ]);

      if (!mounted) return;

      final completeProfile = results[0];
      final userSettings = results[1];
      final notificationPreferences = results[2];

      if (completeProfile != null) {
        setState(() {
          _userProfile = completeProfile;
          _medicalProfile =
              completeProfile['medical_profile'] as Map<String, dynamic>?;
          _userSettings = userSettings;
          _notificationPreferences = notificationPreferences;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Profilo non trovato';
          _isLoading = false;
        });
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Aggiornamento in corso...'),
                  ],
                ),
              )
              : _error != null
              ? _buildErrorWidget()
              : RefreshIndicator(
                onRefresh: _refreshProfile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      ProfileHeaderWidget(
                        patientName:
                            _getSafeString(_userProfile?['full_name']) ??
                            'Utente sconosciuto',
                        profileImageUrl:
                            _getSafeString(
                              _userProfile?['profile_image_url'],
                            ) ??
                            '',
                        accountStatus: 'Paziente attivo',
                        onEditProfile: () => _editPersonalInfo('full_name'),
                      ),
                      SizedBox(height: 2.h),
                      _buildSettingsSections(),
                      SizedBox(height: 4.h),
                      _buildSignOutButton(),
                      SizedBox(height: 10.h),
                    ],
                  ),
                ),
              ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // Helper method to safely extract strings from potentially null values
  String? _getSafeString(dynamic value) {
    if (value == null) return null;
    return value.toString().trim().isEmpty ? null : value.toString();
  }

  // Helper method to safely extract numbers
  double? _getSafeDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.lightTheme.colorScheme.error,
          ),
          SizedBox(height: 2.h),
          Text(
            'Errore nel caricamento del profilo',
            style: AppTheme.lightTheme.textTheme.titleLarge,
          ),
          SizedBox(height: 1.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              _error ?? 'Errore sconosciuto',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton(onPressed: _loadProfile, child: const Text('Riprova')),
        ],
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
    // Prevent navigation if currently loading
    if (_isLoading) return;

    // Don't change navigation if already on the target screen
    if (_selectedNavIndex == index) return;

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
        Navigator.pushNamed(context, AppRoutes.addMeal);
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.reports);
        break;
      case 4:
        // Already on Profile - stay on current screen
        break;
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Impostazioni profilo'),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: CustomIconWidget(
          iconName: 'arrow_back',
          color: AppTheme.lightTheme.primaryColor,
          size: 6.w,
        ),
      ),
      actions: [
        IconButton(
          onPressed: _showHelpDialog,
          icon: CustomIconWidget(
            iconName: 'help_outline',
            color: AppTheme.lightTheme.primaryColor,
            size: 6.w,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Existing sections
        SettingsSectionWidget(
          title: 'Informazioni personali',
          items: [
            SettingsItemData(
              title: 'Nome',
              subtitle:
                  _getSafeString(_userProfile?['full_name']) ?? 'Non impostato',
              iconName: 'person',
              iconColor: AppTheme.lightTheme.primaryColor,
              onTap: () => _editPersonalInfo('full_name'),
            ),
            SettingsItemData(
              title: 'Email',
              subtitle:
                  _getSafeString(_userProfile?['email']) ?? 'Non impostata',
              iconName: 'email',
              iconColor: AppTheme.lightTheme.primaryColor,
              onTap: () => _editPersonalInfo('email'),
            ),
            SettingsItemData(
              title: 'Numero di telefono',
              subtitle:
                  _getSafeString(_userProfile?['phone_number']) ??
                  'Non impostato',
              iconName: 'call',
              iconColor: AppTheme.lightTheme.primaryColor,
              onTap: () => _editPersonalInfo('phone_number'),
            ),
            SettingsItemData(
              title: 'Data di nascita',
              subtitle:
                  _userProfile?['date_of_birth'] != null
                      ? _formatDate(
                        DateTime.tryParse(
                          _userProfile!['date_of_birth'].toString(),
                        ),
                      )
                      : 'Non impostata',
              iconName: 'cake',
              iconColor: AppTheme.lightTheme.primaryColor,
              onTap: () => _editDateField('date_of_birth'),
            ),
            SettingsItemData(
              title: 'Genere alla nascita',
              subtitle: _getGenderDisplayName(
                _getSafeString(_userProfile?['gender']),
              ),
              iconName: 'person_outline',
              iconColor: AppTheme.lightTheme.primaryColor,
              onTap: () => _editGenderField(),
            ),
          ],
        ),
        SizedBox(height: 3.h),
        SettingsSectionWidget(
          title: 'Informazioni sulla salute',
          items: [
            SettingsItemData(
              title: 'Altezza',
              subtitle:
                  _getSafeDouble(_medicalProfile?['height_cm']) != null
                      ? '${_getSafeDouble(_medicalProfile!['height_cm'])} cm'
                      : 'Non impostata',
              iconName: 'straighten',
              iconColor: AppTheme.lightTheme.primaryColor,
              onTap: () => _editMedicalInfo('height_cm'),
            ),
            SettingsItemData(
              title: 'Peso attuale',
              subtitle:
                  _getSafeDouble(_medicalProfile?['current_weight_kg']) != null
                      ? '${_getSafeDouble(_medicalProfile!['current_weight_kg'])} kg'
                      : 'Non impostato',
              iconName: 'monitor_weight',
              iconColor: AppTheme.lightTheme.primaryColor,
              onTap: () => _editMedicalInfo('current_weight_kg'),
            ),
            SettingsItemData(
              title: 'Peso obiettivo',
              subtitle:
                  _getSafeDouble(_medicalProfile?['target_weight_kg']) != null
                      ? '${_getSafeDouble(_medicalProfile!['target_weight_kg'])} kg'
                      : 'Non impostato',
              iconName: 'flag',
              iconColor: AppTheme.lightTheme.primaryColor,
              onTap: () => _editMedicalInfo('target_weight_kg'),
            ),
            SettingsItemData(
              title: 'Livello di attività',
              subtitle: _getActivityLevelDisplayName(
                _getSafeString(_medicalProfile?['activity_level']),
              ),
              iconName: 'fitness_center',
              iconColor: AppTheme.lightTheme.primaryColor,
              onTap: () => _editActivityLevel(),
            ),
            SettingsItemData(
              title: 'Tipo di obiettivo',
              subtitle: _getGoalTypeDisplayName(
                _getSafeString(_medicalProfile?['goal_type']),
              ),
              iconName: 'track_changes',
              iconColor: AppTheme.lightTheme.primaryColor,
              onTap: () => _editGoalType(),
            ),
            SettingsItemData(
              title: 'In terapia presso un nutrizionista?',
              subtitle: _getNutritionalProfessionalDisplayName(
                _getSafeString(_medicalProfile?['nutritional_professional']),
              ),
              iconName: 'medical_services',
              iconColor: AppTheme.lightTheme.primaryColor,
              onTap: () => _editNutritionalProfessional(),
            ),
          ],
        ),
        SizedBox(height: 3.h),
        SettingsSectionWidget(
          title: 'Informazioni Cliniche',
          items: [
            SettingsItemData(
              title: 'Sede primaria del tumore',
              subtitle:
                  _getSafeString(_medicalProfile?['sede_primaria_tumore']) ??
                  'Non impostato',
              iconName: 'healing',
              iconColor: AppTheme.lightTheme.colorScheme.secondary,
              onTap: () => _editClinicalInfo('sede_primaria_tumore'),
            ),
            SettingsItemData(
              title: 'Data prima diagnosi',
              subtitle:
                  _medicalProfile?['data_prima_diagnosi'] != null
                      ? _formatDate(
                        DateTime.tryParse(
                          _medicalProfile!['data_prima_diagnosi'].toString(),
                        ),
                      )
                      : 'Non impostata',
              iconName: 'event',
              iconColor: AppTheme.lightTheme.colorScheme.secondary,
              onTap: () => _editClinicalDateField('data_prima_diagnosi'),
            ),
            SettingsItemData(
              title: 'Trattamento in corso',
              subtitle:
                  _getSafeString(_medicalProfile?['trattamento_in_corso']) ??
                  'Non impostato',
              iconName: 'medication',
              iconColor: AppTheme.lightTheme.colorScheme.secondary,
              onTap: () => _editClinicalInfo('trattamento_in_corso'),
            ),
            SettingsItemData(
              title: 'Patologie concomitanti',
              subtitle:
                  _getSafeString(_medicalProfile?['patologie_concomitanti']) ??
                  'Non impostate',
              iconName: 'local_hospital',
              iconColor: AppTheme.lightTheme.colorScheme.secondary,
              onTap: () => _editClinicalInfo('patologie_concomitanti'),
            ),
            SettingsItemData(
              title: 'Farmaci periodici',
              subtitle:
                  _getSafeString(_medicalProfile?['farmaci_periodici']) ??
                  'Non impostati',
              iconName: 'medication_liquid',
              iconColor: AppTheme.lightTheme.colorScheme.secondary,
              onTap: () => _editClinicalInfo('farmaci_periodici'),
            ),
          ],
        ),
        SizedBox(height: 3.h),
        SettingsSectionWidget(
          title: 'Preferenze app',
          items: [
            SettingsItemData(
              title: 'Modalità scura',
              subtitle: _getThemeModeDisplayName(_userSettings?['theme_mode']),
              iconName: 'dark_mode',
              iconColor: AppTheme.lightTheme.colorScheme.tertiary,
              onTap:
                  () => Navigator.pushNamed(
                    context,
                    AppRoutes.darkModeSettings,
                  ).then((_) => _loadProfile()),
            ),
            SettingsItemData(
              title: 'Frequenza sincronizzazione dati',
              subtitle: _getSyncFrequencyDisplayName(
                _userSettings?['sync_frequency'],
              ),
              iconName: 'sync',
              iconColor: AppTheme.lightTheme.colorScheme.tertiary,
              onTap:
                  () => Navigator.pushNamed(
                    context,
                    AppRoutes.dataSyncFrequencySettings,
                  ).then((_) => _loadProfile()),
            ),
          ],
        ),
        SizedBox(height: 3.h),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Text(
                'Impostazioni notifiche',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.lightTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const NotificationSettingsWidget(),
          ],
        ),
        SizedBox(height: 3.h),
        SettingsSectionWidget(
          title: 'Privacy e sicurezza',
          items: [
            SettingsItemData(
              title: 'Cambia password',
              subtitle: 'Aggiorna la password del tuo account',
              iconName: 'lock',
              iconColor: AppTheme.lightTheme.colorScheme.error,
              onTap: _changePassword,
            ),
            SettingsItemData(
              title: 'Elimina account',
              subtitle: 'Elimina permanentemente il tuo account',
              iconName: 'delete_forever',
              iconColor: AppTheme.lightTheme.colorScheme.error,
              onTap: _showDeleteAccountDialog,
            ),
          ],
        ),
        SizedBox(height: 2.h),
      ],
    );
  }

  // Helper method to get notification settings map
  Map<String, bool> _getNotificationSettingsMap() {
    return {
      'meal_reminders': _notificationPreferences?['meal_reminders'] ?? true,
      'medication_alerts':
          _notificationPreferences?['medication_alerts'] ?? true,
      'progress_celebrations':
          _notificationPreferences?['progress_celebrations'] ?? true,
      'healthcare_provider_messages':
          _notificationPreferences?['healthcare_provider_messages'] ?? true,
      'weekly_reports': _notificationPreferences?['weekly_reports'] ?? true,
    };
  }

  // Helper method to get theme mode display name
  String _getThemeModeDisplayName(String? themeMode) {
    // Always show as light mode since dark mode is coming soon
    return 'Modalità chiara (Scura in arrivo)';
  }

  // Helper method to get sync frequency display name
  String _getSyncFrequencyDisplayName(String? frequency) {
    switch (frequency) {
      case 'realtime':
        return 'Tempo reale';
      case 'hourly':
        return 'Ogni ora';
      case 'daily':
        return 'Giornaliera';
      case 'weekly':
        return 'Settimanale';
      default:
        return 'Tempo reale';
    }
  }

  Widget _buildSignOutButton() {
    return ElevatedButton(
      onPressed: () => _showSignOutDialog(),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 4.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        'Disconnetti',
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Non impostata';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _editPersonalInfo(String field) {
    String? currentValue = _getSafeString(_userProfile?[field]);

    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: currentValue);

        return AlertDialog(
          title: Text('Modifica ${_getFieldDisplayName(field)}'),
          content: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: _getFieldDisplayName(field),
              border: const OutlineInputBorder(),
              helperText: field == 'phone_number' ? 'Solo numeri' : null,
            ),
            keyboardType:
                field == 'email'
                    ? TextInputType.emailAddress
                    : field == 'phone_number'
                    ? TextInputType.number
                    : TextInputType.text,
            inputFormatters:
                field == 'phone_number'
                    ? [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(15),
                    ]
                    : field == 'email'
                    ? [FilteringTextInputFormatter.deny(RegExp(r'\s'))]
                    : null,
            validator:
                field == 'phone_number'
                    ? (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!RegExp(r'^\d+$').hasMatch(value)) {
                          return 'Inserire solo numeri';
                        }
                        if (value.length < 8) {
                          return 'Numero troppo corto';
                        }
                      }
                      return null;
                    }
                    : null,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed:
                  () => _savePersonalInfo(field, controller.text, context),
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  void _editMedicalInfo(String field) {
    String? currentValue = _medicalProfile?[field]?.toString();

    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: currentValue);

        return AlertDialog(
          title: Text('Modifica ${_getFieldDisplayName(field)}'),
          content: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: _getFieldDisplayName(field),
              border: const OutlineInputBorder(),
              suffixText:
                  field.contains('weight')
                      ? 'kg'
                      : field.contains('height')
                      ? 'cm'
                      : null,
            ),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed:
                  () => _saveMedicalInfo(field, controller.text, context),
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  void _editDateField(String field) {
    DateTime? currentDate;
    if (_userProfile?[field] != null) {
      currentDate = DateTime.tryParse(_userProfile![field].toString());
    }

    showDatePicker(
      context: context,
      initialDate:
          currentDate ??
          DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    ).then((selectedDate) {
      if (selectedDate != null) {
        _savePersonalInfo(
          field,
          selectedDate.toIso8601String().split('T')[0],
          context,
        );
      }
    });
  }

  void _editGenderField() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Seleziona genere alla nascita'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  ['male', 'female', 'other', 'prefer_not_to_say']
                      .map(
                        (gender) => RadioListTile<String>(
                          title: Text(_getGenderDisplayName(gender)),
                          value: gender,
                          groupValue: _getSafeString(_userProfile?['gender']),
                          onChanged: (value) {
                            if (value != null) {
                              _savePersonalInfo('gender', value, context);
                            }
                          },
                        ),
                      )
                      .toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annulla'),
              ),
            ],
          ),
    );
  }

  void _editActivityLevel() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Seleziona livello di attività'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  [
                        'sedentary',
                        'lightly_active',
                        'moderately_active',
                        'very_active',
                        'extremely_active',
                      ]
                      .map(
                        (level) => RadioListTile<String>(
                          title: Text(_getActivityLevelDisplayName(level)),
                          value: level,
                          groupValue: _getSafeString(
                            _medicalProfile?['activity_level'],
                          ),
                          onChanged: (value) {
                            if (value != null) {
                              _saveMedicalInfo(
                                'activity_level',
                                value,
                                context,
                              );
                            }
                          },
                        ),
                      )
                      .toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annulla'),
              ),
            ],
          ),
    );
  }

  void _editGoalType() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Seleziona tipo di obiettivo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  [
                        'weight_loss',
                        'weight_gain',
                        'maintain_weight',
                        'muscle_gain',
                        'general_health',
                      ]
                      .map(
                        (goal) => RadioListTile<String>(
                          title: Text(_getGoalTypeDisplayName(goal)),
                          value: goal,
                          groupValue: _getSafeString(
                            _medicalProfile?['goal_type'],
                          ),
                          onChanged: (value) {
                            if (value != null) {
                              _saveMedicalInfo('goal_type', value, context);
                            }
                          },
                        ),
                      )
                      .toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annulla'),
              ),
            ],
          ),
    );
  }

  void _editNutritionalProfessional() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('In terapia presso un nutrizionista?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  [
                        null, // None option
                        'nutrizionista_clinico',
                        'biologo_nutrizionista',
                        'dietista',
                      ]
                      .map(
                        (professional) => RadioListTile<String?>(
                          title: Text(
                            _getNutritionalProfessionalDisplayName(
                              professional,
                            ),
                          ),
                          value: professional,
                          groupValue: _getSafeString(
                            _medicalProfile?['nutritional_professional'],
                          ),
                          onChanged: (value) {
                            _saveMedicalInfo(
                              'nutritional_professional',
                              value ?? '',
                              context,
                            );
                          },
                        ),
                      )
                      .toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annulla'),
              ),
            ],
          ),
    );
  }

  void _editClinicalInfo(String field) {
    String? currentValue = _getSafeString(_medicalProfile?[field]);

    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: currentValue);

        return AlertDialog(
          title: Text('Modifica ${_getClinicalFieldDisplayName(field)}'),
          content: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: _getClinicalFieldDisplayName(field),
              border: const OutlineInputBorder(),
              helperText: _getClinicalFieldHelper(field),
            ),
            keyboardType: TextInputType.multiline,
            maxLines:
                field.contains('farmaci') || field.contains('patologie')
                    ? 3
                    : 1,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _saveClinicalInfo(field, controller.text);
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  void _editClinicalDateField(String field) {
    DateTime? currentDate;
    if (_medicalProfile?[field] != null) {
      currentDate = DateTime.tryParse(_medicalProfile![field].toString());
    }

    showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    ).then((selectedDate) {
      if (selectedDate != null) {
        _saveClinicalInfo(field, selectedDate.toIso8601String().split('T')[0]);
      }
    });
  }

  Future<void> _saveClinicalInfo(String field, String value) async {
    if (!mounted) return;

    try {
      // Show loading indicator without dialog
      setState(() {
        _isLoading = true;
      });

      await _profileService.updateMedicalProfile({field: value});

      // Reload profile data
      await _reloadProfileData();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_getClinicalFieldDisplayName(field)} aggiornato con successo',
            ),
            backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Aggiornamento fallito: ${error.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Add new method to reload profile data without triggering loading state
  Future<void> _reloadProfileData() async {
    if (!mounted || !_authService.isAuthenticated) return;

    try {
      // Load profile and settings in parallel
      final results = await Future.wait([
        _profileService.getCompleteProfile(),
        _userSettingsService.getUserSettings(),
        _userSettingsService.getNotificationPreferences(),
      ]);

      if (!mounted) return;

      final completeProfile = results[0];
      final userSettings = results[1];
      final notificationPreferences = results[2];

      if (completeProfile != null) {
        setState(() {
          _userProfile = completeProfile;
          _medicalProfile =
              completeProfile['medical_profile'] as Map<String, dynamic>?;
          _userSettings = userSettings;
          _notificationPreferences = notificationPreferences;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  String _getClinicalFieldDisplayName(String field) {
    switch (field) {
      case 'sede_primaria_tumore':
        return 'Sede primaria del tumore';
      case 'data_prima_diagnosi':
        return 'Data prima diagnosi';
      case 'trattamento_in_corso':
        return 'Trattamento in corso';
      case 'patologie_concomitanti':
        return 'Patologie concomitanti';
      case 'farmaci_periodici':
        return 'Farmaci periodici';
      default:
        return field.replaceAll('_', ' ').toUpperCase();
    }
  }

  String? _getClinicalFieldHelper(String field) {
    switch (field) {
      case 'sede_primaria_tumore':
        return 'Specificare la sede anatomica del tumore primario';
      case 'trattamento_in_corso':
        return 'Descrivere i trattamenti attuali (chemio, radio, ecc.)';
      case 'patologie_concomitanti':
        return 'Elencare altre patologie presenti';
      case 'farmaci_periodici':
        return 'Elencare farmaci assunti regolarmente';
      default:
        return null;
    }
  }

  String _getNutritionalProfessionalDisplayName(String? professional) {
    if (professional == null || professional.isEmpty)
      return 'Non sono in terapia attualmente';
    switch (professional) {
      case 'nutrizionista_clinico':
        return 'Nutrizionista clinico';
      case 'biologo_nutrizionista':
        return 'Biologo nutrizionista';
      case 'dietista':
        return 'Dietista';
      default:
        return 'Non sono in terapia attualmente';
    }
  }

  Future<void> _savePersonalInfo(
    String field,
    String value,
    BuildContext dialogContext,
  ) async {
    try {
      // Additional validation for phone number
      if (field == 'phone_number' && value.isNotEmpty) {
        if (!RegExp(r'^\d+$').hasMatch(value)) {
          throw Exception('Il numero di telefono deve contenere solo numeri');
        }
        if (value.length < 8) {
          throw Exception(
            'Il numero di telefono deve contenere almeno 8 cifre',
          );
        }
      }

      Navigator.pop(dialogContext);

      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      await _profileService.updateUserProfile({field: value});
      await _reloadProfileData();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_getFieldDisplayName(field)} aggiornato con successo',
            ),
            backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Aggiornamento fallito: ${error.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _saveMedicalInfo(
    String field,
    String value,
    BuildContext dialogContext,
  ) async {
    try {
      Navigator.pop(dialogContext);

      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      dynamic processedValue = value;
      if (field.contains('weight') || field.contains('height')) {
        processedValue = double.tryParse(value);
        if (processedValue == null) {
          throw Exception('Formato numero non valido');
        }
      }

      await _profileService.updateMedicalProfile({field: processedValue});
      await _reloadProfileData();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_getFieldDisplayName(field)} aggiornato con successo',
            ),
            backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Aggiornamento fallito: ${error.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showLoadingDialog() {
    // Removed - using setState loading instead
  }

  String _getFieldDisplayName(String field) {
    switch (field) {
      case 'full_name':
        return 'Nome completo';
      case 'phone_number':
        return 'Numero di telefono';
      case 'date_of_birth':
        return 'Data di nascita';
      case 'height_cm':
        return 'Altezza';
      case 'current_weight_kg':
        return 'Peso attuale';
      case 'target_weight_kg':
        return 'Peso obiettivo';
      case 'activity_level':
        return 'Livello di attività';
      case 'goal_type':
        return 'Tipo di obiettivo';
      case 'nutritional_professional':
        return 'Professionista nutrizionale';
      default:
        return field.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _getGenderDisplayName(String? gender) {
    if (gender == null) return 'Non impostato';
    switch (gender) {
      case 'male':
        return 'Maschio';
      case 'female':
        return 'Femmina';
      case 'other':
        return 'Altro';
      case 'prefer_not_to_say':
        return 'Preferisco non specificare';
      default:
        return 'Non impostato';
    }
  }

  String _getActivityLevelDisplayName(String? level) {
    if (level == null) return 'Non impostato';
    switch (level) {
      case 'sedentary':
        return 'Sedentario';
      case 'lightly_active':
        return 'Leggermente attivo';
      case 'moderately_active':
        return 'Moderatamente attivo';
      case 'very_active':
        return 'Molto attivo';
      case 'extremely_active':
        return 'Estremamente attivo';
      default:
        return 'Non impostato';
    }
  }

  String _getGoalTypeDisplayName(String? goal) {
    if (goal == null) return 'Non impostato';
    switch (goal) {
      case 'weight_loss':
        return 'Perdita di peso';
      case 'weight_gain':
        return 'Aumento di peso';
      case 'maintain_weight':
        return 'Mantenimento peso';
      case 'muscle_gain':
        return 'Aumento massa muscolare';
      case 'general_health':
        return 'Salute generale';
      default:
        return 'Non impostato';
    }
  }

  Future<void> _refreshProfile() async {
    await _loadProfile();
  }

  void _updateNotificationSetting(String key, bool value) async {
    try {
      await _userSettingsService.updateNotificationPreferences({key: value});

      // Update local state
      if (_notificationPreferences != null) {
        setState(() {
          _notificationPreferences![key] = value;
        });
      }

      final keyDisplayName = _getNotificationKeyDisplayName(key);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$keyDisplayName ${value ? 'attivato' : 'disattivato'}',
          ),
          backgroundColor: AppTheme.lightTheme.primaryColor,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nell\'aggiornamento: $error'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
        ),
      );
    }
  }

  String _getNotificationKeyDisplayName(String key) {
    switch (key) {
      case 'meal_reminders':
        return 'Promemoria pasti';
      case 'medication_alerts':
        return 'Avvisi farmaci';
      case 'progress_celebrations':
        return 'Celebrazioni progressi';
      case 'healthcare_provider_messages':
        return 'Messaggi operatori sanitari';
      case 'weekly_reports':
        return 'Report settimanali';
      default:
        return key.replaceAll('_', ' ');
    }
  }

  void _showSyncOptions() {
    // Navigate to the dedicated data sync frequency settings screen
    Navigator.pushNamed(
      context,
      AppRoutes.dataSyncFrequencySettings,
    ).then((_) => _loadProfile());
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cambia password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password attuale',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 2.h),
                TextFormField(
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nuova password',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 2.h),
                TextFormField(
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Conferma nuova password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Funzione cambio password disponibile presto',
                      ),
                      backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
                    ),
                  );
                },
                child: const Text('Cambia password'),
              ),
            ],
          ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Elimina account'),
            content: const Text(
              'Sei sicuro di voler eliminare il tuo account? Questa azione non può essere annullata.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Richiesta eliminazione account inviata',
                      ),
                      backgroundColor: AppTheme.lightTheme.colorScheme.error,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.colorScheme.error,
                ),
                child: const Text('Elimina account'),
              ),
            ],
          ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Disconnetti'),
            content: const Text(
              'Sei sicuro di voler disconnettere il tuo account?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await _authService.signOut();
                    if (mounted) {
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.loginScreen,
                      );
                    }
                  } catch (error) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Disconnessione fallita: ${error.toString()}',
                          ),
                          backgroundColor:
                              AppTheme.lightTheme.colorScheme.error,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Disconnetti'),
              ),
            ],
          ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Aiuto e supporto'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hai bisogno di aiuto con le impostazioni del profilo?',
                ),
                SizedBox(height: 2.h),
                const Text(
                  '• Contatta il tuo medico per modifiche alle informazioni di trattamento',
                ),
                const Text(
                  '• Invia email a support@nutrivita.com per problemi tecnici',
                ),
                const Text('• Chiama 1-800-NUTRI-VITA per supporto urgente'),
                SizedBox(height: 2.h),
                const Text(
                  'Tempo di risposta: 24-48 ore per questioni non urgenti',
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Ho capito'),
              ),
            ],
          ),
    );
  }

  // New method to build a customized settings section with the requested items
  Widget _buildSettingsSection(ThemeData currentTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Impostazioni',
          style: currentTheme.textTheme.titleMedium?.copyWith(
            color: currentTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Container(
          decoration: BoxDecoration(
            color: currentTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: currentTheme.shadowColor.withAlpha(13),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSettingsItem(
                'Modalità Scura',
                'Personalizza l\'aspetto dell\'app',
                'dark_mode',
                () => Navigator.pushNamed(context, AppRoutes.darkModeSettings),
                currentTheme,
              ),
              Divider(
                height: 0,
                color: currentTheme.colorScheme.outline.withAlpha(51),
              ),
              _buildSettingsItem(
                'Accessibilità',
                'Impostazioni per migliorare l\'usabilità',
                'accessibility',
                () => Navigator.pushNamed(
                  context,
                  AppRoutes.accessibilitySettings,
                ),
                currentTheme,
              ),
              Divider(
                height: 0,
                color: currentTheme.colorScheme.outline.withAlpha(51),
              ),
              _buildSettingsItem(
                'Frequenza Sincronizzazione',
                'Gestisci la sincronizzazione dei dati',
                'sync',
                () => Navigator.pushNamed(
                  context,
                  AppRoutes.dataSyncFrequencySettings,
                ),
                currentTheme,
              ),
              Divider(
                height: 0,
                color: currentTheme.colorScheme.outline.withAlpha(51),
              ),
              _buildSettingsItem(
                'Autenticazione Biometrica',
                'Sicurezza e accesso rapido',
                'fingerprint',
                () => Navigator.pushNamed(
                  context,
                  AppRoutes.biometricAuthenticationSettings,
                ),
                currentTheme,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper widget to create individual settings item
  Widget _buildSettingsItem(
    String title,
    String subtitle,
    String iconName,
    VoidCallback onTap,
    ThemeData themeData,
  ) {
    return ListTile(
      title: Text(title, style: themeData.textTheme.bodyMedium),
      subtitle: Text(subtitle, style: themeData.textTheme.bodySmall),
      leading: CustomIconWidget(
        iconName: iconName,
        size: 5.w,
        color: themeData.primaryColor,
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 3.w),
      onTap: onTap,
    );
  }
}
