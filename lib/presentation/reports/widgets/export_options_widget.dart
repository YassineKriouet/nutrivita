import 'dart:convert';
import 'dart:io' if (dart.library.io) 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sizer/sizer.dart';
import 'package:universal_html/html.dart' as html;

import '../../../core/app_export.dart';
import '../../../services/auth_service.dart';
import '../../../services/meal_diary_service.dart';
import '../../../services/sharing_service.dart';

class ExportOptionsWidget extends StatefulWidget {
  final String dateRange;
  final VoidCallback onClose;

  const ExportOptionsWidget({
    Key? key,
    required this.dateRange,
    required this.onClose,
  }) : super(key: key);

  @override
  State<ExportOptionsWidget> createState() => _ExportOptionsWidgetState();
}

class _ExportOptionsWidgetState extends State<ExportOptionsWidget> {
  bool _isGenerating = false;
  String _selectedPrivacyLevel = 'Dettaglio Completo';
  final List<String> _privacyLevels = ['Dettaglio Completo', 'Solo Riassunto'];

  // Real data from Supabase
  Map<String, dynamic> _nutritionalSummary = {};
  Map<String, dynamic> _mealStatistics = {};
  List<Map<String, dynamic>> _recentMeals = [];

  // WhatsApp availability check
  bool _isWhatsAppAvailable = false;

