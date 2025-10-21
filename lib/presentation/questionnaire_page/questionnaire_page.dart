import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/body_metrics_service.dart';
import '../../services/questionnaire_service.dart';
import './widgets/bmi_validation_modal.dart';

class QuestionnairePage extends StatefulWidget {
  const QuestionnairePage({Key? key}) : super(key: key);

  @override
  State<QuestionnairePage> createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends State<QuestionnairePage> {
  final QuestionnaireService _questionnaireService = QuestionnaireService();
  final BodyMetricsService _bodyMetricsService = BodyMetricsService.instance;

  List<Map<String, dynamic>> _questionnaires = [];
  bool _isLoading = true;
  String? _error;
  Map<String, double> _categoryProgress = {};
  double _overallProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadQuestionnaires();
    _loadProgress();
  }

  Future<void> _loadQuestionnaires() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final questionnaires =
          await _questionnaireService.getQuestionnaireTemplates();

      // Filter out "Diario Alimentare" category questionnaires
      final filteredQuestionnaires = questionnaires.where((questionnaire) {
        final category =
            questionnaire['category']?.toString().toLowerCase() ?? '';
        return !category.contains('diario alimentare') &&
            !category.contains('diario');
      }).toList();

      setState(() {
        _questionnaires = filteredQuestionnaires;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Errore nel caricamento dei questionari: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProgress() async {
    try {
      final progressData = await _questionnaireService.getRealProgressData();
      final overallData = progressData['overall'] as Map<String, dynamic>;
      final categoriesData =
          progressData['categories'] as Map<String, Map<String, int>>;

      // Convert overall progress to double (0.0 to 1.0)
      final overallProgress = (overallData['percentage'] as int) / 100.0;

      // Convert category progress to Map<String, double>
      final categoryProgress = <String, double>{};
      for (final entry in categoriesData.entries) {
        final categoryName = entry.key;
        final progress = entry.value;
        final total = progress['total'] ?? 0;
        final completed = progress['completed'] ?? 0;
        categoryProgress[categoryName] = total > 0 ? completed / total : 0.0;
      }

      setState(() {
        _overallProgress = overallProgress;
        _categoryProgress = categoryProgress;
      });
    } catch (e) {
      setState(() {
        _overallProgress = 0.0;
        _categoryProgress = {};
      });
    }
  }

  /// ENHANCED: Check if questionnaire requires BMI validation with more specific rules
  bool _requiresBMIValidation(String questionnaireType, String category) {
    final categoryLower = category.toLowerCase();
    final typeLower = questionnaireType.toLowerCase();

    // More comprehensive BMI validation requirements
    final requiresBMI = categoryLower.contains('must') ||
        categoryLower.contains('nrs') ||
        categoryLower.contains('sarcopenia') ||
        categoryLower.contains('nutrizionale') ||
        categoryLower.contains('nutritional') ||
        typeLower.contains('must') ||
        typeLower.contains('nrs') ||
        typeLower.contains('sarc') ||
        typeLower.contains('nutritional_risk') ||
        typeLower.contains('consolidated_nutritional');

    // Additional logging for debugging
    print(
        '🔍 BMI Check - Type: $questionnaireType, Category: $category, Requires BMI: $requiresBMI');

    return requiresBMI;
  }

  /// ENHANCED: Start questionnaire with improved BMI validation
  Future<void> _startQuestionnaire(
    String questionnaireType,
    String title,
  ) async {
    print('🚀 Starting questionnaire: $questionnaireType');

    try {
      // Get questionnaire details to check if BMI validation is required
      final questionnaire = _questionnaires.firstWhere(
        (q) => q['questionnaire_type'] == questionnaireType,
        orElse: () => <String, dynamic>{},
      );

      final category = questionnaire['category']?.toString() ?? '';

      // Enhanced BMI validation logic
      if (_requiresBMIValidation(questionnaireType, category)) {
        print('⚖️ BMI validation required for $questionnaireType');

        // Show loading indicator while validating BMI
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        try {
          // Validate BMI data with enhanced error handling
          final validationResult =
              await _bodyMetricsService.validateBMIForQuestionnaire();

          // Close loading dialog
          Navigator.of(context).pop();

          // Log validation result for debugging
          print('📋 BMI Validation Result: ${validationResult.toString()}');

          if (!validationResult.isValid) {
            print('❌ BMI validation failed: ${validationResult.message}');

            // Show enhanced BMI validation modal
            await BMIValidationModal.show(
              context: context,
              validationResult: validationResult,
              onUpdatePressed: () async {
                print('🔄 Navigating to body metrics for BMI update');

                // Navigate to body metrics page with enhanced arguments
                final result = await Navigator.pushNamed(
                  context,
                  AppRoutes.bodyMetrics,
                  arguments: {
                    'returnAfterUpdate': true,
                    'questionnairePending': {
                      'type': questionnaireType,
                      'title': title,
                    },
                    'requiredUpdate': {
                      'weight': validationResult.requiresWeightUpdate,
                      'height': validationResult.requiresHeightUpdate,
                    },
                    'validationMessage': validationResult.message,
                  },
                );

                // After returning from body metrics, re-validate and potentially start questionnaire
                if (result == true) {
                  print(
                      '✅ Returned from body metrics, restarting questionnaire');
                  await Future.delayed(const Duration(milliseconds: 500));
                  _startQuestionnaire(questionnaireType, title);
                }
              },
              onCancelPressed: () {
                print('🚫 BMI validation cancelled by user');
              },
            );
            return;
          } else {
            print(
                '✅ BMI validation passed: BMI=${validationResult.bmi?.toStringAsFixed(1)}');
          }
        } catch (validationError) {
          // Close loading dialog if still open
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }

          print('🔥 BMI validation error: $validationError');

          // Show error-specific modal
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Errore durante la validazione BMI. Verifica la connessione.',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
              action: SnackBarAction(
                label: 'RIPROVA',
                textColor: Colors.white,
                onPressed: () => _startQuestionnaire(questionnaireType, title),
              ),
            ),
          );
          return;
        }
      } else {
        print('⏭️ No BMI validation required for $questionnaireType');
      }

      // Continue with normal questionnaire flow
      print('🔄 Starting assessment session...');

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final sessionId = await _questionnaireService.startAssessmentSession(
        questionnaireType,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (sessionId != null) {
        print('✅ Assessment session created: $sessionId');

        // Get template ID for the questionnaire type with improved validation
        String? templateId;

        // First try to get from the loaded questionnaires
        final template = _questionnaires.firstWhere(
          (q) => q['questionnaire_type'] == questionnaireType,
          orElse: () => <String, dynamic>{},
        );

        templateId = template['id'] as String?;

        // If not found, try to get from service
        if (templateId == null || templateId.isEmpty) {
          templateId = await _questionnaireService.getTemplateIdForType(
            questionnaireType,
          );
        }

        // Final validation - if still no template ID, use the session itself to determine template
        if (templateId == null || templateId.isEmpty) {
          print(
              '⚠️ Template ID not found for $questionnaireType, attempting fallback navigation');

          // Navigate without template ID - let the detail screen handle the lookup
          Navigator.pushNamed(
            context,
            AppRoutes.questionnaireDetail,
            arguments: {
              'sessionId': sessionId,
              'questionnaireType': questionnaireType,
              'templateId': '', // Empty, will be resolved in detail screen
              'questionnaireName': title,
            },
          );
          return;
        }

        // Navigate to questionnaire detail screen with validated template ID
        print('📱 Navigating to questionnaire detail screen');
        Navigator.pushNamed(
          context,
          AppRoutes.questionnaireDetail,
          arguments: {
            'sessionId': sessionId,
            'questionnaireType': questionnaireType,
            'templateId': templateId,
            'questionnaireName': title,
          },
        );
      } else {
        print('❌ Failed to create assessment session');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Impossibile avviare il questionario. Riprova tra qualche momento.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'RIPROVA',
              textColor: Colors.white,
              onPressed: () => _startQuestionnaire(questionnaireType, title),
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if it's open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      print('🔥 Error starting questionnaire: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Errore tecnico. Riprova più tardi.')),
            ],
          ),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'RIPROVA',
            textColor: Colors.white,
            onPressed: () => _startQuestionnaire(questionnaireType, title),
          ),
        ),
      );
    }
  }

  Color _getCategoryColor(String category) {
    final categoryLower = category.toLowerCase();
    if (categoryLower.contains('diario')) return Colors.orange;
    if (categoryLower.contains('must')) return Colors.blue;
    if (categoryLower.contains('nrs')) return Colors.green;
    if (categoryLower.contains('esas')) return Colors.red;
    if (categoryLower.contains('sf12')) return Colors.purple;
    if (categoryLower.contains('sarc')) return Colors.indigo;
    if (categoryLower.contains('funzionale')) return Colors.teal;
    if (categoryLower.contains('metabolica')) return Colors.amber;
    return Colors.grey;
  }

  IconData _getCategoryIcon(String category) {
    final categoryLower = category.toLowerCase();
    if (categoryLower.contains('diario')) return Icons.restaurant_menu;
    if (categoryLower.contains('must')) return Icons.assessment;
    if (categoryLower.contains('nrs')) return Icons.medical_services;
    if (categoryLower.contains('esas')) return Icons.mood;
    if (categoryLower.contains('sf12')) return Icons.favorite;
    if (categoryLower.contains('sarc')) return Icons.fitness_center;
    if (categoryLower.contains('funzionale')) return Icons.directions_run;
    if (categoryLower.contains('metabolica')) return Icons.science;
    return Icons.quiz;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Questionari',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 4.w),
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(26),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Progresso: ${(_overallProgress * 100).toInt()}%',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadQuestionnaires();
            await _loadProgress();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue.shade50, Colors.purple.shade50],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.assignment,
                        size: 48,
                        color: Colors.blue.shade700,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Questionari di Valutazione',
                        style: GoogleFonts.inter(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Completa i questionari per una valutazione completa del tuo stato di salute',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 2.h),
                      // Overall progress bar
                      Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Progresso Complessivo',
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  '${(_overallProgress * 100).toInt()}%',
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 1.h),
                            LinearProgressIndicator(
                              value: _overallProgress,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _overallProgress > 0.7
                                    ? Colors.green
                                    : _overallProgress > 0.4
                                        ? Colors.orange
                                        : Colors.blue,
                              ),
                              minHeight: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 3.h),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 2.h),
                        Text(
                          _error!,
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 2.h),
                        ElevatedButton(
                          onPressed: () {
                            _loadQuestionnaires();
                            _loadProgress();
                          },
                          child: const Text('Riprova'),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Text(
                    'Questionari Disponibili',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // Questionnaires List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _questionnaires.length,
                    separatorBuilder: (context, index) => SizedBox(height: 2.h),
                    itemBuilder: (context, index) {
                      final questionnaire = _questionnaires[index];
                      final title = questionnaire['title'] ?? 'Senza titolo';
                      final description = questionnaire['description'] ??
                          'Nessuna descrizione disponibile';
                      final category =
                          questionnaire['category'] ?? 'Categoria Sconosciuta';
                      final questionnaireType =
                          questionnaire['questionnaire_type'] ?? '';

                      final color = _getCategoryColor(category);
                      final icon = _getCategoryIcon(category);
                      final requiresBMI = _requiresBMIValidation(
                        questionnaireType,
                        category,
                      );

                      return InkWell(
                        onTap: () =>
                            _startQuestionnaire(questionnaireType, title),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: color.withAlpha(51),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(13),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Icon(
                                      icon,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: GoogleFonts.inter(
                                                  fontSize: 18.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: color,
                                                ),
                                              ),
                                            ),
                                            if (requiresBMI) ...[
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 2.w,
                                                  vertical: 0.5.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .monitor_weight_outlined,
                                                      size: 12,
                                                      color: Colors
                                                          .orange.shade700,
                                                    ),
                                                    SizedBox(width: 1.w),
                                                    Text(
                                                      'BMI',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 10.sp,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors
                                                            .orange.shade700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.grey[400],
                                    size: 16,
                                  ),
                                ],
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                description,
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  color: Colors.grey[600],
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4.w,
                                  vertical: 1.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 2.w),
                                    Text(
                                      'Inizia Questionario',
                                      style: GoogleFonts.inter(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  if (_questionnaires.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          SizedBox(height: 4.h),
                          Icon(
                            Icons.assignment_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Nessun questionario disponibile',
                            style: GoogleFonts.inter(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'I questionari verranno caricati presto',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],

                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