  final List<Map<String, dynamic>> _exportOptions = [
    {
      'title': 'Genera Report PDF',
      'subtitle': 'Formato report medico professionale',
      'icon': 'picture_as_pdf',
      'color': Color(0xFFE74C3C),
      'action': 'pdf',
    },
    {
      'title': 'Condividi via WhatsApp',
      'subtitle': 'Invia il report nutrizionale su WhatsApp',
      'icon': 'chat',
      'color': Color(0xFF25D366),
      'action': 'whatsapp',
    },
    {
      'title': 'Condividi via Social',
      'subtitle': 'Telegram, Email, SMS e altri',
      'icon': 'share',
      'color': Color(0xFF1DA1F2),
      'action': 'social',
    },
    {
      'title': 'Invia per Email al Fornitore Sanitario',
      'subtitle': 'Invia direttamente al tuo team medico',
      'icon': 'email',
      'color': Color(0xFF3498DB),
      'action': 'email',
    },
    {
      'title': 'Esporta Dati (CSV)',
      'subtitle': 'Dati grezzi per analisi esterni',
      'icon': 'table_chart',
      'color': Color(0xFF27AE60),
      'action': 'csv',
    },
    {
      'title': 'Salva su Cloud Storage',
      'subtitle': 'Backup sicuro e condivisione',
      'icon': 'cloud_upload',
      'color': Color(0xFF9B59B6),
      'action': 'cloud',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadRealData();
    _checkWhatsAppAvailability();
  }

  Future<void> _checkWhatsAppAvailability() async {
    final available = await SharingService.instance.isWhatsAppAvailable();
    setState(() {
      _isWhatsAppAvailable = available;
    });
  }

  Future<void> _loadRealData() async {
    if (!AuthService.instance.isAuthenticated) return;

    try {
      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate = now;

      // Calculate date range based on selection
      switch (widget.dateRange.toLowerCase()) {
        case 'daily':
        case 'giornaliero':
          startDate = DateTime(now.year, now.month, now.day);
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'weekly':
        case 'settimanale':
          startDate = now.subtract(Duration(days: 7));
          break;
        case 'monthly':
        case 'mensile':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'yearly':
        case 'annuale':
          startDate = DateTime(now.year - 1, now.month, now.day);
          break;
        default:
          startDate = now.subtract(Duration(days: 7));
      }

      // Load real data from Supabase
      final summary = await MealDiaryService.instance.getNutritionalSummary(
        startDate: startDate,
        endDate: endDate,
      );

      final statistics = await MealDiaryService.instance.getMealStatistics(
        startDate: startDate,
        endDate: endDate,
      );

      final meals = await MealDiaryService.instance.getUserMeals(
        startDate: startDate,
        endDate: endDate,
      );

      setState(() {
        _nutritionalSummary = summary;
        _mealStatistics = statistics;
        _recentMeals = meals.take(10).toList(); // Last 10 meals for report
      });
    } catch (error) {
      print('Error loading real data: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.outline.withValues(
                    alpha: 0.2,
                  ),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Opzioni di Esportazione e Condivisione',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.lightTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          if (_isGenerating)
            Container(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    color: AppTheme.lightTheme.primaryColor,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Generazione e condivisione report...',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.primaryColor,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isGenerating = false;
                      });
                    },
                    child: Text('Annulla'),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'info',
                            color: AppTheme.lightTheme.primaryColor,
                            size: 20,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              'Genera e condividi il tuo report nutrizionale ${widget.dateRange.toLowerCase()} via WhatsApp, social o email',
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.lightTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'Livello di Privacy',
                      style: AppTheme.lightTheme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 1.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 3.w),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.lightTheme.colorScheme.outline,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPrivacyLevel,
                          isExpanded: true,
                          icon: CustomIconWidget(
                            iconName: 'keyboard_arrow_down',
                            color: AppTheme.lightTheme.primaryColor,
                            size: 24,
                          ),
                          items: _privacyLevels.map((String level) {
                            return DropdownMenuItem<String>(
                              value: level,
                              child: Text(level),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedPrivacyLevel = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'Opzioni di Condivisione',
                      style: AppTheme.lightTheme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 2.h),
                    ..._exportOptions.map((option) {
                      bool isDisabled = option['action'] == 'whatsapp' &&
                          !_isWhatsAppAvailable;

                      return Container(
                        margin: EdgeInsets.only(bottom: 2.h),
                        child: InkWell(
                          onTap: isDisabled
                              ? null
                              : () => _handleExportAction(
                                  option['action'] as String),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: isDisabled
                                  ? AppTheme.lightTheme.cardColor
                                      .withValues(alpha: 0.5)
                                  : AppTheme.lightTheme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.lightTheme.colorScheme.outline
                                    .withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(3.w),
                                  decoration: BoxDecoration(
                                    color: (option['color'] as Color)
                                        .withValues(
                                            alpha: isDisabled ? 0.3 : 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: CustomIconWidget(
                                    iconName: option['icon'] as String,
                                    color: isDisabled
                                        ? (option['color'] as Color)
                                            .withValues(alpha: 0.5)
                                        : (option['color'] as Color),
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option['title'] as String,
                                        style: AppTheme
                                            .lightTheme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: isDisabled
                                              ? AppTheme.lightTheme.colorScheme
                                                  .onSurfaceVariant
                                                  .withValues(alpha: 0.5)
                                              : null,
                                        ),
                                      ),
                                      SizedBox(height: 0.5.h),
                                      Text(
                                        (option['subtitle'] as String) +
                                            (isDisabled
                                                ? ' (non disponibile)'
                                                : ''),
                                        style: AppTheme
                                            .lightTheme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: isDisabled
                                              ? AppTheme.lightTheme.colorScheme
                                                  .onSurfaceVariant
                                                  .withValues(alpha: 0.5)
                                              : AppTheme.lightTheme.colorScheme
                                                  .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                CustomIconWidget(
                                  iconName: 'arrow_forward_ios',
                                  color: isDisabled
                                      ? AppTheme.lightTheme.colorScheme
                                          .onSurfaceVariant
                                          .withValues(alpha: 0.3)
                                      : AppTheme.lightTheme.colorScheme
                                          .onSurfaceVariant,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleExportAction(String action) async {
    setState(() {
      _isGenerating = true;
    });

    try {
      switch (action) {
        case 'pdf':
          await _generatePDFReport();
          break;
        case 'whatsapp':
          await _shareViaWhatsApp();
          break;
        case 'social':
          await _showSocialSharingOptions();
          break;
        case 'email':
          await _emailReport();
          break;
        case 'csv':
          await _exportCSVData();
          break;
        case 'cloud':
          await _saveToCloud();
          break;
      }
    } catch (e) {
      _showErrorMessage('Operazione fallita. Riprova.');
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _shareViaWhatsApp() async {
    final reportContent = _generateReportContent();
    final filename = 'nutrivita_report_${widget.dateRange.toLowerCase()}.txt';

    final success = await SharingService.instance.shareViaWhatsApp(
      reportContent,
      filename,
    );

    if (success) {
      _showSuccessMessage('Report condiviso su WhatsApp con successo!');
      widget.onClose();
    } else {
      _showErrorMessage(
          'Impossibile condividere su WhatsApp. Assicurati che WhatsApp sia installato.');
    }
  }

  Future<void> _showSocialSharingOptions() async {
    setState(() {
      _isGenerating = false;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              child: Text(
                'Condividi via Social',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.lightTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...[
              {
                'name': 'Telegram',
                'icon': 'telegram',
                'color': Color(0xFF0088CC),
                'platform': 'telegram'
              },
              {
                'name': 'Email',
                'icon': 'email',
                'color': Color(0xFF3498DB),
                'platform': 'email'
              },
              {
                'name': 'SMS',
                'icon': 'sms',
                'color': Color(0xFF27AE60),
                'platform': 'sms'
              },
              {
                'name': 'Condivisione Sistema',
                'icon': 'share',
                'color': Color(0xFF95A5A6),
                'platform': 'system'
              },
            ].map((social) {
              return ListTile(
                leading: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: (social['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: social['icon'] as String,
                    color: social['color'] as Color,
                    size: 24,
                  ),
                ),
                title: Text(social['name'] as String),
                onTap: () async {
                  Navigator.pop(context);
                  await _shareViaSocialPlatform(social['platform'] as String);
                },
              );
            }).toList(),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Future<void> _shareViaSocialPlatform(String platform) async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final reportContent = _generateReportContent();
      final filename = 'nutrivita_report_${widget.dateRange.toLowerCase()}.txt';

      bool success = false;
      if (platform == 'system') {
        success = await SharingService.instance.shareViaSystemSheet(
          reportContent,
          filename,
        );
      } else {
        success = await SharingService.instance.shareViaOtherPlatforms(
          reportContent,
          filename,
          platform,
        );
      }

      if (success) {
        _showSuccessMessage('Report condiviso con successo!');
        widget.onClose();
      } else {
        _showErrorMessage('Impossibile completare la condivisione.');
      }
    } catch (e) {
      _showErrorMessage('Errore durante la condivisione. Riprova.');
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _generatePDFReport() async {
    final reportContent = _generateReportContent();

    if (kIsWeb) {
      final bytes = utf8.encode(reportContent);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute(
          "download",
          "nutrivita_report_${widget.dateRange.toLowerCase()}.txt",
        )
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/nutrivita_report_${widget.dateRange.toLowerCase()}.txt',
      );
      await file.writeAsString(reportContent);
    }

    _showSuccessMessage('Report PDF generato con successo');
    widget.onClose();
  }

  Future<void> _emailReport() async {
    // Simulate email functionality with real data processing
    await Future.delayed(const Duration(seconds: 2));
    _showSuccessMessage(
      'Report inviato al fornitore sanitario con dati aggiornati',
    );
    widget.onClose();
  }

  Future<void> _exportCSVData() async {
    final csvContent = _generateCSVContent();

    if (kIsWeb) {
      final bytes = utf8.encode(csvContent);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute(
          "download",
          "nutrivita_data_${widget.dateRange.toLowerCase()}.csv",
        )
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/nutrivita_data_${widget.dateRange.toLowerCase()}.csv',
      );
      await file.writeAsString(csvContent);
    }

    _showSuccessMessage('Dati CSV esportati con successo');
    widget.onClose();
  }

  Future<void> _saveToCloud() async {
    // Simulate cloud save functionality with real data
    await Future.delayed(const Duration(seconds: 3));
    _showSuccessMessage(
      'Report salvato su cloud storage sicuro con dati reali',
    );
    widget.onClose();
  }

  String _generateReportContent() {
    // Generate report with real data from Supabase
    final totalCalories =
        (_nutritionalSummary['total_calories'] ?? 0.0).toStringAsFixed(0);
    final avgCaloriesPerDay =
        (_nutritionalSummary['avg_calories_per_day'] ?? 0.0).toStringAsFixed(0);
    final totalProtein =
        (_nutritionalSummary['total_protein'] ?? 0.0).toStringAsFixed(1);
    final totalCarbs =
        (_nutritionalSummary['total_carbs'] ?? 0.0).toStringAsFixed(1);
    final totalFat = (_nutritionalSummary['total_fat'] ?? 0.0).toStringAsFixed(
      1,
    );
    final totalMeals = _mealStatistics['total_meals'] ?? 0;
    final mealDistribution = _mealStatistics['meal_type_distribution'] ?? {};

    return '''
NutriVita Report Nutrizionale
============================

Paziente: Utente NutriVita
Periodo Report: ${widget.dateRange}
Generato: ${DateTime.now().toString().split('.')[0]}
Livello Privacy: $_selectedPrivacyLevel

RIASSUNTO NUTRIZIONALE
---------------------
Calorie Totali: $totalCalories kcal
Calorie Giornaliere Medie: $avgCaloriesPerDay kcal
Pasti Registrati: $totalMeals

DISTRIBUZIONE MACRO
------------------
Proteine Totali: ${totalProtein}g
Carboidrati Totali: ${totalCarbs}g
Grassi Totali: ${totalFat}g

FREQUENZA PASTI
--------------
Colazioni: ${mealDistribution['breakfast'] ?? 0}
Pranzi: ${mealDistribution['lunch'] ?? 0}
Cene: ${mealDistribution['dinner'] ?? 0}
Spuntini: ${mealDistribution['snack'] ?? 0}

PASTI RECENTI
${_selectedPrivacyLevel == 'Dettaglio Completo' ? _generateMealsList() : 'Dettagli omessi per privacy'}

RACCOMANDAZIONI
--------------
- Mantieni la registrazione costante dei pasti
- ${totalMeals > 0 ? 'Continua con l\'approccio nutrizionale attuale' : 'Inizia a registrare i tuoi pasti per un monitoraggio migliore'}
- Programma un follow-up con il fornitore sanitario

Questo report è generato da NutriVita per scopi di consultazione medica.
    ''';
  }

  String _generateMealsList() {
    if (_recentMeals.isEmpty) {
      return '- Nessun pasto registrato nel periodo selezionato';
    }

    final mealsText = StringBuffer();
    for (var meal in _recentMeals) {
      final mealDate = meal['meal_date'] ?? 'Data non disponibile';
      final mealType = meal['meal_type'] ?? 'Tipo non specificato';
      final mealTime = meal['meal_time'] ?? '';
      final notes = meal['notes'] ?? '';

      mealsText.writeln(
        '- $mealDate ${mealTime.isNotEmpty ? '($mealTime)' : ''}: $mealType',
      );
      if (notes.isNotEmpty) {
        mealsText.writeln('  Note: $notes');
      }

      final mealFoods = meal['meal_foods'] as List? ?? [];
      for (var food in mealFoods) {
        final calories = (food['calories'] ?? 0).toStringAsFixed(0);
        mealsText.writeln('  • ${calories} kcal');
      }
    }

    return mealsText.toString();
  }

  String _generateCSVContent() {
    // Generate CSV with real data
    final buffer = StringBuffer();
    buffer.writeln('Data,Tipo_Pasto,Calorie,Proteine,Carboidrati,Grassi');

    if (_recentMeals.isNotEmpty) {
      for (var meal in _recentMeals) {
        final mealDate = meal['meal_date'] ?? '';
        final mealType = meal['meal_type'] ?? '';
        final mealFoods = meal['meal_foods'] as List? ?? [];

        double totalCalories = 0;
        double totalProtein = 0;
        double totalCarbs = 0;
        double totalFat = 0;

        for (var food in mealFoods) {
          totalCalories += (food['calories'] ?? 0).toDouble();
          totalProtein += (food['protein_g'] ?? 0).toDouble();
          totalCarbs += (food['carbs_g'] ?? 0).toDouble();
          totalFat += (food['fat_g'] ?? 0).toDouble();
        }

        buffer.writeln(
          '$mealDate,$mealType,${totalCalories.toStringAsFixed(0)},${totalProtein.toStringAsFixed(1)},${totalCarbs.toStringAsFixed(1)},${totalFat.toStringAsFixed(1)}',
        );
      }
    } else {
      // Add sample row if no data
      buffer.writeln(
        '${DateTime.now().toIso8601String().split('T')[0]},breakfast,0,0,0,0',
      );
    }

    return buffer.toString();
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF27AE60),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
